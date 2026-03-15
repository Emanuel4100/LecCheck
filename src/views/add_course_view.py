import flet as ft
import time
from models.course import Course
from utils.i18n import t # <-- מנוע התרגום

class AddCourseView(ft.Column):
    def __init__(self, page: ft.Page, schedule, change_screen_func):
        super().__init__(expand=True)
        self.app_page = page
        self.schedule = schedule
        self.change_screen = change_screen_func
        self.weekly_meetings = [] 

        self.title_input = ft.TextField(label="שם הקורס (למשל: אלגברה)", col={"xs": 12, "sm": 6})
        self.code_input = ft.TextField(label="קוד קורס (אופציונלי)", col={"xs": 6, "sm": 3})
        self.lecturer_input = ft.TextField(label="שם המרצה", col={"xs": 6, "sm": 3})
        self.location_input = ft.TextField(label="מיקום (חדר/אולם)", col={"xs": 12, "sm": 6, "md": 4})
        
        self.type_dropdown = ft.Dropdown(label="סוג", options=[ft.dropdown.Option("הרצאה"), ft.dropdown.Option("תרגול"), ft.dropdown.Option("מעבדה")], value="הרצאה", col={"xs": 6, "sm": 4, "md": 2})
        self.day_dropdown = ft.Dropdown(label="יום", options=[ft.dropdown.Option(d) for d in ["ראשון", "שני", "שלישי", "רביעי", "חמישי", "שישי"]], col={"xs": 6, "sm": 4, "md": 2})
        
        times = [f"{h:02d}:{m:02d}" for h in range(8, 23) for m in (0, 30)]
        self.start_dropdown = ft.Dropdown(label="התחלה", options=[ft.dropdown.Option(t) for t in times[:-1]], value="10:00", col={"xs": 6, "sm": 4, "md": 2})
        self.end_dropdown = ft.Dropdown(label="סיום", options=[ft.dropdown.Option(t) for t in times[1:]], value="12:00", col={"xs": 6, "sm": 6, "md": 2})
        
        self.tree_view = ft.Column(spacing=10)

        header = ft.Container(
            content=ft.Row([
                ft.TextButton(content=ft.Row([ft.Image(src="icons/arrow_forward.svg", width=18, height=18, color="white"), ft.Text("חזור", color="white", weight="bold")]), on_click=lambda _: self.change_screen("schedule")),
                ft.Text("הוספת קורס חדש", size=20, weight="bold", color="white")
            ]),
            bgcolor="#1976D2", padding=5, border_radius=10
        )

        self.controls = [
            header,
            ft.Container(
                padding=20,
                content=ft.Column([
                    ft.Text("פרטי הקורס:", weight="bold", size=16),
                    ft.ResponsiveRow([self.title_input, self.code_input, self.lecturer_input]),
                    ft.Divider(),
                    ft.Text("הוסף זמני מערכת:", weight="bold", size=16),
                    ft.ResponsiveRow([self.type_dropdown, self.day_dropdown, self.start_dropdown, self.end_dropdown, self.location_input]),
                    ft.ElevatedButton(content=ft.Row([ft.Image(src="icons/add_circle.svg", width=20, height=20, color="white"), ft.Text("הוסף זמן לקורס")], alignment=ft.MainAxisAlignment.CENTER), on_click=self.add_meeting, bgcolor="#F57C00", color="white"),
                    ft.Container(content=self.tree_view, margin=ft.margin.only(top=10, bottom=10)),
                    ft.Divider(),
                    ft.ElevatedButton(content=ft.Row([ft.Image(src="icons/save.svg", width=20, height=20, color="white"), ft.Text("שמור קורס וייצר הכל לסמסטר")], alignment=ft.MainAxisAlignment.CENTER), on_click=self.save_course, bgcolor="#43A047", color="white", height=45)
                ], spacing=15)
            )
        ]

    def calc_duration_text(self, start, end):
        h1, m1 = map(int, start.split(':'))
        h2, m2 = map(int, end.split(':'))
        total_mins = (h2 * 60 + m2) - (h1 * 60 + m1)
        if total_mins <= 0: return None
        
        hours = total_mins // 60
        mins = total_mins % 60
        res = []
        if hours == 1: res.append("שעה")
        elif hours == 2: res.append("שעתיים")
        elif hours > 2: res.append(f"{hours} שעות")
        
        if mins > 0:
            if hours > 0: res.append(f"ו-{mins} דקות")
            else: res.append(f"{mins} דקות")
        return " ".join(res)

    def add_meeting(self, e):
        if not self.day_dropdown.value or not self.start_dropdown.value or not self.end_dropdown.value:
            return
            
        dur_text = self.calc_duration_text(self.start_dropdown.value, self.end_dropdown.value)
        if not dur_text:
            self.app_page.snack_bar = ft.SnackBar(ft.Text("שגיאה! שעת הסיום חייבת להיות אחרי שעת ההתחלה.", color="red"))
            self.app_page.snack_bar.open = True
            self.app_page.update()
            return
        
        meeting = {
            "day": self.day_dropdown.value, "start": self.start_dropdown.value, "end": self.end_dropdown.value, 
            "location": self.location_input.value, "type": self.type_dropdown.value, "dur_text": dur_text
        }
        self.weekly_meetings.append(meeting)
        self.update_tree_view()
        self.app_page.update()

    def update_tree_view(self):
        self.tree_view.controls.clear()
        if not self.weekly_meetings: return

        groups = {"הרצאה": [], "תרגול": [], "מעבדה": []}
        for m in self.weekly_meetings: groups[m["type"]].append(m)

        c_title = self.title_input.value if self.title_input.value else t("course.new_course", "קורס חדש")
        c_code = f" ({self.code_input.value})" if self.code_input.value else ""
        
        tree_nodes = [ft.Row([ft.Image(src="icons/menu_book.svg", width=20, height=20, color="#1976D2"), ft.Text(f"{c_title}{c_code}", size=16, weight="bold", color="#1976D2")])]
        
        for m_type, m_list in groups.items():
            if not m_list: continue
            
            # השימוש המרכזי במערכת i18n שלנו לתיקון הפלורליזציה!
            plural_type = t(f"plurals.{m_type}", default=m_type)
            type_col = ft.Column([ft.Text(plural_type, weight="bold", color="black87")])
            
            for m in m_list:
                loc_text = f" | {m['location']}" if m['location'] else ""
                item = ft.Row([
                    ft.Image(src="icons/schedule.svg", width=14, height=14, color="grey600"),
                    ft.Text(f"{m['day']}, {m['start']} - {m['end']} | {m['dur_text']}{loc_text}", color="grey700", size=13)
                ])
                type_col.controls.append(item)
            
            tree_nodes.append(
                ft.Container(
                    content=type_col,
                    border=ft.border.only(right=ft.border.BorderSide(2, "#E0E0E0")),
                    padding=ft.padding.only(right=15),
                    margin=ft.margin.only(right=10)
                )
            )
            
        self.tree_view.controls.extend(tree_nodes)

    def save_course(self, e):
        if not self.title_input.value or len(self.weekly_meetings) == 0:
            self.app_page.snack_bar = ft.SnackBar(ft.Text("שגיאה! חובה להזין שם קורס ולפחות מועד אחד."))
            self.app_page.snack_bar.open = True
            self.app_page.update()
            return
            
        new_course = Course(course_id=str(time.time()), title=self.title_input.value, lecturer=self.lecturer_input.value, course_code=self.code_input.value)
        for m in self.weekly_meetings:
            new_course.add_weekly_meeting(self.schedule.semester_start, self.schedule.semester_end, m["day"], m["start"], m["end"], m["location"], m["type"])
            
        self.schedule.add_course(new_course)
        self.app_page.snack_bar = ft.SnackBar(ft.Text(f"הקורס '{self.title_input.value}' נוסף בהצלחה!"))
        self.app_page.snack_bar.open = True
        self.app_page.update()
        self.change_screen("schedule")