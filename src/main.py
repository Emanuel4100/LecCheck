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
    
    # חזרנו לארכיטקטורה המקורית והחכמה שלך!
    page.theme = AppTheme.get_theme()
    page.rtl = True
    
    my_schedule = SemesterSchedule()
    
    def change_screen(screen_name):
        page.on_resize = None 
        page.controls.clear()
        
        if screen_name == "onboarding":
            page.controls.append(OnboardingView(page, my_schedule, change_screen))
        elif screen_name == "schedule":
            page.controls.append(ScheduleView(page, my_schedule, change_screen))
        elif screen_name == "add":
            page.controls.append(AddCourseView(page, my_schedule, change_screen))
        elif screen_name == "add_meeting":
            page.controls.append(AddMeetingView(page, my_schedule, change_screen))
        elif screen_name == "settings":
            page.controls.append(SettingsView(page, my_schedule, change_screen))
        page.update()

    if my_schedule.load_from_file() and my_schedule.is_semester_set():
        page.rtl = (my_schedule.language == "he")
        change_screen("schedule")
    else:
        change_screen("onboarding")

if __name__ == "__main__":
    ft.run(main, assets_dir="assets")