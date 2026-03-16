import flet as ft
from models.lecture import LectureStatus
from utils.i18n import t

class StatisticsPanel(ft.Column):
    def __init__(self, schedule):
        super().__init__(expand=True, scroll=ft.ScrollMode.AUTO)
        self.schedule = schedule
        self.build_ui()

    def build_ui(self):
        self.controls.clear()
        lectures = self.schedule.get_all_lectures()
        
        total = len(lectures)
        attended = sum(1 for l in lectures if l.status == LectureStatus.ATTENDED)
        watched = sum(1 for l in lectures if l.status == LectureStatus.WATCHED_RECORDING)
        pending = sum(1 for l in lectures if l.status == LectureStatus.NEEDS_WATCHING)
        skipped = sum(1 for l in lectures if l.status == LectureStatus.SKIPPED)

        total_mins_all = 0
        total_mins_completed = 0

        for l in lectures:
            lec_mins = 0
            if l.duration_mins:
                lec_mins = l.duration_mins
            elif l.start_time and l.end_time:
                try:
                    h1, m1 = map(int, l.start_time.split(':'))
                    h2, m2 = map(int, l.end_time.split(':'))
                    lec_mins = (h2 * 60 + m2) - (h1 * 60 + m1)
                except Exception:
                    pass
            
            total_mins_all += lec_mins
            if l.status in [LectureStatus.ATTENDED, LectureStatus.WATCHED_RECORDING]:
                total_mins_completed += lec_mins

        def format_time(mins):
            hours = mins // 60
            m = mins % 60
            if hours > 0: return f"{hours}h {m}m"
            return f"{m}m" if mins > 0 else "0m"

        self.controls = [
            ft.Container(
                content=ft.Text(t("stats.title", default="סטטיסטיקות"), size=20, weight="bold", color="primary"),
                padding=ft.padding.only(bottom=10)
            ),
            self._build_stat_card(t("status.attended"), str(attended), "check_circle", "green"),
            self._build_stat_card(t("status.watched"), str(watched), "smart_display", "blue"),
            self._build_stat_card(t("status.needs_watching"), str(pending), "pending", "orange"),
            self._build_stat_card(t("status.skipped"), str(skipped), "cancel", "red"),
            ft.Divider(color="outlineVariant"),
            self._build_stat_card(t("stats.time_completed", default="זמן שהושלם"), format_time(total_mins_completed), "check", "green"),
            self._build_stat_card(t("stats.total_time", default="זמן כולל"), format_time(total_mins_all), "access_time", "primary"),
            self._build_stat_card(t("stats.total_meetings", default="סך הכל מפגשים"), str(total), "calendar_month", "onSurfaceVariant")
        ]

    def _build_stat_card(self, title, value, icon_name, color):
        return ft.Container(
            content=ft.Row([
                ft.Row([
                    ft.Image(src=f"icons/{icon_name}.svg", width=24, height=24, color=color),
                    ft.Text(title, size=15, weight="w500", color="onSurface")
                ], spacing=10),
                ft.Text(value, size=18, weight="bold", color="onSurface")
            ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
            padding=15,
            bgcolor="surface",
            border_radius=12,
            border=ft.border.all(1, "outlineVariant"),
            margin=ft.margin.only(bottom=10)
        )