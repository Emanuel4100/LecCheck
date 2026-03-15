import flet as ft

class AppTheme:
    SEED_COLOR = "#005CBB"

    @staticmethod
    def get_theme():
        return ft.Theme(
            color_scheme_seed=AppTheme.SEED_COLOR
        )

    STATUS_ATTENDED = "green600"
    STATUS_WATCHED = "blue600"
    STATUS_PENDING = "orange600"
    STATUS_SKIPPED = "error"
    STATUS_CANCELLED = "outline"