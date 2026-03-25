import os
from dotenv import load_dotenv
import flet as ft
from flet.auth.providers.google_oauth_provider import GoogleOAuthProvider

from models.schedule import SemesterSchedule
from views.onboarding_view import OnboardingView
from views.schedule_view import ScheduleView
from views.add_course_view import AddCourseView
from views.add_meeting_view import AddMeetingView
from views.settings_view import SettingsView
from views.login_page import LoginView
from utils.theme import AppTheme

# טעינת המשתנים הסודיים מקובץ ה-.env
load_dotenv()

async def main(page: ft.Page):
    page.title = "LecCheck"
    page.theme_mode = ft.ThemeMode.LIGHT
    page.theme = AppTheme.get_theme()
    page.rtl = True
    
    provider = GoogleOAuthProvider(
        client_id=os.getenv("GOOGLE_CLIENT_ID", ""),
        client_secret=os.getenv("GOOGLE_CLIENT_SECRET", ""),
        redirect_url="http://localhost:8550/oauth_callback",
    )
    
    my_schedule = SemesterSchedule(page=page)

    def change_screen(screen_name):
        page.on_resize = None 
        page.controls.clear()
        
        view = None
        if screen_name == "login":
            view = LoginView(page, provider, change_screen, on_guest_login)
        elif screen_name == "onboarding":
            view = OnboardingView(page, my_schedule, change_screen)
        elif screen_name == "schedule":
            view = ScheduleView(page, my_schedule, change_screen)
        elif screen_name == "add":
            view = AddCourseView(page, my_schedule, change_screen)
        elif screen_name == "add_meeting":
            view = AddMeetingView(page, my_schedule, change_screen)
        elif screen_name == "settings":
            view = SettingsView(page, my_schedule, change_screen, is_tab=False)
            
        page.controls.append(ft.SafeArea(view, expand=True))
        page.update()

    async def on_guest_login():
        print("Logged in as Guest (Local mode)")
        my_schedule.set_user(None) 
        await my_schedule.load_from_file() # טוען מגיבוי מקומי
        
        if my_schedule.is_semester_set():
            page.rtl = (my_schedule.language == "he")
            change_screen("schedule")
        else:
            change_screen("onboarding")

    async def on_login(e):
        if e and getattr(e, "error", None):
            page.snack_bar = ft.SnackBar(ft.Text(f"שגיאת התחברות: {e.error}"))
            page.snack_bar.open = True
            page.update()
        else:
            user_id = page.auth.user.id
            print(f"Logged in successfully as: {user_id}")
            my_schedule.set_user(user_id)
            
            # מנסה למשוך מהענן
            success, msg = my_schedule.pull_from_server()
            
            # אם נכשל (פיירבייס לא הוגדר או ענן ריק), נטען מגיבוי מקומי כדי לא לאבד נתונים
            if not success:
                print(f"Cloud fetch failed ({msg}), loading local backup...")
                await my_schedule.load_from_file()
                
            if my_schedule.is_semester_set():
                page.rtl = (my_schedule.language == "he")
                change_screen("schedule")
            else:
                change_screen("onboarding")

    page.on_login = on_login

    if page.auth:
        await on_login(None)
    else:
        change_screen("login")

if __name__ == "__main__":
    ft.run(main, port=8550, view=ft.AppView.WEB_BROWSER, assets_dir="assets")