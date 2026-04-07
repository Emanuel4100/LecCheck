// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LecCheck';

  @override
  String get welcomeTitle => 'Welcome to LecCheck';

  @override
  String get welcomeSubtitle => 'Manage your schedule with cloud sync.';

  @override
  String get continueLocal => 'Continue Local';

  @override
  String get continueCloudComingSoon => 'Continue Cloud (coming soon)';

  @override
  String get cloudComingSoonMessage =>
      'Cloud login (Google/Firebase) will be added later.';

  @override
  String get semesterSetupTitle => 'New Semester Setup';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get pickDate => 'Pick';

  @override
  String get weekStartsOn => 'Week starts on';

  @override
  String get sunday => 'Sunday';

  @override
  String get monday => 'Monday';

  @override
  String get includeWeekend => 'Include weekend (Fri/Sat)';

  @override
  String get continueCta => 'Continue';

  @override
  String get setupCoursesTitle => 'Setup Courses';

  @override
  String get addCoursesSubtitle => 'Add your courses for this semester';

  @override
  String get noCoursesYet => 'No courses yet. Add your first course.';

  @override
  String get addCourse => 'Add course';

  @override
  String get addMeeting => 'Add meeting';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get settings => 'Settings';

  @override
  String get weekly => 'Weekly';

  @override
  String get lectures => 'Lectures';

  @override
  String get stats => 'Stats';

  @override
  String get language => 'Language';

  @override
  String get logout => 'Logout';

  @override
  String get resetSemester => 'Reset Semester';
}
