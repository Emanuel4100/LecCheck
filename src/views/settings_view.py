import flet as ft
from datetime import datetime
import json
import shutil
from utils.i18n import translator, t

class SettingsView(ft.Column):
    def __init__(self, page: ft.Page, schedule, change_screen_func, is_tab=False):
        super().__init__(expand=True, scroll=ft.ScrollMode.AUTO)
        self.app_page = page
        self.schedule = schedule
        self.change_screen = change_screen_func

        def show_snackbar(message):
            self.app_page.snack_bar = ft.SnackBar(ft.Text(message, color="onPrimary"), bgcolor="primary")
            self.app_page.snack_bar.open = True
            self.app_page.update()

        def recalc_all():
            if self.schedule.is_semester_set():
                for c in self.schedule.courses:
                    c.recalculate_all_lectures(self.schedule.semester_start, self.schedule.semester_end, self.schedule.enable_meeting_numbers)
                self.schedule.save_to_file()

        def toggle_weekend(e):
            self.schedule.show_weekend = e.control.value
            self.schedule.save_to_file()
            
        def toggle_numbers(e):
            self.schedule.enable_meeting_numbers = e.control.value
            recalc_all()

        def update_date_texts():
            if self.schedule.semester_start:
                self.start_text.value = self.schedule.semester_start.strftime("%d/%m/%Y")
            if self.schedule.semester_end:
                self.end_text.value = self.schedule.semester_end.strftime("%d/%m/%Y")
            try:
                if self.page:
                    self.update()
            except Exception:
                pass

        async def export_data(e):
            try:
                picker = ft.FilePicker()
                result = await picker.save_file_async(
                    dialog_title=t("settings.export_dialog_title", default="שמור קובץ מערכת שעות"),
                    file_name="my_schedule_data.json",
                    file_type=ft.FilePickerFileType.CUSTOM,
                    allowed_extensions=["json"]
                )
                
                if result:
                    path = result.path if hasattr(result, 'path') else result
                    if path:
                        with open(path, 'w', encoding='utf-8') as f:
                            json.dump(self.schedule.to_dict(), f, ensure_ascii=False, indent=4)
                        show_snackbar(t("settings.export_success", default="הקובץ נשמר בהצלחה!"))
            except Exception as ex:
                show_snackbar(f"{t('settings.export_error', default='שגיאה בשמירה: ')}{str(ex)}")

        async def import_data(e):
            try:
                picker = ft.FilePicker()
                result = await picker.pick_files_async(
                    dialog_title=t("settings.import_dialog_title", default="בחר קובץ מערכת שעות לטעינה"),
                    file_type=ft.FilePickerFileType.CUSTOM,
                    allowed_extensions=["json"]
                )
                
                if result:
                    files = result.files if hasattr(result, 'files') else result
                    if files and len(files) > 0:
                        selected_file_path = files[0].path if hasattr(files[0], 'path') else files[0].get('path')
                        shutil.copy(selected_file_path, self.schedule.data_file)
                        success = self.schedule.load_from_file()
                        
                        if success:
                            show_snackbar(t("settings.import_success", default="הנתונים נטענו בהצלחה!"))
                            self.change_screen("schedule")
                        else:
                            show_snackbar(t("settings.import_failed", default="שגיאה: הקובץ לא תקין."))
            except Exception as ex:
                show_snackbar(f"{t('settings.import_error', default='שגיאה בטעינה: ')}{str(ex)}")

        def set_language(lang):
            if self.schedule.language == lang: return
            self.schedule.language = lang
            translator.set_language(lang)
            self.app_page.rtl = (lang == "he")
            self.schedule.save_to_file()
            self.app_page.update()
            self.change_screen("schedule") 

        self.lang_he_btn = ft.ElevatedButton(
            content=ft.Text("עברית", weight="bold"),
            style=ft.ButtonStyle(
                bgcolor="primary" if self.schedule.language == "he" else "surfaceVariant",
                color="onPrimary" if self.schedule.language == "he" else "onSurfaceVariant",
            ),
            on_click=lambda _: set_language("he")
        )

        self.lang_en_btn = ft.ElevatedButton(
            content=ft.Text("English", weight="bold"),
            style=ft.ButtonStyle(
                bgcolor="primary" if self.schedule.language == "en" else "surfaceVariant",
                color="onPrimary" if self.schedule.language == "en" else "onSurfaceVariant",
            ),
            on_click=lambda _: set_language("en")
        )

        language_section = ft.Column([
            ft.Text(t("settings.language", default="Language:"), size=16, weight="bold"),
            ft.Row([self.lang_he_btn, self.lang_en_btn], spacing=10)
        ])

        self.weekend_switch = ft.Switch(
            label=t("settings.show_weekend", default="Show Weekend"),
            value=self.schedule.show_weekend,
            on_change=toggle_weekend
        )
        
        self.numbers_switch = ft.Switch(
            label=t("settings.enable_numbering", default="Enable auto meeting numbers"),
            value=self.schedule.enable_meeting_numbers,
            on_change=toggle_numbers
        )

        def pick_date(e, is_start):
            def handle_change(ev):
                val = ev.control.value
                if val:
                    if isinstance(val, str):
                        parsed_date = datetime.strptime(val[:10], "%Y-%m-%d").date()
                    elif hasattr(val, 'date'):
                        parsed_date = val.date()
                    else:
                        parsed_date = val

                    if is_start: self.schedule.semester_start = parsed_date
                    else: self.schedule.semester_end = parsed_date
                    update_date_texts()
                    recalc_all()

            picker = ft.DatePicker(
                first_date=datetime(2020, 1, 1),
                last_date=datetime(2030, 12, 31),
                on_change=handle_change
            )
            self.app_page.overlay.append(picker)
            picker.open = True
            self.app_page.update()

        self.start_text = ft.Text("")
        self.end_text = ft.Text("")
        update_date_texts() 

        date_section = ft.Column([
            ft.Text(t("settings.dates", default="Semester Dates:"), weight="bold", size=16),
            ft.Row([
                ft.ElevatedButton(
                    content=ft.Row([ft.Image(src="icons/calendar_month.svg", width=18, height=18, color="primary"), ft.Text(t("settings.change_start", default="Change Start"), color="primary")]), 
                    on_click=lambda e: pick_date(e, True)
                ),
                self.start_text
            ]),
            ft.Row([
                ft.ElevatedButton(
                    content=ft.Row([ft.Image(src="icons/calendar_month.svg", width=18, height=18, color="primary"), ft.Text(t("settings.change_end", default="Change End"), color="primary")]), 
                    on_click=lambda e: pick_date(e, False)
                ),
                self.end_text
            ])
        ], spacing=10)

        def pull_from_server(e):
            show_snackbar("מושך נתונים מהענן...")
            success, msg = self.schedule.pull_from_server()
            show_snackbar(msg)
            if success:
                self.change_screen("schedule")

        def logout_user(e):
            self.app_page.logout()
            self.change_screen("login")

        sync_section = ft.Column([
            ft.Text(t("settings.data_management", default="ניהול נתונים בענן:"), weight="bold", size=16),
            ft.Row([
                ft.ElevatedButton(
                    content=ft.Row([ft.Image(src="icons/cloud_download.svg", width=18, height=18, color="onPrimary"), ft.Text("סנכרן נתונים עכשיו", color="onPrimary")]),
                    bgcolor="primary",
                    on_click=pull_from_server
                )
            ]),
            ft.Divider(height=10, color="transparent"),
            ft.Row([
                ft.ElevatedButton(
                    content=ft.Row([ft.Image(src="icons/save.svg", width=18, height=18, color="primary"), ft.Text(t("settings.export_data", default="Export Schedule"), color="primary")]),
                    on_click=export_data
                ),
            ]),
            ft.Row([
                ft.ElevatedButton(
                    content=ft.Row([ft.Image(src="icons/push_pin.svg", width=18, height=18, color="onError"), ft.Text(t("settings.import_data", default="Import Schedule"), color="onError")]),
                    bgcolor="errorContainer",
                    on_click=import_data
                )
            ]),
            ft.Divider(height=20, color="outlineVariant"),
            ft.ElevatedButton(
                # שימוש ב-icon במקום ב-name!
                content=ft.Row([ft.Icon(icon=ft.Icons.LOGOUT, color="onError"), ft.Text("התנתק מהמערכת", color="onError")], alignment=ft.MainAxisAlignment.CENTER),
                bgcolor="errorContainer",
                on_click=logout_user,
                width=200
            ),
        ], spacing=10)

        header = ft.Container(
            content=ft.Row([
                ft.TextButton(content=ft.Row([ft.Image(src="icons/arrow_forward.svg", width=18, height=18, color="onPrimary"), ft.Text(t("common.back"), color="onPrimary", weight="bold")]), on_click=lambda _: self.change_screen("schedule")),
                ft.Text(t("schedule.settings"), size=20, weight="bold", color="onPrimary")
            ]),
            bgcolor="primary", padding=5, border_radius=10,
            visible=not is_tab 
        )

        mobile_title = ft.Text(t("schedule.settings"), size=26, weight="bold", color="primary") if is_tab else ft.Container()

        self.controls = [
            header,
            ft.Container(
                padding=20,
                content=ft.Column([
                    mobile_title,
                    ft.Divider(height=10, color="transparent") if is_tab else ft.Container(),
                    language_section,
                    ft.Divider(height=20, color="transparent"),
                    ft.Text(t("settings.display", default="Display Settings:"), size=16, weight="bold"),
                    self.weekend_switch,
                    self.numbers_switch,
                    ft.Divider(height=30),
                    date_section,
                    ft.Divider(height=30),
                    sync_section 
                ], spacing=10)
            )
        ]