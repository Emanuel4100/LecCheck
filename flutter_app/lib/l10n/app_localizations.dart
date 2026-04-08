import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'LecCheck'**
  String get appTitle;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'LecCheck'**
  String get dashboardTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to LecCheck'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your schedule with cloud sync.'**
  String get welcomeSubtitle;

  /// No description provided for @continueLocal.
  ///
  /// In en, this message translates to:
  /// **'Continue Local'**
  String get continueLocal;

  /// No description provided for @continueCloudComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Continue Cloud (coming soon)'**
  String get continueCloudComingSoon;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithGoogleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in (not on this platform)'**
  String get continueWithGoogleUnavailable;

  /// No description provided for @signInUnavailableThisPlatform.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not available on this platform.'**
  String get signInUnavailableThisPlatform;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed: {message}'**
  String signInFailed(String message);

  /// No description provided for @signInAndroidConfigHint.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In needs your app’s SHA-1 in Firebase. Console → Project settings → Your Android app → Add fingerprint. Then run: cd android && ./gradlew signingReport (use the SHA-1 under Variant: debug).'**
  String get signInAndroidConfigHint;

  /// No description provided for @cloudComingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'Cloud login (Google/Firebase) will be added later.'**
  String get cloudComingSoonMessage;

  /// No description provided for @semesterSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'New Semester Setup'**
  String get semesterSetupTitle;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get pickDate;

  /// No description provided for @weekStartsOn.
  ///
  /// In en, this message translates to:
  /// **'Week starts on'**
  String get weekStartsOn;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @weekdayMonShort.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMonShort;

  /// No description provided for @weekdayTueShort.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTueShort;

  /// No description provided for @weekdayWedShort.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWedShort;

  /// No description provided for @weekdayThuShort.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThuShort;

  /// No description provided for @weekdayFriShort.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFriShort;

  /// No description provided for @weekdaySatShort.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySatShort;

  /// No description provided for @weekdaySunShort.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySunShort;

  /// No description provided for @dayGeneric.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayGeneric;

  /// No description provided for @includeWeekend.
  ///
  /// In en, this message translates to:
  /// **'Include weekend (Fri/Sat)'**
  String get includeWeekend;

  /// No description provided for @continueCta.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueCta;

  /// No description provided for @semesterDateRangeError.
  ///
  /// In en, this message translates to:
  /// **'End date must be after the start date.'**
  String get semesterDateRangeError;

  /// No description provided for @semesterDurationHint.
  ///
  /// In en, this message translates to:
  /// **'Semester length: {days} days'**
  String semesterDurationHint(int days);

  /// No description provided for @setupCoursesTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup Courses'**
  String get setupCoursesTitle;

  /// No description provided for @addCoursesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your courses for this semester'**
  String get addCoursesSubtitle;

  /// No description provided for @noCoursesYet.
  ///
  /// In en, this message translates to:
  /// **'No courses yet. Add your first course.'**
  String get noCoursesYet;

  /// No description provided for @addCourse.
  ///
  /// In en, this message translates to:
  /// **'Add course'**
  String get addCourse;

  /// No description provided for @addMeeting.
  ///
  /// In en, this message translates to:
  /// **'Add meeting'**
  String get addMeeting;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @lectures.
  ///
  /// In en, this message translates to:
  /// **'Lectures'**
  String get lectures;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @shownDays.
  ///
  /// In en, this message translates to:
  /// **'Shown days'**
  String get shownDays;

  /// No description provided for @lectureDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Lecture details'**
  String get lectureDetailsTitle;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @addRecordingLink.
  ///
  /// In en, this message translates to:
  /// **'Add recording link'**
  String get addRecordingLink;

  /// No description provided for @recordingLink.
  ///
  /// In en, this message translates to:
  /// **'Recording link'**
  String get recordingLink;

  /// No description provided for @semesterWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get semesterWeekLabel;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @resetSemester.
  ///
  /// In en, this message translates to:
  /// **'Reset Semester'**
  String get resetSemester;

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @grid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get grid;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @attended.
  ///
  /// In en, this message translates to:
  /// **'Attended'**
  String get attended;

  /// No description provided for @missed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missed;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @weeklyGridView.
  ///
  /// In en, this message translates to:
  /// **'Weekly grid view'**
  String get weeklyGridView;

  /// No description provided for @addCourseFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a course first.'**
  String get addCourseFirst;

  /// No description provided for @courseName.
  ///
  /// In en, this message translates to:
  /// **'Course name'**
  String get courseName;

  /// No description provided for @courseCode.
  ///
  /// In en, this message translates to:
  /// **'Course code'**
  String get courseCode;

  /// No description provided for @addLecturer.
  ///
  /// In en, this message translates to:
  /// **'Add lecturer'**
  String get addLecturer;

  /// No description provided for @lecturer.
  ///
  /// In en, this message translates to:
  /// **'Lecturer'**
  String get lecturer;

  /// No description provided for @addCourseLink.
  ///
  /// In en, this message translates to:
  /// **'Add course link'**
  String get addCourseLink;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @course.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get course;

  /// No description provided for @weekday.
  ///
  /// In en, this message translates to:
  /// **'Weekday'**
  String get weekday;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @lectureType.
  ///
  /// In en, this message translates to:
  /// **'Lecture'**
  String get lectureType;

  /// No description provided for @practiceType.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practiceType;

  /// No description provided for @labType.
  ///
  /// In en, this message translates to:
  /// **'Lab'**
  String get labType;

  /// No description provided for @otherType.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherType;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get endTime;

  /// No description provided for @length.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get length;

  /// No description provided for @room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get room;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @showWeekend.
  ///
  /// In en, this message translates to:
  /// **'Show weekend'**
  String get showWeekend;

  /// No description provided for @autoMeetingNumbers.
  ///
  /// In en, this message translates to:
  /// **'Auto meeting numbers'**
  String get autoMeetingNumbers;

  /// No description provided for @semesterStart.
  ///
  /// In en, this message translates to:
  /// **'Semester start'**
  String get semesterStart;

  /// No description provided for @semesterEnd.
  ///
  /// In en, this message translates to:
  /// **'Semester end'**
  String get semesterEnd;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @addSession.
  ///
  /// In en, this message translates to:
  /// **'Add session'**
  String get addSession;

  /// No description provided for @addWeeklySessions.
  ///
  /// In en, this message translates to:
  /// **'Add weekly sessions'**
  String get addWeeklySessions;

  /// No description provided for @noSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No sessions added yet.'**
  String get noSessionsYet;

  /// No description provided for @courseCodePrefix.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get courseCodePrefix;

  /// No description provided for @lecturerPrefix.
  ///
  /// In en, this message translates to:
  /// **'Lecturer'**
  String get lecturerPrefix;

  /// No description provided for @addCourseNameAndSessionError.
  ///
  /// In en, this message translates to:
  /// **'Add course name and at least one session.'**
  String get addCourseNameAndSessionError;

  /// No description provided for @endAfterStartError.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time.'**
  String get endAfterStartError;

  /// No description provided for @markAttended.
  ///
  /// In en, this message translates to:
  /// **'Mark attended'**
  String get markAttended;

  /// No description provided for @markWatchedRecording.
  ///
  /// In en, this message translates to:
  /// **'Mark watched recording'**
  String get markWatchedRecording;

  /// No description provided for @markMissed.
  ///
  /// In en, this message translates to:
  /// **'Mark missed'**
  String get markMissed;

  /// No description provided for @markSkipped.
  ///
  /// In en, this message translates to:
  /// **'Mark skipped'**
  String get markSkipped;

  /// No description provided for @markCanceled.
  ///
  /// In en, this message translates to:
  /// **'Mark canceled'**
  String get markCanceled;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusAttended.
  ///
  /// In en, this message translates to:
  /// **'Attended'**
  String get statusAttended;

  /// No description provided for @statusMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get statusMissed;

  /// No description provided for @statusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get statusSkipped;

  /// No description provided for @statusWatchedRecording.
  ///
  /// In en, this message translates to:
  /// **'Watched recording'**
  String get statusWatchedRecording;

  /// No description provided for @statusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get statusCanceled;

  /// No description provided for @hourUnitShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hourUnitShort;

  /// No description provided for @minuteUnitShort.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minuteUnitShort;

  /// No description provided for @lecturesTabNeedAttention.
  ///
  /// In en, this message translates to:
  /// **'Need attention'**
  String get lecturesTabNeedAttention;

  /// No description provided for @lecturesTabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get lecturesTabUpcoming;

  /// No description provided for @lecturesTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get lecturesTabAll;

  /// No description provided for @lecturesCaughtUpTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get lecturesCaughtUpTitle;

  /// No description provided for @lecturesCaughtUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No past sessions are still waiting to be marked.'**
  String get lecturesCaughtUpSubtitle;

  /// No description provided for @lecturesMarkToKeepStreakHint.
  ///
  /// In en, this message translates to:
  /// **'Mark sessions to grow your learning streak.'**
  String get lecturesMarkToKeepStreakHint;

  /// No description provided for @lecturesNoUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No sessions in this week window.'**
  String get lecturesNoUpcoming;

  /// No description provided for @showNextWeekToo.
  ///
  /// In en, this message translates to:
  /// **'Show the following week too'**
  String get showNextWeekToo;

  /// No description provided for @showNextWeekOnly.
  ///
  /// In en, this message translates to:
  /// **'Next week only'**
  String get showNextWeekOnly;

  /// No description provided for @searchCourses.
  ///
  /// In en, this message translates to:
  /// **'Search courses'**
  String get searchCourses;

  /// No description provided for @sortByDateNewest.
  ///
  /// In en, this message translates to:
  /// **'Date (newest first)'**
  String get sortByDateNewest;

  /// No description provided for @sortByDateOldest.
  ///
  /// In en, this message translates to:
  /// **'Date (oldest first)'**
  String get sortByDateOldest;

  /// No description provided for @sortByCourse.
  ///
  /// In en, this message translates to:
  /// **'Course name'**
  String get sortByCourse;

  /// No description provided for @sortByType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get sortByType;

  /// No description provided for @sortByStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get sortByStatus;

  /// No description provided for @sortMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortMenuTooltip;

  /// No description provided for @addActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get addActionsTitle;

  /// No description provided for @goToCurrentWeek.
  ///
  /// In en, this message translates to:
  /// **'Go to current week'**
  String get goToCurrentWeek;

  /// No description provided for @focusSearchField.
  ///
  /// In en, this message translates to:
  /// **'Focus search'**
  String get focusSearchField;

  /// No description provided for @statsAttendanceHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get statsAttendanceHeroTitle;

  /// No description provided for @statsAttendanceHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share of past sessions marked attended or watched vs missed.'**
  String get statsAttendanceHeroSubtitle;

  /// No description provided for @statsStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Learning streak'**
  String get statsStreakLabel;

  /// No description provided for @statsOverduePendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Overdue to mark'**
  String get statsOverduePendingLabel;

  /// No description provided for @statsThisWeekUpcomingLabel.
  ///
  /// In en, this message translates to:
  /// **'Upcoming this week'**
  String get statsThisWeekUpcomingLabel;

  /// No description provided for @statsNext7DaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Upcoming in next 7 days'**
  String get statsNext7DaysLabel;

  /// No description provided for @statsStatusMixTitle.
  ///
  /// In en, this message translates to:
  /// **'Status mix'**
  String get statsStatusMixTitle;

  /// No description provided for @statsPerCourseTitle.
  ///
  /// In en, this message translates to:
  /// **'Past sessions by course'**
  String get statsPerCourseTitle;

  /// No description provided for @statsNoDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get statsNoDataYet;

  /// No description provided for @statsNoCourseBars.
  ///
  /// In en, this message translates to:
  /// **'Mark attended or missed on past sessions to see a course breakdown.'**
  String get statsNoCourseBars;

  /// No description provided for @statsPastDecidedLabel.
  ///
  /// In en, this message translates to:
  /// **'Past decided totals'**
  String get statsPastDecidedLabel;

  /// No description provided for @statsBarLegendAttended.
  ///
  /// In en, this message translates to:
  /// **'Attended / watched'**
  String get statsBarLegendAttended;

  /// No description provided for @statsBarLegendMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get statsBarLegendMissed;

  /// No description provided for @courseNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a course name.'**
  String get courseNameRequired;

  /// No description provided for @deleteCourseConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete course?'**
  String get deleteCourseConfirmTitle;

  /// No description provided for @deleteCourseConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the course and all its sessions from the schedule.'**
  String get deleteCourseConfirmBody;

  /// No description provided for @deleteCourseAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteCourseAction;

  /// No description provided for @editCourseTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit course'**
  String get editCourseTitle;

  /// No description provided for @courseInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Course information'**
  String get courseInfoSection;

  /// No description provided for @courseCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Course code (optional)'**
  String get courseCodeOptional;

  /// No description provided for @optionalFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalFieldHint;

  /// No description provided for @courseNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get courseNotesLabel;

  /// No description provided for @courseNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Reading list, exam rules, etc.'**
  String get courseNotesHint;

  /// No description provided for @courseExtraLinksSection.
  ///
  /// In en, this message translates to:
  /// **'Extra links'**
  String get courseExtraLinksSection;

  /// No description provided for @namedLinkExampleHint.
  ///
  /// In en, this message translates to:
  /// **'Example: \"Syllabus (PDF)\" with a URL to the file.'**
  String get namedLinkExampleHint;

  /// No description provided for @linkTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get linkTitleLabel;

  /// No description provided for @linkUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get linkUrlLabel;

  /// No description provided for @addNamedLink.
  ///
  /// In en, this message translates to:
  /// **'Add link'**
  String get addNamedLink;

  /// No description provided for @meetingsSection.
  ///
  /// In en, this message translates to:
  /// **'Weekly meetings'**
  String get meetingsSection;

  /// No description provided for @meetingLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location / room'**
  String get meetingLocationLabel;

  /// No description provided for @meetingLinksSection.
  ///
  /// In en, this message translates to:
  /// **'Links for this meeting'**
  String get meetingLinksSection;

  /// No description provided for @meetingLinkExampleHint.
  ///
  /// In en, this message translates to:
  /// **'Example: \"Meeting summary\" with a link to slides or a PDF.'**
  String get meetingLinkExampleHint;

  /// No description provided for @weeklySessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly session {number}'**
  String weeklySessionTitle(int number);

  /// No description provided for @manageCourses.
  ///
  /// In en, this message translates to:
  /// **'Manage courses'**
  String get manageCourses;

  /// No description provided for @manageCoursesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add, edit, or remove courses'**
  String get manageCoursesSubtitle;

  /// No description provided for @fabManageCourses.
  ///
  /// In en, this message translates to:
  /// **'Manage courses'**
  String get fabManageCourses;

  /// No description provided for @themeModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeModeLabel;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeModeSystem;

  /// No description provided for @aboutSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSectionTitle;

  /// No description provided for @developerLabel.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developerLabel;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @openLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get openLinkFailed;

  /// No description provided for @resourcesSection.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get resourcesSection;

  /// No description provided for @primaryCourseLink.
  ///
  /// In en, this message translates to:
  /// **'Course website'**
  String get primaryCourseLink;

  /// No description provided for @editMeetingResourcesHint.
  ///
  /// In en, this message translates to:
  /// **'Changes apply to every week for this meeting slot.'**
  String get editMeetingResourcesHint;

  /// No description provided for @lectureNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes for this session'**
  String get lectureNotesLabel;

  /// No description provided for @lectureNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Prep, assignments, reminders…'**
  String get lectureNotesHint;

  /// No description provided for @use24HourTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'24-hour time'**
  String get use24HourTimeTitle;

  /// No description provided for @use24HourTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off: AM/PM (locale style). On: 14:30 style.'**
  String get use24HourTimeSubtitle;

  /// No description provided for @dayOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Day options'**
  String get dayOptionsTitle;

  /// No description provided for @markNoClassDay.
  ///
  /// In en, this message translates to:
  /// **'No class (cancel all)'**
  String get markNoClassDay;

  /// No description provided for @markNoClassDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Marks every session this day as canceled.'**
  String get markNoClassDaySubtitle;

  /// No description provided for @clearNoClassDay.
  ///
  /// In en, this message translates to:
  /// **'Restore normal day'**
  String get clearNoClassDay;

  /// No description provided for @afterSemesterShort.
  ///
  /// In en, this message translates to:
  /// **'After term'**
  String get afterSemesterShort;

  /// No description provided for @semesterEndsThisDay.
  ///
  /// In en, this message translates to:
  /// **'Semester ends'**
  String get semesterEndsThisDay;

  /// No description provided for @gridZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom grid in'**
  String get gridZoomIn;

  /// No description provided for @gridZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom grid out'**
  String get gridZoomOut;

  /// No description provided for @gridZoomReset.
  ///
  /// In en, this message translates to:
  /// **'Reset grid zoom'**
  String get gridZoomReset;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
