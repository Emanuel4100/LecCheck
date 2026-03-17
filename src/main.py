import flet as ft
from models.schedule import SemesterSchedule
from views.onboarding_view import OnboardingView
from views.schedule_view import ScheduleView
from views.add_course_view import AddCourseView
from views.add_meeting_view import AddMeetingView
from views.settings_view import SettingsView
from utils.theme import AppTheme

def main(page: ft.Page):
    page.title = "Lecture Tracker"
    page.theme_mode = ft.ThemeMode.LIGHT
    page.theme = AppTheme.get_theme()
    page.rtl = True
    
    my_schedule = SemesterSchedule()
    
    def change_screen(screen_name):
        page.on_resize = None 
        page.controls.clear()
        
        view = None
        if screen_name == "onboarding":
            view = OnboardingView(page, my_schedule, change_screen)
        elif screen_name == "schedule":
            view = ScheduleView(page, my_schedule, change_screen)
        elif screen_name == "add":
            view = AddCourseView(page, my_schedule, change_screen)
        elif screen_name == "add_meeting":
            view = AddMeetingView(page, my_schedule, change_screen)
        elif screen_name == "settings":
            view = SettingsView(page, my_schedule, change_screen, is_tab=False)
            
        # התיקון למובייל: עוטפים את המסך ב-SafeArea כדי שלא ייתקע בשורת הסטטוס העליונה!
        page.controls.append(ft.SafeArea(view, expand=True))
        page.update()

    if my_schedule.load_from_file() and my_schedule.is_semester_set():
        page.rtl = (my_schedule.language == "he")
        change_screen("schedule")
    else:
        change_screen("onboarding")

if __name__ == "__main__":
    ft.run(main, assets_dir="assets")