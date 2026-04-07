package com.leccheck.shared.ui

enum class Screen {
    Login,
    Onboarding,
    Schedule,
    AddCourse,
    AddMeeting,
    Settings
}

enum class ScheduleTab {
    Weekly,
    Lectures,
    Statistics
}

data class AppUiState(
    val language: String = "he",
    val screen: Screen = Screen.Login,
    val selectedTab: ScheduleTab = ScheduleTab.Weekly,
    val isNarrow: Boolean = false,
    val userId: String? = null
)
