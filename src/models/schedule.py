import json
import os
import urllib.request
from datetime import datetime
from models.course import Course
from utils.i18n import translator

class SemesterSchedule:
    def __init__(self, data_file="schedule_data.json"):
        self.data_file = data_file
        self.semester_start = None
        self.semester_end = None
        self.courses = []
        self.language = "he"
        self.show_weekend = False
        self.enable_meeting_numbers = True
        self.server_url = "" # Self-hosted server URL (e.g., https://lec.emulab.space)

    def to_dict(self):
        return {
            "semester_start": self.semester_start.strftime("%Y-%m-%d") if self.semester_start else None,
            "semester_end": self.semester_end.strftime("%Y-%m-%d") if self.semester_end else None,
            "language": self.language,
            "show_weekend": self.show_weekend,
            "enable_meeting_numbers": self.enable_meeting_numbers,
            "server_url": self.server_url,
            "courses": [c.to_dict() for c in self.courses]
        }
    
    def set_semester(self, start_val, end_val):
        def parse_date(d):
            if not d: return None
            if hasattr(d, 'date'): return d.date()
            if isinstance(d, str):
                try: 
                    return datetime.strptime(d, "%d/%m/%Y").date()
                except ValueError: 
                    pass
                try: 
                    return datetime.strptime(d[:10], "%Y-%m-%d").date()
                except ValueError: 
                    return None
            return d
            
        self.semester_start = parse_date(start_val)
        self.semester_end = parse_date(end_val)
        self.save_to_file()

    def save_to_file(self):
        try:
            with open(self.data_file, 'w', encoding='utf-8') as f:
                json.dump(self.to_dict(), f, ensure_ascii=False, indent=4)
        except Exception as e:
            print(f"Error saving local file: {e}")

        # Call directly without threading (Web Workers handle this without freezing UI)
        if self.server_url:
            self._push_to_server()

    def _push_to_server(self):
        try:
            base_url = self.server_url.rstrip('/')
            firebase_endpoint = f"{base_url}/schedule.json"
            
            data = json.dumps(self.to_dict()).encode('utf-8')
            req = urllib.request.Request(firebase_endpoint, data=data, method='PUT')
            req.add_header('Content-Type', 'application/json')
            
            with urllib.request.urlopen(req, timeout=5) as response:
                if response.status == 200:
                    print("Successfully pushed data to Firebase.")
                else:
                    print(f"Firebase error: {response.status}")
        except Exception as e:
            print(f"Failed to push to server: {e}")

    def pull_from_server(self):
        if not self.server_url:
            return False, "Server URL not configured"
        try:
            base_url = self.server_url.rstrip('/')
            firebase_endpoint = f"{base_url}/schedule.json"
            
            req = urllib.request.Request(firebase_endpoint, method='GET')
            with urllib.request.urlopen(req, timeout=5) as response:
                if response.status == 200:
                    data = json.loads(response.read().decode('utf-8'))
                    if data is None:
                        return False, "No data on Firebase yet"
                    
                    with open(self.data_file, 'w', encoding='utf-8') as f:
                        json.dump(data, f, ensure_ascii=False, indent=4)
                    
                    self.load_from_file()
                    return True, "Sync from Firebase completed successfully!"
                else:
                    return False, f"Firebase error: {response.status}"
        except Exception as e:
            return False, f"Communication error: {e}"

    def load_from_file(self):
        if not os.path.exists(self.data_file):
            return False
        try:
            with open(self.data_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                
            self.semester_start = self._safe_parse_date(data.get("semester_start"))
            self.semester_end = self._safe_parse_date(data.get("semester_end"))
            self.language = data.get("language", "he")
            self.show_weekend = data.get("show_weekend", False)
            self.enable_meeting_numbers = data.get("enable_meeting_numbers", True)
            self.server_url = data.get("server_url", "") 
            translator.set_language(self.language)
            
            self.courses = []
            for c_data in data.get("courses", []):
                course = Course.from_dict(c_data)
                
                if not course.lectures and course.meetings and self.semester_start and self.semester_end:
                    course.recalculate_all_lectures(self.semester_start, self.semester_end, self.enable_meeting_numbers)
                
                self.courses.append(course)
                
            self.save_to_file()
            return True
            
        except Exception as e:
            print(f"Error loading data: {e}")
            return False

    def _safe_parse_date(self, date_str):
        if not date_str:
            return None
        try:
            return datetime.strptime(date_str, "%Y-%m-%d").date()
        except:
            return None

    def is_semester_set(self):
        return bool(self.semester_start and self.semester_end)

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