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
  String get includeWeekend => 'כלול סוף שבוע (שישי/שבת)';

  @override
  String get continueCta => 'המשך';

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
  String get logout => 'התנתקות';

  @override
  String get resetSemester => 'איפוס סמסטר';
}
