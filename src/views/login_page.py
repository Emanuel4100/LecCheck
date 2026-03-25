import flet as ft

class LoginView(ft.Column):
    def __init__(self, page: ft.Page, provider, change_screen_func, on_guest_login_func):
        super().__init__(expand=True, horizontal_alignment=ft.CrossAxisAlignment.CENTER, alignment=ft.MainAxisAlignment.CENTER)
        self.app_page = page
        self.provider = provider
        self.change_screen = change_screen_func
        self.on_guest_login = on_guest_login_func

        # פונקציות אסינכרוניות כנדרש להתחברות
        async def handle_google_login(e):
            await self.app_page.login(self.provider)

        async def handle_guest_login(e):
            await self.on_guest_login()

        self.controls = [
            ft.Image(src="icons/school.svg", width=120, height=120, color="primary"),
            ft.Container(height=20),
            ft.Text("ברוכים הבאים ל-LecCheck", size=32, weight="bold", color="primary"),
            ft.Text("נהלו את מערכת השעות שלכם מכל מקום,\nבסנכרון מלא לענן העדכני ביותר.", size=16, color="onSurfaceVariant", text_align=ft.TextAlign.CENTER),
            ft.Container(height=50),
            
            ft.ElevatedButton(
                content=ft.Row([
                    ft.Image(src="https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg", width=24, height=24),
                    ft.Text("התחברות מאובטחת עם Google", size=16, weight="bold", color="black87")
                ], alignment=ft.MainAxisAlignment.CENTER, spacing=15),
                style=ft.ButtonStyle(
                    bgcolor="white",
                    shape=ft.RoundedRectangleBorder(radius=10),
                    padding=20,
                    elevation=2
                ),
                width=320,
                on_click=handle_google_login # קריאה ישירה לפונקציה
            ),
            
            ft.Container(height=10),
            
            ft.TextButton(
                content=ft.Text("המשך ללא התחברות (שמירה מקומית)", size=14, color="primary"),
                on_click=handle_guest_login
            ),
            
            ft.Container(height=20),
            
            ft.Row([
                ft.Icon(icon=ft.Icons.LOCK_OUTLINE, size=14, color="outline"),
                ft.Text("החיבור מאובטח על ידי שרתי Google", size=12, color="outline")
            ], alignment=ft.MainAxisAlignment.CENTER)
        ]