package com.leccheck.shared.ui

data class UiStrings(
    val appTitle: String,
    val welcomeTitle: String,
    val welcomeSubtitle: String,
    val loginGoogle: String,
    val guestMode: String,
    val secureByGoogle: String,
    val setupTitle: String,
    val continueText: String,
    val weeklyTab: String,
    val lecturesTab: String,
    val statsTab: String,
    val settings: String
)

object StringsRepo {
    val he = UiStrings(
        appTitle = "מעקב הרצאות",
        welcomeTitle = "ברוכים הבאים ל-LecCheck",
        welcomeSubtitle = "נהלו את מערכת השעות שלכם מכל מקום,\nבסנכרון מלא לענן העדכני ביותר.",
        loginGoogle = "התחברות מאובטחת עם Google",
        guestMode = "המשך ללא התחברות (שמירה מקומית)",
        secureByGoogle = "החיבור מאובטח על ידי שרתי Google",
        setupTitle = "הגדרת סמסטר חדש",
        continueText = "המשך",
        weeklyTab = "לוח שבועי",
        lecturesTab = "הרצאות",
        statsTab = "סטטיסטיקה",
        settings = "הגדרות"
    )

    val en = UiStrings(
        appTitle = "Lecture Tracker",
        welcomeTitle = "Welcome to LecCheck",
        welcomeSubtitle = "Manage your study schedule from any device with cloud sync.",
        loginGoogle = "Secure sign in with Google",
        guestMode = "Continue as guest (local mode)",
        secureByGoogle = "Connection secured by Google",
        setupTitle = "New Semester Setup",
        continueText = "Continue",
        weeklyTab = "Weekly Board",
        lecturesTab = "Lectures",
        statsTab = "Statistics",
        settings = "Settings"
    )
}
