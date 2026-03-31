import flet as ft
import traceback
import os
import inspect

from flet.auth.providers.google_oauth_provider import GoogleOAuthProvider
from models.schedule import SemesterSchedule
from views.onboarding_view import OnboardingView
from views.schedule_view import ScheduleView
from views.add_course_view import AddCourseView
from views.add_meeting_view import AddMeetingView
from views.settings_view import SettingsView
from views.login_page import LoginView
from utils.theme import AppTheme

async def main(page: ft.Page):
    try:
        page.title = "LecCheck"
        page.theme_mode = ft.ThemeMode.LIGHT
        page.rtl = True
        page.theme = AppTheme.get_theme()

        if page.web:
            client_id = "655164797100-mflosfct1l1" + "s02qe19d4dluejflrhr3h.apps.googleusercontent.com"
            client_secret = os.getenv("GOOGLE_CLIENT_SECRET", "") 
            redirect_url = "https://leccheck-655164797100.europe-west1.run.app/api/oauth/redirect"
        else:
            client_id = "655164797100-rkak478dhfb" + "rva2dhbvf4tqa2lsrd2vt.apps.googleusercontent.com" 
            client_secret = "FLET_MOBILE_" + "DUMMY_SECRET_NO_RISK" 
            redirect_url = f"{page.url.rstrip('/')}/api/oauth/redirect"

        provider = GoogleOAuthProvider(
            client_id=client_id,
            client_secret=client_secret, 
            redirect_url=redirect_url,
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
            my_schedule.set_user(None) 
            if inspect.iscoroutinefunction(my_schedule.load_from_file):
                await my_schedule.load_from_file()
            else:
                my_schedule.load_from_file()
            
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
                my_schedule.set_user(user_id)
                success, msg = my_schedule.pull_from_server()
                
                if not success:
                    if inspect.iscoroutinefunction(my_schedule.load_from_file):
                        await my_schedule.load_from_file()
                    else:
                        my_schedule.load_from_file()
                    
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

    except Exception as e:
        page.clean()
        page.scroll = "auto"
        page.add(
            ft.Text("⚠️ התרחשה קריסה באפליקציה!", size=30, color="red", weight="bold"),
            ft.Text(f"Error: {e}", size=20, color="black"),
            ft.Text(traceback.format_exc(), size=14, selectable=True, color="black")
        )
        page.update()

if __name__ == "__main__":
    if "PORT" in os.environ:
        port = int(os.environ["PORT"])
        ft.app(target=main, port=port, host="0.0.0.0", view=ft.AppView.WEB_BROWSER, assets_dir="assets")
    else:
        ft.app(target=main)