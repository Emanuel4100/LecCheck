import flet as ft
from models.lecture import LectureStatus

class LectureCard(ft.Container):
    def __init__(self, lecture, update_callback):
        super().__init__()
        self.lecture = lecture
        self.update_callback = update_callback 
        
        self.border_radius = 12
        self.padding = 10
        self.margin = ft.margin.only(bottom=10)
        self.bgcolor = self.lecture.course_color
        
        self.shadow = ft.BoxShadow(
            spread_radius=1, blur_radius=5, color="black12", offset=ft.Offset(0, 2)
        )

        title = ft.Text(self.lecture.title, weight="w600", size=15, color="black87", no_wrap=True, overflow=ft.TextOverflow.ELLIPSIS)
        
        time_room = ft.Row([
            ft.Image(src="icons/access_time.svg", width=14, height=14, color="black54"),
            ft.Text(f"{self.lecture.start_time} - {self.lecture.end_time}", color="black54", size=12),
            ft.Container(width=10),
            ft.Image(src="icons/location_on.svg", width=14, height=14, color="black54"),
            ft.Text(self.lecture.room, color="black54", size=12)
        ], spacing=4, alignment=ft.MainAxisAlignment.START)

        self.content = ft.Column([
            title, time_room, ft.Divider(height=1, color="black12"), self.build_status_icons()
        ], spacing=6)

    def build_status_icons(self):
        def create_icon(icon_name, status_value, tooltip_text, active_color):
            is_active = (self.lecture.status == status_value)
            
            # התיקון: שימוש ב-Container לחיץ במקום IconButton
            return ft.Container(
                content=ft.Image(
                    src=f"icons/{icon_name}.svg", 
                    width=20, height=20, 
                    color=active_color if is_active else "black38"
                ),
                tooltip=tooltip_text,
                bgcolor="white" if is_active else "transparent",
                border_radius=20,
                padding=8,
                on_click=lambda e: self.set_status(status_value)
            )

        return ft.Row([
            create_icon("check_circle", LectureStatus.ATTENDED, "הלכתי", "green"),
            create_icon("smart_display", LectureStatus.WATCHED_RECORDING, "הקלטה", "blue"),
            create_icon("pending", LectureStatus.NEEDS_WATCHING, "להשלים", "orange"),
            create_icon("cancel", LectureStatus.SKIPPED, "דילגתי", "red"),
            create_icon("block", LectureStatus.CANCELLED, "בוטלה", "grey700"),
        ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN)

    def set_status(self, new_status):
        self.lecture.status = new_status
        if self.update_callback:
            self.update_callback()