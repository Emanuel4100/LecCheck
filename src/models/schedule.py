import json
import os
import requests
import threading
from datetime import datetime
from models.course import Course
from utils.i18n import translator

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# חובה לשים כאן את כתובת ה-Firebase האמיתית שלך!
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FIREBASE_URL = "https://leccheck-db-default-rtdb.europe-west1.firebasedatabase.app"

class SemesterSchedule:
    def __init__(self, page=None):
        self.page = page  
        self.user_id = None 
        self.data_file = "my_schedule_data.json"
        
        self.language = "he"
        self.semester_start = None
        self.semester_end = None
        self.show_weekend = False
        self.enable_meeting_numbers = True
        self.courses = []

    def set_user(self, user_id):
        self.user_id = user_id

    def set_semester(self, start_val, end_val):
        def parse_date(d):
            if not d: return None
            if hasattr(d, 'date'): return d.date()
            if isinstance(d, str):
                try: return datetime.strptime(d, "%d/%m/%Y").date()
                except ValueError: pass
                try: return datetime.strptime(d[:10], "%Y-%m-%d").date()
                except ValueError: return None
            return d
            
        self.semester_start = parse_date(start_val)
        self.semester_end = parse_date(end_val)
        self.save_to_file()

    def add_course(self, course):
        self.courses.append(course)
        self.save_to_file()

    def remove_course(self, course_id):
        self.courses = [c for c in self.courses if c.id != course_id]
        self.save_to_file()

    def is_semester_set(self):
        return self.semester_start is not None and self.semester_end is not None

    def to_dict(self):
        return {
            "language": self.language,
            "semester_start": self.semester_start.strftime("%Y-%m-%d") if self.semester_start else None,
            "semester_end": self.semester_end.strftime("%Y-%m-%d") if self.semester_end else None,
            "show_weekend": self.show_weekend,
            "enable_meeting_numbers": self.enable_meeting_numbers,
            "courses": [c.to_dict() for c in self.courses]
        }

    def from_dict(self, data):
        if not data: return
        self.language = data.get("language", "he")
        start_str = data.get("semester_start")
        end_str = data.get("semester_end")
        self.semester_start = datetime.strptime(start_str, "%Y-%m-%d").date() if start_str else None
        self.semester_end = datetime.strptime(end_str, "%Y-%m-%d").date() if end_str else None
        self.show_weekend = data.get("show_weekend", False)
        self.enable_meeting_numbers = data.get("enable_meeting_numbers", True)
        
        translator.set_language(self.language)
        
        self.courses = []
        for c_data in data.get("courses", []):
            course = Course.from_dict(c_data)
            if not course.lectures and course.meetings and self.semester_start and self.semester_end:
                course.recalculate_all_lectures(self.semester_start, self.semester_end, self.enable_meeting_numbers)
            self.courses.append(course)

    def save_to_file(self):
        """שומר נתונים כפליים: גם כגיבוי מקומי על המחשב, וגם בענן"""
        data = self.to_dict()
        
        # 1. תמיד שומר עותק מקומי (מונע מחיקת נתונים)
        try:
            with open(self.data_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=4)
        except Exception as e:
            print(f"Error saving to local file: {e}")
            
        # 2. אם מחובר לגוגל - דוחף גם ל-Firebase ברקע
        if self.user_id:
            threading.Thread(target=self._push_to_server, daemon=True).start()

    async def load_from_file(self):
        """טוען את הנתונים מהגיבוי המקומי"""
        try:
            if os.path.exists(self.data_file):
                with open(self.data_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    self.from_dict(data)
                    return True
        except Exception as e:
            print(f"Error loading from local file: {e}")
        return False

    def _push_to_server(self):
        if not self.user_id: return
        try:
            endpoint = f"{FIREBASE_URL}/users/{self.user_id}/schedule.json"
            requests.put(endpoint, json=self.to_dict(), timeout=5)
        except Exception as e:
            print(f"Failed to push to Firebase: {e}")

    def pull_from_server(self):
        if not self.user_id:
            return False, "Not logged in"
        try:
            endpoint = f"{FIREBASE_URL}/users/{self.user_id}/schedule.json"
            response = requests.get(endpoint, timeout=5)
            
            if response.status_code == 200:
                data = response.json()
                if data is None:
                    return False, "לא נמצאו נתונים בענן למשתמש זה."
                
                self.from_dict(data)
                with open(self.data_file, 'w', encoding='utf-8') as f:
                    json.dump(self.to_dict(), f, ensure_ascii=False, indent=4)
                    
                return True, "הנתונים סונכרנו בהצלחה מהענן!"
            else:
                return False, f"Firebase error: {response.status_code}"
        except Exception as e:
            return False, f"שגיאת תקשורת: {e}"

    def get_all_lectures(self):
        all_lecs = []
        for c in self.courses:
            all_lecs.extend(c.lectures)
        return all_lecs

    def get_weekly_lectures(self, start_date, end_date):
        weekly_lecs = []
        for lec in self.get_all_lectures():
            if lec.date_obj and start_date <= lec.date_obj <= end_date:
                weekly_lecs.append(lec)
        return weekly_lecs

    def get_categorized_lectures(self):
        now = datetime.now()
        today = now.date()
        current_time = now.time()
        all_lecs = self.get_all_lectures()
        pending, future, past = [], [], []
        for l in all_lecs:
            if not l.date_obj:
                continue
            if l.status == "status.needs_watching" and l.date_obj <= today:
                pending.append(l)
            else:
                if l.date_obj < today:
                    past.append(l)
                elif l.date_obj > today:
                    future.append(l)
                else:
                    if l.start_time:
                        try:
                            h, m = map(int, l.start_time.split(':'))
                            if datetime(today.year, today.month, today.day, h, m).time() > current_time:
                                future.append(l)
                            else:
                                past.append(l)
                        except:
                            past.append(l)
                    else:
                        past.append(l)
        return pending, future, past