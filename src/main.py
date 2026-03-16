import flet as ft
from models.schedule import SemesterSchedule
from views.onboarding_view import OnboardingView
from views.schedule_view import ScheduleView
from views.add_course_view import AddCourseView
from views.add_meeting_view import AddMeetingView
from views.settings_view import SettingsView

def main(page: ft.Page):
    page.title = "Lecture Tracker"
    page.theme_mode = ft.ThemeMode.LIGHT
    
    # הגדרת צבעים בטוחה שתואמת לכל הגרסאות של Flet
    page.theme = ft.Theme(
        color_scheme=ft.ColorScheme(
            primary="#006493",
            on_primary="#ffffff",
            primary_container="#cae6ff",
            on_primary_container="#001e30",
            secondary="#50606e",
            on_secondary="#ffffff",
            secondary_container="#d3e5f5",
            on_secondary_container="#0b1d29",
            tertiary="#65587b",
            on_tertiary="#ffffff",
            tertiary_container="#ebddff",
            on_tertiary_container="#201634",
            error="#ba1a1a",
            on_error="#ffffff",
            error_container="#ffdad6",
            on_error_container="#410002",
            surface="#fcfcff",
            on_surface="#1a1c1e",
            on_surface_variant="#42474e",
            outline="#72777f"
        )
    )
    page.rtl = True
    
    # [תיקון] - מעבירים את ה-page למודל כדי שידע לשמור ל-client_storage במובייל
    my_schedule = SemesterSchedule(page)
    
    def change_screen(screen_name):
        # [תיקון] - חובה לנקות מאזינים גלובליים לפני החלפת מסך כדי למנוע קריסות (Memory Leaks)
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