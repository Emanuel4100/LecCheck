import flet as ft
from datetime import datetime
from components.lecture_card import LectureCard
from utils.i18n import t

class LecturesList(ft.Column):
    def __init__(self, schedule, refresh_callback):
        super().__init__(expand=True, spacing=0)
        self.schedule = schedule
        self.refresh_callback = refresh_callback
        
        self.filters = [t("schedule.tab_missing"), t("schedule.tab_future"), t("schedule.tab_past")]
        self.selected_lecture_filter = self.filters[0]
        self.current_sort_method = "date"

        # 1. יצירת ה-TabBar - זה הרכיב החדש ב-Flet 1.0 שמחזיק את הלשוניות החזותיות
        # שימו לב: משתמשים ב-label (שלתוכו מכניסים Control) בדיוק לפי הכללים החדשים!
        self.tab_bar = ft.TabBar(
            tabs=[ft.Tab(label=ft.Text(f, weight="bold", size=14)) for f in self.filters]
        )

        # 2. יצירת רכיבי UI סטטיים לביצועים מקסימליים (למעבר מהיר בין לשוניות)
        self.summary_time_text = ft.Text("", weight="bold", color="primary", size=14)
        self.sort_btn_text = ft.Text("", color="primary", weight="bold", size=13)

        self.sort_btn = ft.PopupMenuButton(
            content=ft.Container(
                content=ft.Row([
                    ft.Image(src="icons/schedule.svg", width=18, height=18, color="primary"), 
                    self.sort_btn_text
                ], spacing=4),
                padding=ft.padding.symmetric(horizontal=10, vertical=5),
                bgcolor="surfaceVariant",
                border_radius=8
            ),
            tooltip="מיון הרצאות"
        )

        self.summary_row = ft.Container(
            content=ft.Row([
                ft.Row([
                    ft.Image(src="icons/access_time.svg", width=18, height=18, color="primary"),
                    self.summary_time_text
                ], spacing=6),
                self.sort_btn 
            ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
            padding=ft.padding.only(left=20, right=20, top=10, bottom=10),
            visible=False
        )

        self.divider = ft.Divider(height=1, color="outlineVariant", opacity=0.5)
        
        self.list_view = ft.ListView(expand=True, padding=20, spacing=10)
        
        self.gesture_wrapper = ft.GestureDetector(
            content=self.list_view,
            on_horizontal_drag_end=self.handle_swipe,
            expand=True
        )

        self.list_container = ft.Container(
            content=ft.Column([
                self.summary_row,
                self.divider,
                self.gesture_wrapper
            ], expand=True, spacing=0),
            expand=True
        )
        
        # 3. ה-Tabs ב-Flet 1.0 הוא עכשיו רק "בקר שליטה" עוטף
        # הוא מקבל length (מספר הלשוניות) ו-content (שבו נמצא ה-TabBar שלנו והרשימה)
        self.tabs_control = ft.Tabs(
            selected_index=0,
            length=len(self.filters),
            animation_duration=300,
            on_change=self.handle_tab_change,
            expand=True,
            content=ft.Column(
                expand=True,
                spacing=0,
                controls=[
                    self.tab_bar,
                    self.list_container
                ]
            )
        )
        
        self.controls = [self.tabs_control]
        
        self.update_list()

    def handle_tab_change(self, e):
        self.selected_lecture_filter = self.filters[e.control.selected_index]
        self.update_list()
        self.update()

    def change_filter(self, filter_name):
        self.selected_lecture_filter = filter_name
        try:
            self.tabs_control.selected_index = self.filters.index(filter_name)
        except ValueError:
            pass
        self.update_list()
        self.update()

    def handle_swipe(self, e: ft.DragEndEvent):
        velocity = e.primary_velocity
        try:
            idx = self.filters.index(self.selected_lecture_filter)
        except ValueError:
            return
        new_idx = idx
        
        if self.schedule.language == "he":
            if velocity < -300 and idx > 0:          
                new_idx = idx - 1
            elif velocity > 300 and idx < len(self.filters) - 1: 
                new_idx = idx + 1
        else:
            if velocity < -300 and idx < len(self.filters) - 1:
                new_idx = idx + 1
            elif velocity > 300 and idx > 0:
                new_idx = idx - 1
                
        if new_idx != idx:
            self.change_filter(self.filters[new_idx])

    def update_list(self):
        if self.selected_lecture_filter == self.filters[0]:
            lectures = self.schedule.get_pending_lectures()
        elif self.selected_lecture_filter == self.filters[2]:
            lectures = self.schedule.get_past_lectures()
        else:
            lectures = self.schedule.get_future_lectures()
            
        if self.current_sort_method == "duration":
            lectures.sort(key=lambda x: x.duration_mins or 0, reverse=True)
        elif self.current_sort_method == "type":
            lectures.sort(key=lambda x: str(x.meeting_type))
        else:
            lectures.sort(key=lambda x: (x.date_obj if x.date_obj else datetime.min.date(), x.start_time if x.start_time else "00:00"))

        total_mins = 0
        for l in lectures:
            if l.duration_mins:
                total_mins += l.duration_mins
            elif l.start_time and l.end_time:
                try:
                    h1, m1 = map(int, l.start_time.split(':'))
                    h2, m2 = map(int, l.end_time.split(':'))
                    total_mins += (h2 * 60 + m2) - (h1 * 60 + m1)
                except Exception:
                    pass

        hours = total_mins // 60
        mins = total_mins % 60
        time_str = f"{hours}h {mins}m" if hours > 0 else f"{mins}m"
        if total_mins == 0: time_str = "0m"

        sort_options = [
            ("date", t("schedule.sort_date", default="מיון: תאריך")),
            ("duration", t("schedule.sort_duration", default="מיון: אורך")),
            ("type", t("schedule.sort_type", default="מיון: סוג"))
        ]
        
        def handle_sort(e):
            self.current_sort_method = e.control.data
            self.update_list()
            self.update()

        # שימוש תקין ב-Flet 1.0 עבור תפריט נפתח (חובה להשתמש ב-content במקום ב-text)
        self.sort_btn.items = [
            ft.PopupMenuItem(
                data=k, 
                content=ft.Text(label), 
                checked=(self.current_sort_method == k), 
                on_click=handle_sort
            )
            for k, label in sort_options
        ]
        
        self.sort_btn_text.value = next(label for k, label in sort_options if k == self.current_sort_method)
        self.summary_time_text.value = t("schedule.total_duration", default="סה״כ זמן:") + f" {time_str}"
        
        has_lectures = len(lectures) > 0
        self.summary_row.visible = has_lectures
        self.divider.visible = has_lectures

        self.list_view.controls.clear()
        
        if not has_lectures:
            empty_state = ft.Column([
                ft.Image(src="icons/event_busy.svg", width=60, height=60, color="onSurfaceVariant"), 
                ft.Text(t("schedule.no_lectures", default="אין הרצאות"), size=18, weight="w500", color="onSurfaceVariant")
            ], alignment=ft.MainAxisAlignment.CENTER, horizontal_alignment=ft.CrossAxisAlignment.CENTER)
            self.list_view.controls.append(ft.Container(content=empty_state, alignment=ft.Alignment(0, 0), padding=ft.padding.only(top=100)))
        else:
            for lec in lectures:
                self.list_view.controls.append(LectureCard(lec, self.refresh_callback, is_mobile=False, show_date=True))