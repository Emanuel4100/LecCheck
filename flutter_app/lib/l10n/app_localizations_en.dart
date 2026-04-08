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
  String get dashboardTitle => 'LecCheck';

  @override
  String get welcomeTitle => 'Welcome to LecCheck';

  @override
  String get welcomeSubtitle => 'Manage your schedule with cloud sync.';

  @override
  String get continueLocal => 'Continue Local';

  @override
  String get continueCloudComingSoon => 'Continue Cloud (coming soon)';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithGoogleUnavailable =>
      'Google sign-in (not on this platform)';

  @override
  String get signInUnavailableThisPlatform =>
      'Google sign-in is not available on this platform.';

  @override
  String signInFailed(String message) {
    return 'Sign-in failed: $message';
  }

  @override
  String get signInAndroidConfigHint =>
      'Google Sign-In needs your app’s SHA-1 in Firebase. Console → Project settings → Your Android app → Add fingerprint. Then run: cd android && ./gradlew signingReport (use the SHA-1 under Variant: debug).';

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
  String get weekdayMonShort => 'Mon';

  @override
  String get weekdayTueShort => 'Tue';

  @override
  String get weekdayWedShort => 'Wed';

  @override
  String get weekdayThuShort => 'Thu';

  @override
  String get weekdayFriShort => 'Fri';

  @override
  String get weekdaySatShort => 'Sat';

  @override
  String get weekdaySunShort => 'Sun';

  @override
  String get dayGeneric => 'Day';

  @override
  String get includeWeekend => 'Include weekend (Fri/Sat)';

  @override
  String get continueCta => 'Continue';

  @override
  String get semesterDateRangeError => 'End date must be after the start date.';

  @override
  String semesterDurationHint(int days) {
    return 'Semester length: $days days';
  }

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
  String get shownDays => 'Shown days';

  @override
  String get lectureDetailsTitle => 'Lecture details';

  @override
  String get statusLabel => 'Status';

  @override
  String get addRecordingLink => 'Add recording link';

  @override
  String get recordingLink => 'Recording link';

  @override
  String get semesterWeekLabel => 'Week';

  @override
  String get logout => 'Logout';

  @override
  String get resetSemester => 'Reset Semester';

  @override
  String get list => 'List';

  @override
  String get grid => 'Grid';

  @override
  String get attendance => 'Attendance';

  @override
  String get attended => 'Attended';

  @override
  String get missed => 'Missed';

  @override
  String get skipped => 'Skipped';

  @override
  String get pending => 'Pending';

  @override
  String get weeklyGridView => 'Weekly grid view';

  @override
  String get addCourseFirst => 'Add a course first.';

  @override
  String get courseName => 'Course name';

  @override
  String get courseCode => 'Course code';

  @override
  String get addLecturer => 'Add lecturer';

  @override
  String get lecturer => 'Lecturer';

  @override
  String get addCourseLink => 'Add course link';

  @override
  String get link => 'Link';

  @override
  String get course => 'Course';

  @override
  String get weekday => 'Weekday';

  @override
  String get type => 'Type';

  @override
  String get lectureType => 'Lecture';

  @override
  String get practiceType => 'Practice';

  @override
  String get labType => 'Lab';

  @override
  String get otherType => 'Other';

  @override
  String get startTime => 'Start time';

  @override
  String get endTime => 'End time';

  @override
  String get length => 'Length';

  @override
  String get room => 'Room';

  @override
  String get change => 'Change';

  @override
  String get showWeekend => 'Show weekend';

  @override
  String get autoMeetingNumbers => 'Auto meeting numbers';

  @override
  String get semesterStart => 'Semester start';

  @override
  String get semesterEnd => 'Semester end';

  @override
  String get reset => 'Reset';

  @override
  String get addSession => 'Add session';

  @override
  String get addWeeklySessions => 'Add weekly sessions';

  @override
  String get noSessionsYet => 'No sessions added yet.';

  @override
  String get courseCodePrefix => 'Code';

  @override
  String get lecturerPrefix => 'Lecturer';

  @override
  String get addCourseNameAndSessionError =>
      'Add course name and at least one session.';

  @override
  String get endAfterStartError => 'End time must be after start time.';

  @override
  String get markAttended => 'Mark attended';

  @override
  String get markWatchedRecording => 'Mark watched recording';

  @override
  String get markMissed => 'Mark missed';

  @override
  String get markSkipped => 'Mark skipped';

  @override
  String get markCanceled => 'Mark canceled';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusAttended => 'Attended';

  @override
  String get statusMissed => 'Missed';

  @override
  String get statusSkipped => 'Skipped';

  @override
  String get statusWatchedRecording => 'Watched recording';

  @override
  String get statusCanceled => 'Canceled';

  @override
  String get hourUnitShort => 'h';

  @override
  String get minuteUnitShort => 'm';

  @override
  String get lecturesTabNeedAttention => 'Need attention';

  @override
  String get lecturesTabUpcoming => 'Upcoming';

  @override
  String get lecturesTabAll => 'All';

  @override
  String get lecturesCaughtUpTitle => 'You\'re all caught up';

  @override
  String get lecturesCaughtUpSubtitle =>
      'No past sessions are still waiting to be marked.';

  @override
  String get lecturesMarkToKeepStreakHint =>
      'Mark sessions to grow your learning streak.';

  @override
  String get lecturesNoUpcoming => 'No sessions in this week window.';

  @override
  String get showNextWeekToo => 'Show the following week too';

  @override
  String get showNextWeekOnly => 'Next week only';

  @override
  String get searchCourses => 'Search courses';

  @override
  String get sortByDateNewest => 'Date (newest first)';

  @override
  String get sortByDateOldest => 'Date (oldest first)';

  @override
  String get sortByCourse => 'Course name';

  @override
  String get sortByType => 'Type';

  @override
  String get sortByStatus => 'Status';

  @override
  String get sortMenuTooltip => 'Sort';

  @override
  String get addActionsTitle => 'Quick actions';

  @override
  String get goToCurrentWeek => 'Go to current week';

  @override
  String get focusSearchField => 'Focus search';

  @override
  String get statsAttendanceHeroTitle => 'Attendance';

  @override
  String get statsAttendanceHeroSubtitle =>
      'Share of past sessions marked attended or watched vs missed.';

  @override
  String get statsStreakLabel => 'Learning streak';

  @override
  String get statsOverduePendingLabel => 'Overdue to mark';

  @override
  String get statsThisWeekUpcomingLabel => 'Upcoming this week';

  @override
  String get statsNext7DaysLabel => 'Upcoming in next 7 days';

  @override
  String get statsStatusMixTitle => 'Status mix';

  @override
  String get statsPerCourseTitle => 'Past sessions by course';

  @override
  String get statsNoDataYet => 'No data yet';

  @override
  String get statsNoCourseBars =>
      'Mark attended or missed on past sessions to see a course breakdown.';

  @override
  String get statsPastDecidedLabel => 'Past decided totals';

  @override
  String get statsBarLegendAttended => 'Attended / watched';

  @override
  String get statsBarLegendMissed => 'Missed';

  @override
  String get courseNameRequired => 'Enter a course name.';

  @override
  String get deleteCourseConfirmTitle => 'Delete course?';

  @override
  String get deleteCourseConfirmBody =>
      'This removes the course and all its sessions from the schedule.';

  @override
  String get deleteCourseAction => 'Delete';

  @override
  String get editCourseTitle => 'Edit course';

  @override
  String get courseInfoSection => 'Course information';

  @override
  String get courseCodeOptional => 'Course code (optional)';

  @override
  String get optionalFieldHint => 'Optional';

  @override
  String get courseNotesLabel => 'Notes';

  @override
  String get courseNotesHint => 'Reading list, exam rules, etc.';

  @override
  String get courseExtraLinksSection => 'Extra links';

  @override
  String get namedLinkExampleHint =>
      'Example: \"Syllabus (PDF)\" with a URL to the file.';

  @override
  String get linkTitleLabel => 'Title';

  @override
  String get linkUrlLabel => 'URL';

  @override
  String get addNamedLink => 'Add link';

  @override
  String get meetingsSection => 'Weekly meetings';

  @override
  String get meetingLocationLabel => 'Location / room';

  @override
  String get meetingLinksSection => 'Links for this meeting';

  @override
  String get meetingLinkExampleHint =>
      'Example: \"Meeting summary\" with a link to slides or a PDF.';

  @override
  String weeklySessionTitle(int number) {
    return 'Weekly session $number';
  }

  @override
  String get manageCourses => 'Manage courses';

  @override
  String get manageCoursesSubtitle => 'Add, edit, or remove courses';

  @override
  String get fabManageCourses => 'Manage courses';

  @override
  String get themeModeLabel => 'Theme';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeModeSystem => 'System default';

  @override
  String get aboutSectionTitle => 'About';

  @override
  String get developerLabel => 'Developer';

  @override
  String get versionLabel => 'Version';

  @override
  String get openLinkFailed => 'Could not open link';

  @override
  String get resourcesSection => 'Resources';

  @override
  String get primaryCourseLink => 'Course website';

  @override
  String get editMeetingResourcesHint =>
      'Changes apply to every week for this meeting slot.';

  @override
  String get lectureNotesLabel => 'Notes for this session';

  @override
  String get lectureNotesHint => 'Prep, assignments, reminders…';

  @override
  String get use24HourTimeTitle => '24-hour time';

  @override
  String get use24HourTimeSubtitle =>
      'Off: AM/PM (locale style). On: 14:30 style.';

  @override
  String get dayOptionsTitle => 'Day options';

  @override
  String get markNoClassDay => 'No class (cancel all)';

  @override
  String get markNoClassDaySubtitle =>
      'Marks every session this day as canceled.';

  @override
  String get clearNoClassDay => 'Restore normal day';

  @override
  String get afterSemesterShort => 'After term';

  @override
  String get semesterEndsThisDay => 'Semester ends';

  @override
  String get gridZoomIn => 'Zoom grid in';

  @override
  String get gridZoomOut => 'Zoom grid out';

  @override
  String get gridZoomReset => 'Reset grid zoom';
}
