// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'LecCheck';

  @override
  String get dashboardTitle => 'LecCheck';

  @override
  String get welcomeTitle => 'ברוכים הבאים ל-LecCheck';

  @override
  String get welcomeSubtitle => 'ניהול מערכת שעות עם סנכרון ענן.';

  @override
  String get continueLocal => 'המשך מקומי';

  @override
  String get continueCloudComingSoon => 'המשך בענן (בקרוב)';

  @override
  String get cloudComingSoonMessage =>
      'התחברות לענן (Google/Firebase) תתווסף בהמשך.';

  @override
  String get semesterSetupTitle => 'הגדרת סמסטר חדש';

  @override
  String get startDate => 'תאריך התחלה';

  @override
  String get endDate => 'תאריך סיום';

  @override
  String get pickDate => 'בחר';

  @override
  String get weekStartsOn => 'תחילת שבוע';

  @override
  String get sunday => 'יום ראשון';

  @override
  String get monday => 'יום שני';

  @override
  String get weekdayMonShort => 'ב׳';

  @override
  String get weekdayTueShort => 'ג׳';

  @override
  String get weekdayWedShort => 'ד׳';

  @override
  String get weekdayThuShort => 'ה׳';

  @override
  String get weekdayFriShort => 'ו׳';

  @override
  String get weekdaySatShort => 'ש׳';

  @override
  String get weekdaySunShort => 'א׳';

  @override
  String get dayGeneric => 'יום';

  @override
  String get includeWeekend => 'כלול סוף שבוע (שישי/שבת)';

  @override
  String get continueCta => 'המשך';

  @override
  String get semesterDateRangeError =>
      'תאריך הסיום חייב להיות אחרי תאריך ההתחלה.';

  @override
  String semesterDurationHint(int days) {
    return 'אורך הסמסטר: $days ימים';
  }

  @override
  String get setupCoursesTitle => 'הגדרת קורסים';

  @override
  String get addCoursesSubtitle => 'הוסף קורסים לסמסטר';

  @override
  String get noCoursesYet => 'אין קורסים עדיין. הוסף קורס ראשון.';

  @override
  String get addCourse => 'הוסף קורס';

  @override
  String get addMeeting => 'הוסף מפגש';

  @override
  String get save => 'שמור';

  @override
  String get cancel => 'ביטול';

  @override
  String get settings => 'הגדרות';

  @override
  String get weekly => 'שבועי';

  @override
  String get lectures => 'הרצאות';

  @override
  String get stats => 'סטטיסטיקה';

  @override
  String get language => 'שפה';

  @override
  String get shownDays => 'ימים מוצגים';

  @override
  String get lectureDetailsTitle => 'פרטי מפגש';

  @override
  String get statusLabel => 'סטטוס';

  @override
  String get addRecordingLink => 'הוסף קישור להקלטה';

  @override
  String get recordingLink => 'קישור להקלטה';

  @override
  String get semesterWeekLabel => 'שבוע';

  @override
  String get logout => 'התנתקות';

  @override
  String get resetSemester => 'איפוס סמסטר';

  @override
  String get list => 'רשימה';

  @override
  String get grid => 'טבלה';

  @override
  String get attendance => 'נוכחות';

  @override
  String get attended => 'נכח';

  @override
  String get missed => 'החסיר';

  @override
  String get skipped => 'דילג';

  @override
  String get pending => 'ממתין';

  @override
  String get weeklyGridView => 'תצוגת רשת שבועית';

  @override
  String get addCourseFirst => 'הוסף קורס קודם.';

  @override
  String get courseName => 'שם הקורס';

  @override
  String get courseCode => 'קוד קורס';

  @override
  String get addLecturer => 'הוסף מרצה';

  @override
  String get lecturer => 'מרצה';

  @override
  String get addCourseLink => 'הוסף קישור לקורס';

  @override
  String get link => 'קישור';

  @override
  String get course => 'קורס';

  @override
  String get weekday => 'יום בשבוע';

  @override
  String get type => 'סוג';

  @override
  String get lectureType => 'הרצאה';

  @override
  String get practiceType => 'תרגול';

  @override
  String get labType => 'מעבדה';

  @override
  String get otherType => 'אחר';

  @override
  String get startTime => 'שעת התחלה';

  @override
  String get endTime => 'שעת סיום';

  @override
  String get length => 'משך';

  @override
  String get room => 'חדר';

  @override
  String get change => 'שנה';

  @override
  String get showWeekend => 'הצג סוף שבוע';

  @override
  String get autoMeetingNumbers => 'מספור מפגשים אוטומטי';

  @override
  String get semesterStart => 'תחילת סמסטר';

  @override
  String get semesterEnd => 'סיום סמסטר';

  @override
  String get reset => 'אפס';

  @override
  String get addSession => 'הוסף מפגש';

  @override
  String get addWeeklySessions => 'הוסף מפגשים שבועיים';

  @override
  String get noSessionsYet => 'עדיין לא נוספו מפגשים.';

  @override
  String get courseCodePrefix => 'קוד';

  @override
  String get lecturerPrefix => 'מרצה';

  @override
  String get addCourseNameAndSessionError => 'הוסף שם קורס ולפחות מפגש אחד.';

  @override
  String get endAfterStartError => 'שעת הסיום חייבת להיות אחרי שעת ההתחלה.';

  @override
  String get markAttended => 'סמן כנוכח';

  @override
  String get markWatchedRecording => 'סמן כנצפה בהקלטה';

  @override
  String get markMissed => 'סמן כהחסיר';

  @override
  String get markSkipped => 'סמן כדולג';

  @override
  String get markCanceled => 'סמן כמבוטל';

  @override
  String get statusPending => 'ממתין';

  @override
  String get statusAttended => 'נכח';

  @override
  String get statusMissed => 'החסיר';

  @override
  String get statusSkipped => 'דולג';

  @override
  String get statusWatchedRecording => 'נצפה בהקלטה';

  @override
  String get statusCanceled => 'מבוטל';

  @override
  String get hourUnitShort => 'ש';

  @override
  String get minuteUnitShort => 'ד';

  @override
  String get lecturesTabNeedAttention => 'דורש טיפול';

  @override
  String get lecturesTabUpcoming => 'קרוב';

  @override
  String get lecturesTabAll => 'הכל';

  @override
  String get lecturesCaughtUpTitle => 'הכול מעודכן';

  @override
  String get lecturesCaughtUpSubtitle => 'אין מפגשים שעברו שממתינים לסימון.';

  @override
  String get lecturesMarkToKeepStreakHint => 'סמנו מפגשים כדי לבנות רצף למידה.';

  @override
  String get lecturesNoUpcoming => 'אין מפגשים בחלון השבוע הזה.';

  @override
  String get showNextWeekToo => 'הצג גם את השבוע שאחריו';

  @override
  String get showNextWeekOnly => 'רק השבוע הבא';

  @override
  String get searchCourses => 'חיפוש קורסים';

  @override
  String get sortByDateNewest => 'תאריך (חדש לישן)';

  @override
  String get sortByDateOldest => 'תאריך (ישן לחדש)';

  @override
  String get sortByCourse => 'שם קורס';

  @override
  String get sortByType => 'סוג';

  @override
  String get sortByStatus => 'סטטוס';

  @override
  String get sortMenuTooltip => 'מיון';

  @override
  String get addActionsTitle => 'פעולות מהירות';

  @override
  String get goToCurrentWeek => 'עבור לשבוע הנוכחי';

  @override
  String get focusSearchField => 'מיקוד חיפוש';

  @override
  String get statsAttendanceHeroTitle => 'נוכחות';

  @override
  String get statsAttendanceHeroSubtitle =>
      'מנת המפגשים שעברו שסומנו כנוכח/הקלטה לעומת החסיר.';

  @override
  String get statsStreakLabel => 'רצף למידה (ימים)';

  @override
  String get statsOverduePendingLabel => 'ממתינים לסימון (באיחור)';

  @override
  String get statsThisWeekUpcomingLabel => 'מפגשים קרובים השבוע';

  @override
  String get statsNext7DaysLabel => 'מפגשים ב־7 הימים הבאים';

  @override
  String get statsStatusMixTitle => 'פילוח סטטוסים';

  @override
  String get statsPerCourseTitle => 'מפגשים שעברו לפי קורס';

  @override
  String get statsNoDataYet => 'אין עדיין נתונים';

  @override
  String get statsNoCourseBars =>
      'סמנו נוכחות או היעדרות במפגשים שעברו כדי לראות פילוח.';

  @override
  String get statsPastDecidedLabel => 'סיכום מפגשים שעברו (הוחלט)';

  @override
  String get statsBarLegendAttended => 'נוכח / הקלטה';

  @override
  String get statsBarLegendMissed => 'החסיר';

  @override
  String get courseNameRequired => 'הזן שם קורס.';

  @override
  String get deleteCourseConfirmTitle => 'למחוק את הקורס?';

  @override
  String get deleteCourseConfirmBody =>
      'פעולה זו מסירה את הקורס ואת כל המפגשים מהמערכת.';

  @override
  String get deleteCourseAction => 'מחק';

  @override
  String get editCourseTitle => 'עריכת קורס';

  @override
  String get courseInfoSection => 'פרטי קורס';

  @override
  String get courseCodeOptional => 'קוד קורס (אופציונלי)';

  @override
  String get optionalFieldHint => 'אופציונלי';

  @override
  String get courseNotesLabel => 'הערות';

  @override
  String get courseNotesHint => 'רשימת קריאה, כללי בחינה וכו׳';

  @override
  String get courseExtraLinksSection => 'קישורים נוספים';

  @override
  String get namedLinkExampleHint => 'לדוגמה: \"סילבוס (PDF)\" עם כתובת לקובץ.';

  @override
  String get linkTitleLabel => 'כותרת';

  @override
  String get linkUrlLabel => 'כתובת';

  @override
  String get addNamedLink => 'הוסף קישור';

  @override
  String get meetingsSection => 'מפגשים שבועיים';

  @override
  String get meetingLocationLabel => 'מיקום / חדר';

  @override
  String get meetingLinksSection => 'קישורים למפגש זה';

  @override
  String get meetingLinkExampleHint =>
      'לדוגמה: \"סיכום מפגש\" עם קישור למצגת או PDF.';

  @override
  String weeklySessionTitle(int number) {
    return 'מפגש שבועי $number';
  }

  @override
  String get manageCourses => 'ניהול קורסים';

  @override
  String get manageCoursesSubtitle => 'הוספה, עריכה או הסרה של קורסים';

  @override
  String get fabManageCourses => 'ניהול קורסים';

  @override
  String get themeModeLabel => 'ערכת נושא';

  @override
  String get themeModeLight => 'בהיר';

  @override
  String get themeModeDark => 'כהה';

  @override
  String get themeModeSystem => 'לפי המערכת';

  @override
  String get aboutSectionTitle => 'אודות';

  @override
  String get developerLabel => 'מפתח';

  @override
  String get versionLabel => 'גרסה';

  @override
  String get openLinkFailed => 'לא ניתן לפתוח את הקישור';

  @override
  String get resourcesSection => 'משאבים';

  @override
  String get primaryCourseLink => 'אתר הקורס';

  @override
  String get editMeetingResourcesHint =>
      'השינויים חלים על כל השבועות עבור מפגש זה.';
}
