import flet as ft
from datetime import datetime, timedelta
from components.lecture_card import LectureCard
from utils.i18n import t

class LecturesList(ft.Column):
    def __init__(self, schedule, refresh_callback):
        super().__init__(expand=True, spacing=0)
        self.schedule = schedule
        self.refresh_callback = refresh_callback
        
        self.filters = [t("schedule.tab_missing"), t("schedule.tab_future"), t("schedule.tab_past")]
        self.current_sort_method = "date"
        self._cards_cache = {}

        self.ITEMS_PER_PAGE = 15
        self.visible_limits = [self.ITEMS_PER_PAGE, self.ITEMS_PER_PAGE, self.ITEMS_PER_PAGE]
        self.future_weeks_loaded = 0 
        
        self.tab_buttons = []
        self.tabs_row = ft.Row(alignment=ft.MainAxisAlignment.SPACE_AROUND, spacing=0)
        
        for i, f_name in enumerate(self.filters):
            btn = ft.Container(
                content=ft.Text(f_name, weight="w500", color="onSurfaceVariant", size=14),
                alignment=ft.Alignment(0, 0),
                padding=ft.padding.symmetric(vertical=15),
                ink=True,
                on_click=lambda e, idx=i: self.set_active_tab(idx),
                expand=True
            )
            self.tab_buttons.append(btn)
            self.tabs_row.controls.append(btn)

        self.summary_time_text = ft.Text("", weight="bold", color="primary", size=14)
        self.sort_btn_text = ft.Text("", color="primary", weight="bold", size=13)

        self.sort_btn = ft.PopupMenuButton(
            content=ft.Container(
                content=ft.Row([
                    ft.Image(src="icons/schedule.svg", width=18, height=18, color="primary"), 
                    self.sort_btn_text
                ], spacing=4),
                padding=ft.padding.symmetric(horizontal=10, vertical=5),
                bgcolor="surfaceVariant",
                border_radius=8
            ),
            tooltip="מיון הרצאות"
        )

        self.summary_row = ft.Container(
            content=ft.Row([
                ft.Row([
                    ft.Image(src="icons/access_time.svg", width=18, height=18, color="primary"),
                    self.summary_time_text
                ], spacing=6),
                self.sort_btn 
            ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
            padding=ft.padding.only(left=20, right=20, top=10, bottom=10),
            visible=False
        )

        self.divider = ft.Divider(height=1, color="outlineVariant", opacity=0.5)
        
        self.missing_list = ft.ListView(expand=True, padding=20, spacing=10, visible=True)
        self.future_list = ft.ListView(expand=True, padding=20, spacing=10, visible=False)
        self.past_list = ft.ListView(expand=True, padding=20, spacing=10, visible=False)
        
        self.list_views = [self.missing_list, self.future_list, self.past_list]
        self.totals = [0, 0, 0]
        self.has_items = [False, False, False]

        self.views_container = ft.Stack(self.list_views, expand=True)

        self.controls = [
            self.tabs_row,
            ft.Divider(height=1, color="outlineVariant", opacity=0.3),
            self.summary_row,
            self.divider,
            self.views_container
        ]
        
        self.current_tab_idx = -1
        
        self.rebuild_lists()
        self.set_active_tab(0, update_ui=False)

    def _safe_update(self, control):
        """ חומת מגן: מונעת קריסות פתאומיות כאשר הרכיב מתעדכן ברקע (כשאנחנו בלוח שבועי למשל) """
        if control and control.page:
            try:
                control.update()
            except Exception:
                # הבלמת השגיאה: הרכיב יעודכן אוטומטית כשהוא יחזור להיות מוצג במסך
                pass

    def set_active_tab(self, new_idx, update_ui=True):
        if self.current_tab_idx == new_idx and not update_ui:
            return
            
        # זיהוי מעבר לשונית כדי לאפס את כפתורי ה"טען עוד"
        is_tab_changed = (self.current_tab_idx != new_idx and self.current_tab_idx != -1)
        self.current_tab_idx = new_idx
        
        if is_tab_changed:
            self.visible_limits = [self.ITEMS_PER_PAGE, self.ITEMS_PER_PAGE, self.ITEMS_PER_PAGE]
            self.future_weeks_loaded = 0
            self.rebuild_lists()
        
        for i, btn in enumerate(self.tab_buttons):
            is_active = (i == new_idx)
            btn.border = ft.border.only(bottom=ft.border.BorderSide(3, "primary")) if is_active else None
            btn.content.color = "primary" if is_active else "onSurfaceVariant"
            btn.content.weight = "bold" if is_active else "w500"
            if update_ui: self._safe_update(btn)

        for i, lst in enumerate(self.list_views):
            is_active = (i == new_idx)
            if lst.visible != is_active:
                lst.visible = is_active
                if update_ui: self._safe_update(lst)

        total_mins = self.totals[new_idx]
        hours = total_mins // 60
        mins = total_mins % 60
        time_str = f"{hours}h {mins}m" if hours > 0 else f"{mins}m"
        if total_mins == 0: time_str = "0m"

        self.summary_time_text.value = t("schedule.total_duration", default="סה״כ זמן:") + f" {time_str}"
        if update_ui: self._safe_update(self.summary_time_text)
        
        has_lectures = self.has_items[new_idx]
        if self.summary_row.visible != has_lectures:
            self.summary_row.visible = has_lectures
            if update_ui: self._safe_update(self.summary_row)
            
        if self.divider.visible != has_lectures:
            self.divider.visible = has_lectures
            if update_ui: self._safe_update(self.divider)

    def load_more(self, tab_idx):
        if tab_idx == 1:
            self.future_weeks_loaded += 1
        else:
            self.visible_limits[tab_idx] += self.ITEMS_PER_PAGE
            
        self.rebuild_lists()
        self.set_active_tab(self.current_tab_idx, update_ui=True)

    def handle_sort(self, e):
        self.current_sort_method = e.control.data
        self.visible_limits = [self.ITEMS_PER_PAGE, self.ITEMS_PER_PAGE, self.ITEMS_PER_PAGE]
        self.future_weeks_loaded = 0
        self.rebuild_lists()
        self.set_active_tab(self.current_tab_idx, update_ui=True)

    def update_list(self):
        # הפונקציה נקראת בעת שינוי סטטוס ממסכים אחרים
        self.rebuild_lists()
        self.set_active_tab(self.current_tab_idx, update_ui=True)

    def rebuild_lists(self):
        sort_options = [
            ("date", t("schedule.sort_date", default="מיון: תאריך")),
            ("duration", t("schedule.sort_duration", default="מיון: אורך")),
            ("type", t("schedule.sort_type", default="מיון: סוג"))
        ]
        
        self.sort_btn.items = [
            ft.PopupMenuItem(data=k, content=ft.Text(label), checked=(self.current_sort_method == k), on_click=self.handle_sort)
            for k, label in sort_options
        ]
        self.sort_btn_text.value = next(label for k, label in sort_options if k == self.current_sort_method)

        # שימוש אופטימלי בפונקציית החלוקה שבנינו, עם חזרה לגיבוי למקרה של תקלת-פיתוח
        try:
            pending, future, past = self.schedule.get_categorized_lectures()
        except AttributeError:
            pending = self.schedule.get_pending_lectures()
            future = self.schedule.get_future_lectures()
            past = self.schedule.get_past_lectures()

        lists_data = [pending, future, past]

        new_cache = {}
        today = datetime.now().date()
        days_to_saturday = (5 - today.weekday()) % 7

        for i, lecs in enumerate(lists_data):
            if self.current_sort_method == "duration":
                lecs.sort(key=lambda x: x.duration_mins or 0, reverse=True)
            elif self.current_sort_method == "type":
                lecs.sort(key=lambda x: str(x.meeting_type))
            else:
                lecs.sort(key=lambda x: (x.date_obj if x.date_obj else datetime.min.date(), x.start_time if x.start_time else "00:00"))

            new_controls = []
            
            if i == 1:
                max_future_date = today + timedelta(days=days_to_saturday + (7 * self.future_weeks_loaded))
                display_lecs = [l for l in lecs if l.date_obj and l.date_obj <= max_future_date]
                has_more = len(display_lecs) < len(lecs)
                btn_text = "טען את השבוע הבא..."
                empty_msg = "אין עוד הרצאות מתוכננות השבוע"
            else:
                current_limit = self.visible_limits[i]
                display_lecs = lecs[:current_limit]
                has_more = len(lecs) > current_limit
                btn_text = t("common.load_more", default="טען עוד הרצאות...")
                empty_msg = t("schedule.no_lectures", default="אין הרצאות")

            total_mins = 0
            for lec in display_lecs:
                if lec.duration_mins:
                    total_mins += lec.duration_mins
                elif lec.start_time and lec.end_time:
                    try:
                        h1, m1 = map(int, lec.start_time.split(':'))
                        h2, m2 = map(int, lec.end_time.split(':'))
                        total_mins += (h2 * 60 + m2) - (h1 * 60 + m1)
                    except Exception:
                        pass
            
            self.totals[i] = total_mins
            self.has_items[i] = len(display_lecs) > 0

            if len(lecs) == 0:
                empty_state = ft.Column([
                    ft.Image(src="icons/event_busy.svg", width=60, height=60, color="onSurfaceVariant"), 
                    ft.Text(t("schedule.no_lectures", default="אין הרצאות"), size=18, weight="w500", color="onSurfaceVariant")
                ], alignment=ft.MainAxisAlignment.CENTER, horizontal_alignment=ft.CrossAxisAlignment.CENTER)
                new_controls.append(ft.Container(content=empty_state, alignment=ft.Alignment(0, 0), padding=ft.padding.only(top=100)))
                
            elif len(display_lecs) == 0:
                empty_state = ft.Column([
                    ft.Image(src="icons/event_busy.svg", width=60, height=60, color="onSurfaceVariant"), 
                    ft.Text(empty_msg, size=18, weight="w500", color="onSurfaceVariant")
                ], alignment=ft.MainAxisAlignment.CENTER, horizontal_alignment=ft.CrossAxisAlignment.CENTER)
                new_controls.append(ft.Container(content=empty_state, alignment=ft.Alignment(0, 0), padding=ft.padding.only(top=50, bottom=20)))
                
            else:
                for lec in display_lecs:
                    cache_key = f"{lec.session_id}_{lec.status}_{lec.duration_mins}_{lec.external_link}"
                    if cache_key in self._cards_cache:
                        card = self._cards_cache[cache_key]
                    else:
                        card = LectureCard(lec, self.refresh_callback, is_mobile=False, show_date=True)
                        
                    new_cache[cache_key] = card
                    new_controls.append(card)

            if has_more:
                load_more_btn = ft.Container(
                    content=ft.OutlinedButton(
                        content=ft.Text(btn_text),
                        on_click=lambda e, idx=i: self.load_more(idx),
                        width=220
                    ),
                    alignment=ft.Alignment(0, 0),
                    padding=ft.padding.only(top=10, bottom=20)
                )
                new_controls.append(load_more_btn)

            # Assign all at once to avoid constant UI mutations
            self.list_views[i].controls = new_controls

        self._cards_cache = new_cache