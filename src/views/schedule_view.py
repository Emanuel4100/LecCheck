import flet as ft
from datetime import datetime
import time
from components.weekly_grid import WeeklyGrid
from components.lectures_list import LecturesList
from components.statistics_panel import StatisticsPanel
from models.lecture import LectureSession, LectureStatus
from utils.i18n import t

class ScheduleView(ft.Column):
    def __init__(self, page: ft.Page, schedule, change_screen_func):
        super().__init__(expand=True, spacing=0)
        self.app_page = page 
        self.schedule = schedule
        self.change_screen = change_screen_func

        self.is_narrow_screen = self.app_page.width < 1100
        
        self.tabs = self.get_tabs()
        self.selected_tab = self.tabs[0]
        
        self.weekly_grid_component = WeeklyGrid(self.schedule, self.refresh_ui, self.is_narrow_screen)
        self.lectures_list_component = LecturesList(self.schedule, self.refresh_ui)
        
        self.app_page.on_resize = self.handle_resize

        self.tabs_row = ft.Row(scroll=ft.ScrollMode.AUTO, alignment=ft.MainAxisAlignment.CENTER, visible=not self.is_narrow_screen)
        
        self.bottom_nav_row = ft.Row(alignment=ft.MainAxisAlignment.SPACE_AROUND)
        self.bottom_nav = ft.Container(
            content=self.bottom_nav_row,
            visible=self.is_narrow_screen,
            bgcolor="surface",
            border=ft.border.only(top=ft.border.BorderSide(1, "outlineVariant")),
            padding=ft.padding.only(top=5, bottom=5),
            height=65
        )

        self.content_area = ft.Container()
        self.build_tabs()
        self.update_content()

        self.header = ft.Container(
            content=ft.Row([
                ft.Container(content=ft.Icon("settings", size=24, color="onPrimary"), tooltip=t("schedule.settings"), padding=10, on_click=lambda _: self.change_screen("settings")),
                ft.Text(t("schedule.app_title"), size=22, weight="bold", color="onPrimary"),
                ft.Container(width=48)
            ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
            bgcolor="primary", padding=15, border_radius=ft.border_radius.only(bottom_left=15, bottom_right=15), shadow=ft.BoxShadow(blur_radius=5, color="shadow")
        )

        add_btn = ft.FloatingActionButton(content=ft.Icon("add", size=24, color="onPrimaryContainer"), bgcolor="primaryContainer", shape=ft.RoundedRectangleBorder(radius=16), on_click=self.open_add_menu)
        
        # התיקון העיצובי הקריטי: עיגון של התוכן לארבעת הקצוות בתוך ה-Stack כדי שלא יעלם
        self.controls = [
            self.header,
            self.tabs_row,
            ft.Stack([
                ft.Container(content=self.content_area, top=0, bottom=0, left=0, right=0),
                ft.Container(content=add_btn, bottom=20, left=20) 
            ], expand=True),
            self.bottom_nav
        ]

    def get_tabs(self):
        if self.is_narrow_screen: return [t("schedule.tab_weekly"), t("schedule.tab_lectures"), t("schedule.tab_stats")]
        else: return [t("schedule.tab_weekly"), t("schedule.tab_lectures")]

    def handle_resize(self, e):
        new_is_narrow = self.app_page.width < 1100
        if new_is_narrow != self.is_narrow_screen:
            self.is_narrow_screen = new_is_narrow
            self.tabs = self.get_tabs()
            if self.selected_tab not in self.tabs: self.selected_tab = self.tabs[0]
            
            self.weekly_grid_component.set_narrow_screen(new_is_narrow)
            self.tabs_row.visible = not new_is_narrow
            self.bottom_nav.visible = new_is_narrow
            
            self.build_tabs()
            self.update_content()
            self.update()

    def open_add_menu(self, e):
        def close_and_go(screen_name):
            bs.open = False; self.app_page.update(); self.change_screen(screen_name)
            
        def close_and_open_oneoff():
            bs.open = False; self.app_page.update(); self.open_oneoff_event_dialog()

        if self.selected_tab == t("schedule.tab_lectures"):
            options_content = ft.Column([
                ft.Text(t("schedule.add_task", default="משימה חדשה"), size=18, weight="bold", color="onSurface"),
                ft.Divider(color="outlineVariant"),
                ft.ListTile(leading=ft.Icon("video_camera_front", color="primary"), title=ft.Text(t("schedule.add_recording", default="הקלטה להשלמה"), color="onSurface"), on_click=lambda _: close_and_open_oneoff()),
                ft.ListTile(leading=ft.Icon("event", color="tertiary"), title=ft.Text(t("schedule.add_custom_event", default="אירוע חריג"), color="onSurface"), on_click=lambda _: close_and_open_oneoff()),
            ], tight=True)
        else:
            options_content = ft.Column([
                ft.Text(t("schedule_menu.add_options"), size=18, weight="bold", color="onSurface"),
                ft.Divider(color="outlineVariant"),
                ft.ListTile(leading=ft.Icon("menu_book", color="primary"), title=ft.Text(t("schedule_menu.add_course"), color="onSurface"), on_click=lambda _: close_and_go("add")),
                ft.ListTile(leading=ft.Icon("schedule", color="tertiary"), title=ft.Text(t("schedule_menu.add_meeting"), color="onSurface"), on_click=lambda _: close_and_go("add_meeting"))
            ], tight=True)

        bs = ft.BottomSheet(ft.Container(padding=20, bgcolor="surface", content=options_content))
        self.app_page.overlay.append(bs); bs.open = True; self.app_page.update()

    def open_oneoff_event_dialog(self):
        course_options = [ft.dropdown.Option(key=c.course_id, text=c.title) for c in self.schedule.courses]
        course_dropdown = ft.Dropdown(label=t("schedule.select_course", default="בחר קורס"), options=course_options, width=280)
        title_input = ft.TextField(label=t("schedule.topic_title", default="נושא"), width=280)
        duration_input = ft.TextField(label=t("schedule.duration_mins", default="אורך (דקות)"), keyboard_type=ft.KeyboardType.NUMBER, width=120)
        
        type_dropdown = ft.Dropdown(label=t("schedule.meeting_type", default="סוג"), width=150, options=[
            ft.dropdown.Option("meeting_types.lecture", t("meeting_types.lecture")),
            ft.dropdown.Option("meeting_types.practice", t("meeting_types.practice")),
            ft.dropdown.Option("meeting_types.lab", t("meeting_types.lab")),
            ft.dropdown.Option("meeting_types.recording", t("meeting_types.recording", default="הקלטה")),
            ft.dropdown.Option("meeting_types.other", t("meeting_types.other", default="אחר"))
        ], value="meeting_types.other")
        
        def save_oneoff(e):
            if not course_dropdown.value or not title_input.value:
                return
            course = next((c for c in self.schedule.courses if c.course_id == course_dropdown.value), None)
            if course:
                session_id = str(time.time())
                dur = int(duration_input.value) if duration_input.value.isdigit() else 60
                
                lec = LectureSession(
                    session_id=session_id,
                    title=f"{course.title} - {title_input.value}",
                    lecturer=course.lecturer,
                    date_obj=datetime.now().date(),
                    duration_mins=dur,
                    is_one_off=True,
                    meeting_type=type_dropdown.value,
                    status=LectureStatus.NEEDS_WATCHING
                )
                lec.course_color = course.color
                course.lectures.append(lec)
                self.schedule.save_to_file()
                self.refresh_ui()
                dlg.open = False
                self.app_page.update()
                
        def close_dialog(e):
            dlg.open = False
            self.app_page.update()

        dlg = ft.AlertDialog(
            title=ft.Text(t("schedule.add_task", default="משימה חדשה")),
            content=ft.Column([course_dropdown, title_input, ft.Row([duration_input, type_dropdown])], tight=True),
            actions=[
                ft.TextButton(t("common.cancel", default="ביטול"), on_click=close_dialog),
                ft.ElevatedButton(t("common.save", default="שמור"), on_click=save_oneoff, bgcolor="primary", color="onPrimary")
            ]
        )
        self.app_page.overlay.append(dlg)
        dlg.open = True
        self.app_page.update()

    def build_tabs(self):
        self.tabs_row.controls.clear()
        for tab in self.tabs:
            is_selected = (tab == self.selected_tab)
            btn = ft.TextButton(
                content=ft.Text(tab, color="onSecondaryContainer" if is_selected else "onSurfaceVariant", weight="bold" if is_selected else "normal"),
                style=ft.ButtonStyle(bgcolor="secondaryContainer" if is_selected else "transparent", shape=ft.RoundedRectangleBorder(radius=20)),
                on_click=self.create_tab_click_handler(tab)
            )
            self.tabs_row.controls.append(btn)

        self.bottom_nav_row.controls.clear()
        nav_items = [
            ("calendar_month", t("schedule.tab_weekly")),
            ("menu_book", t("schedule.tab_lectures")),
            ("pie_chart", t("schedule.tab_stats"))
        ]
        for icon_name, tab_name in nav_items:
            is_selected = (self.selected_tab == tab_name)
            color = "primary" if is_selected else "onSurfaceVariant"
            
            nav_btn = ft.Container(
                content=ft.Column([
                    ft.Icon(icon_name, size=24, color=color),
                    ft.Text(tab_name, size=11, color=color, weight="bold" if is_selected else "normal")
                ], spacing=4, alignment=ft.MainAxisAlignment.CENTER, horizontal_alignment=ft.CrossAxisAlignment.CENTER),
                expand=True, ink=True, border_radius=10,
                on_click=self.create_tab_click_handler(tab_name)
            )
            self.bottom_nav_row.controls.append(nav_btn)

    def create_tab_click_handler(self, tab):
        def on_click(e):
            self.selected_tab = tab; self.build_tabs(); self.update_content(); self.update()
        return on_click
    
    def refresh_ui(self):
        self.schedule.save_to_file()
        self.weekly_grid_component.update_grid()
        self.lectures_list_component.update_list()
        self.update_content()
        self.update()

    def update_content(self):
        main_view = None
        
        if self.selected_tab == t("schedule.tab_weekly"): 
            main_view = self.weekly_grid_component
        elif self.selected_tab == t("schedule.tab_stats"): 
            main_view = StatisticsPanel(self.schedule)
        elif self.selected_tab == t("schedule.tab_lectures"): 
            main_view = self.lectures_list_component

        if not self.is_narrow_screen and self.selected_tab == t("schedule.tab_lectures"):
            border_side = ft.border.only(
                right=ft.border.BorderSide(width=1, color="outlineVariant")
            ) if self.schedule.language == "he" else ft.border.only(
                left=ft.border.BorderSide(width=1, color="outlineVariant")
            )
            
            side_panel = ft.Container(
                content=StatisticsPanel(self.schedule), 
                width=350, border=border_side, padding=10
            )
            self.content_area.content = ft.Row([
                ft.Container(content=main_view, expand=True), 
                side_panel
            ], expand=True)
        else:
            self.content_area.content = main_view