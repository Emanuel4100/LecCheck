import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../core/auth/leccheck_auth.dart';
import '../core/config/feature_flags.dart';
import '../core/firebase/leccheck_firebase.dart';
import '../core/platform/adaptive.dart';
import '../core/schedule/schedule_bootstrap.dart';
import '../core/schedule/schedule_persistence.dart';
import '../core/ui/app_icons.dart';
import '../features/course_setup/course_editor_page.dart';
import '../features/course_setup/course_list_page.dart';
import '../features/course_setup/course_setup_screen.dart';
import '../features/dashboard/dashboard_shell.dart';
import '../features/dashboard/dashboard_types.dart';
import '../l10n/app_localizations.dart';
import '../models/schedule_models.dart';
import '../models/schedule_lectures.dart';

enum AppScreen { login, onboarding, addCourse, dashboard }

class LecCheckRoot extends StatefulWidget {
  const LecCheckRoot({
    super.key,
    required this.onLanguageChanged,
    required this.themeMode,
    required this.onThemeModeChanged,
  });
  final ValueChanged<String> onLanguageChanged;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<LecCheckRoot> createState() => _LecCheckRootState();
}

class _LecCheckRootState extends State<LecCheckRoot> with WidgetsBindingObserver {
  AppScreen screen = AppScreen.login;
  SemesterSchedule? schedule;
  DashboardTab tab = DashboardTab.weekly;
  int selectedDay = DateTime.now().weekday;
  List<Lecture>? _allLecturesCache;
  int _weeklyWeekSyncToken = 0;
  int _lecturesSearchFocusToken = 0;
  final SchedulePersistence _persistence = SchedulePersistence();
  bool _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final s = schedule;
    if (s != null) {
      unawaited(
        _persistence.persistNow(s, user: FirebaseAuth.instance.currentUser),
      );
    }
    _persistence.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      final s = schedule;
      if (s != null) {
        unawaited(
          _persistence.persistNow(s, user: FirebaseAuth.instance.currentUser),
        );
      }
    }
  }

  Future<void> _bootstrap() async {
    try {
      final r = await loadInitialScheduleState();
      if (!mounted) return;
      setState(() {
        _applyLoadedState(r);
        _bootstrapping = false;
      });
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('Bootstrap failed: $e\n$st');
      }
      if (!mounted) return;
      setState(() => _bootstrapping = false);
    }
  }

  void _applyLoadedState(({SemesterSchedule? schedule, User? user}) r) {
    schedule = r.schedule;
    if (schedule != null) {
      screen = schedule!.courses.isEmpty ? AppScreen.addCourse : AppScreen.dashboard;
      _invalidateLectureCache();
    } else if (FirebaseAuth.instance.currentUser != null) {
      screen = AppScreen.onboarding;
    } else {
      screen = AppScreen.login;
    }
  }

  void _persistSchedule() {
    final s = schedule;
    if (s == null) return;
    _persistence.persistDebounced(s, user: FirebaseAuth.instance.currentUser);
  }

  Future<void> _handleReset() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await _persistence.clearLocal();
    if (uid != null && FeatureFlags.enableFirebaseSync) {
      await _persistence.clearCloud(uid);
    }
    if (!mounted) return;
    setState(() {
      schedule = null;
      screen = AppScreen.onboarding;
      _invalidateLectureCache();
      _weeklyWeekSyncToken = 0;
    });
  }

  Future<void> _handleLogout() async {
    await signOutEverywhere();
    if (!mounted) return;
    setState(() {
      schedule = null;
      screen = AppScreen.login;
      _invalidateLectureCache();
      _weeklyWeekSyncToken = 0;
    });
  }

  Future<void> _onGoogleSignedIn() async {
    final r = await loadInitialScheduleState();
    if (!mounted) return;
    setState(() => _applyLoadedState(r));
  }

  void _invalidateLectureCache() {
    _allLecturesCache = null;
  }

  List<Lecture> get allLectures {
    final sc = schedule;
    if (sc == null) return [];
    return _allLecturesCache ??=
        sc.courses.expand((course) => course.lectures).toList();
  }

  void _jumpWeeklyToCurrentWeek() {
    setState(() => _weeklyWeekSyncToken++);
  }

  void _requestLecturesSearchFocus() {
    setState(() => _lecturesSearchFocusToken++);
  }

  double get attendancePercent {
    final past = allLectures
        .where((l) => l.date.isBefore(DateTime.now()))
        .toList();
    final attended = past
        .where(
          (l) =>
              l.status == LectureStatus.attended ||
              l.status == LectureStatus.watchedRecording,
        )
        .length;
    final missed = past.where((l) => l.status == LectureStatus.missed).length;
    final total = attended + missed;
    if (total == 0) return 0;
    return attended / total;
  }

  Future<void> createSchedule(
    String lang,
    DateTime start,
    DateTime end,
    int weekStartsOn,
  ) async {
    setState(() {
      schedule = SemesterSchedule(
        startDate: start,
        endDate: end,
        language: lang,
        weekStartsOn: weekStartsOn,
      );
      selectedDay = weekStartsOn;
      screen = AppScreen.addCourse;
      _invalidateLectureCache();
    });
    widget.onLanguageChanged(lang);
    final s = schedule;
    if (s != null) {
      await _persistence.persistNow(s, user: FirebaseAuth.instance.currentUser);
    }
  }

  static Meeting _cloneMeeting(Meeting m) {
    return Meeting(
      id: m.id,
      weekday: m.weekday,
      start: m.start,
      end: m.end,
      room: m.room,
      type: m.type,
      links: m.links
          .map((l) => NamedLink(title: l.title, url: l.url))
          .toList(),
    );
  }

  void _createCourse(CourseEditorPayload payload, List<Meeting> meetings) {
    final sc = schedule;
    if (sc == null) return;
    final course = Course(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      name: payload.name,
      lecturer: payload.lecturer,
      code: payload.code,
      link: payload.link,
      notes: payload.notes,
      extraLinks: payload.extraLinks
          .map((e) => NamedLink(title: e.title, url: e.url))
          .toList(),
      color: payload.color,
    );
    for (final m in meetings) {
      course.meetings.add(_cloneMeeting(m));
    }
    rebuildLecturesForCourse(course, sc);
    sc.courses.add(course);
    setState(_invalidateLectureCache);
    _persistSchedule();
  }

  void _updateCourse(
    Course course,
    CourseEditorPayload payload,
    List<Meeting> meetings,
  ) {
    final sc = schedule;
    if (sc == null) return;
    course.name = payload.name;
    course.lecturer = payload.lecturer;
    course.code = payload.code;
    course.link = payload.link;
    course.notes = payload.notes;
    course.color = payload.color;
    course.extraLinks.clear();
    for (final e in payload.extraLinks) {
      course.extraLinks.add(NamedLink(title: e.title, url: e.url));
    }
    course.meetings.clear();
    for (final m in meetings) {
      course.meetings.add(_cloneMeeting(m));
    }
    rebuildLecturesForCourse(course, sc);
    setState(_invalidateLectureCache);
    _persistSchedule();
  }

  void _deleteCourse(Course course) {
    schedule?.courses.remove(course);
    setState(_invalidateLectureCache);
    _persistSchedule();
  }

  void addMeeting(Course course, Meeting meeting) {
    final sc = schedule;
    if (sc == null) return;
    course.meetings.add(_cloneMeeting(meeting));
    rebuildLecturesForCourse(course, sc);
    setState(_invalidateLectureCache);
    _persistSchedule();
  }

  void _updateMeetingLinks(
    Course course,
    Meeting meeting,
    List<NamedLink> links,
  ) {
    final sc = schedule;
    if (sc == null) return;
    meeting.links.clear();
    for (final l in links) {
      meeting.links.add(NamedLink(title: l.title, url: l.url));
    }
    rebuildLecturesForCourse(course, sc);
    setState(_invalidateLectureCache);
    _persistSchedule();
  }

  void _pushCourseEditor(BuildContext context, {Course? existing}) {
    final sc = schedule;
    if (sc == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => CourseEditorPage(
          schedule: sc,
          existing: existing,
          onSaved: (payload, meetings) {
            if (existing == null) {
              _createCourse(payload, meetings);
            } else {
              _updateCourse(existing, payload, meetings);
            }
          },
          onDeleted: existing != null ? () => _deleteCourse(existing) : null,
        ),
      ),
    );
  }

  void _pushManageCourses(BuildContext context) {
    final sc = schedule;
    if (sc == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => CourseListPage(
          schedule: sc,
          onCreate: (navCtx) => _pushCourseEditor(navCtx, existing: null),
          onEdit: (navCtx, course) =>
              _pushCourseEditor(navCtx, existing: course),
        ),
      ),
    );
  }

  void updateLanguage(String language) {
    final sc = schedule;
    if (sc == null) return;
    setState(() => sc.language = language);
    widget.onLanguageChanged(language);
    _persistSchedule();
  }

  void updateVisibleDays(Set<int> days) {
    final sc = schedule;
    if (sc == null) return;
    final sanitized = days.isEmpty ? {1, 2, 3, 4, 5, 6, 7} : days;
    setState(() {
      sc.visibleWeekdays = sanitized;
      if (!sc.visibleWeekdays.contains(selectedDay)) {
        final ordered = orderedWeekdaysForSchedule(sc);
        selectedDay = ordered.isEmpty ? sc.weekStartsOn : ordered.first;
      }
    });
    _persistSchedule();
  }

  void updateMeetingNumbers(bool value) {
    final sc = schedule;
    if (sc == null) return;
    setState(() => sc.enableMeetingNumbers = value);
    _persistSchedule();
  }

  void updateStartDate(DateTime date) {
    final sc = schedule;
    if (sc == null) return;
    setState(() {
      sc.startDate = date;
      for (final c in sc.courses) {
        rebuildLecturesForCourse(c, sc);
      }
      _invalidateLectureCache();
    });
    _persistSchedule();
  }

  void updateEndDate(DateTime date) {
    final sc = schedule;
    if (sc == null) return;
    setState(() {
      sc.endDate = date;
      for (final c in sc.courses) {
        rebuildLecturesForCourse(c, sc);
      }
      _invalidateLectureCache();
    });
    _persistSchedule();
  }

  void updateWeekStartsOn(int weekday) {
    final sc = schedule;
    if (sc == null) return;
    final activeDays = orderedWeekdaysForSchedule(sc);
    setState(() {
      sc.weekStartsOn = weekday;
      final nextActiveDays = orderedWeekdaysForSchedule(sc);
      if (!nextActiveDays.contains(selectedDay)) {
        selectedDay = nextActiveDays.first;
      } else if (!activeDays.contains(selectedDay)) {
        selectedDay = weekday;
      }
    });
    _persistSchedule();
  }

  @override
  Widget build(BuildContext context) {
    if (_bootstrapping) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    switch (screen) {
      case AppScreen.login:
        return _LoginScreen(
          onGuest: () => setState(() => screen = AppScreen.onboarding),
          onGoogleSignedIn: _onGoogleSignedIn,
        );
      case AppScreen.onboarding:
        return _Onboarding(
          onStart: (lang, start, end, week) =>
              unawaited(createSchedule(lang, start, end, week)),
          onLanguageChanged: widget.onLanguageChanged,
        );
      case AppScreen.addCourse:
        return CourseSetupScreen(
          schedule: schedule!,
          onCreateCourse: _createCourse,
          onContinue: () {
            setState(() => screen = AppScreen.dashboard);
            _persistSchedule();
          },
          onBack: () => setState(() => screen = AppScreen.onboarding),
        );
      case AppScreen.dashboard:
        return DashboardShell(
          schedule: schedule!,
          tab: tab,
          allLectures: allLectures,
          attendance: attendancePercent,
          onChangeTab: (v) => setState(() => tab = v),
          onStatus: (l, s) {
            setState(() => l.status = s);
            _persistSchedule();
          },
          onAddMeeting: addMeeting,
          onOpenCourseEditor: (ctx) => _pushCourseEditor(ctx, existing: null),
          onOpenManageCourses: _pushManageCourses,
          onMeetingLinksSaved: _updateMeetingLinks,
          onChangeLanguage: updateLanguage,
          onChangeWeekStart: updateWeekStartsOn,
          onChangeVisibleDays: updateVisibleDays,
          onToggleMeetingNumbers: updateMeetingNumbers,
          onChangeStartDate: updateStartDate,
          onChangeEndDate: updateEndDate,
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          onReset: () => unawaited(_handleReset()),
          onLogout: () => unawaited(_handleLogout()),
          weeklyWeekSyncToken: _weeklyWeekSyncToken,
          onJumpToCurrentWeek: _jumpWeeklyToCurrentWeek,
          lecturesSearchFocusToken: _lecturesSearchFocusToken,
          onRequestLecturesSearchFocus: _requestLecturesSearchFocus,
        );
    }
  }
}

class _LoginScreen extends StatefulWidget {
  const _LoginScreen({
    required this.onGuest,
    required this.onGoogleSignedIn,
  });

  final VoidCallback onGuest;
  final Future<void> Function() onGoogleSignedIn;

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  bool _busy = false;

  Future<void> _onGooglePressed(BuildContext context) async {
    if (!firebaseSupportedOnThisPlatform) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signInUnavailableThisPlatform)),
      );
      return;
    }
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final cred = await signInWithGoogle();
      if (!context.mounted) return;
      if (cred == null) return;
      await widget.onGoogleSignedIn();
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.signInFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final googleAvailable = FeatureFlags.enableGoogleSignIn &&
        googleSignInSupportedOnPlatform &&
        firebaseSupportedOnThisPlatform;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Adaptive.maxBodyWidth(context)),
          child: Card(
            child: SizedBox(
              width: 520,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎓', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 12),
                    Text(
                      l10n.welcomeTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.welcomeSubtitle),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : widget.onGuest,
                      child: Text(l10n.continueLocal),
                    ),
                    const SizedBox(height: 8),
                    if (FeatureFlags.enableGoogleSignIn)
                      OutlinedButton.icon(
                        onPressed: _busy || !googleAvailable
                            ? null
                            : () => _onGooglePressed(context),
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.login),
                        label: Text(
                          googleAvailable
                              ? l10n.continueWithGoogle
                              : l10n.continueWithGoogleUnavailable,
                        ),
                      )
                    else
                      OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.cloudComingSoonMessage),
                            ),
                          );
                        },
                        child: Text(l10n.continueCloudComingSoon),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Onboarding extends StatefulWidget {
  const _Onboarding({
    required this.onStart,
    required this.onLanguageChanged,
  });

  final void Function(
    String lang,
    DateTime start,
    DateTime end,
    int weekStartsOn,
  ) onStart;

  final ValueChanged<String> onLanguageChanged;

  @override
  State<_Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<_Onboarding> {
  String lang = 'en';
  DateTime start = DateTime.now();
  DateTime end = DateTime.now().add(const Duration(days: 120));
  int weekStartsOn = 1;

  int get _lengthDays {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return e.difference(s).inDays;
  }

  bool get _datesInvalid {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !e.isAfter(s);
  }

  void _submit(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    if (!e.isAfter(s)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.semesterDateRangeError)),
      );
      return;
    }
    widget.onStart(lang, start, end, weekStartsOn);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxW = MediaQuery.sizeOf(context).width - 32;
    final cardWidth = maxW < 560 ? maxW : 560.0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cardWidth),
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.semesterSetupTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.appTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: const Icon(AppIcons.language),
                          title: Text(l10n.language),
                          subtitle: DropdownButtonFormField<String>(
                            key: ValueKey(lang),
                            initialValue: lang,
                            items: const [
                              DropdownMenuItem(
                                value: 'he',
                                child: Text('עברית'),
                              ),
                              DropdownMenuItem(
                                value: 'en',
                                child: Text('English'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => lang = v);
                              widget.onLanguageChanged(v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _datesInvalid
                            ? l10n.semesterDateRangeError
                            : l10n.semesterDurationHint(_lengthDays),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _datesInvalid
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.startDate),
                        subtitle: Text(
                          MaterialLocalizations.of(context).formatMediumDate(
                            start,
                          ),
                        ),
                        trailing: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: start,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setState(() => start = picked);
                            }
                          },
                          child: Text(l10n.pickDate),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.endDate),
                        subtitle: Text(
                          MaterialLocalizations.of(context).formatMediumDate(
                            end,
                          ),
                        ),
                        trailing: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: end,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setState(() => end = picked);
                            }
                          },
                          child: Text(l10n.pickDate),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        key: ValueKey(weekStartsOn),
                        initialValue: weekStartsOn,
                        decoration: InputDecoration(
                          labelText: l10n.weekStartsOn,
                          prefixIcon: const Icon(Icons.date_range),
                          border: const OutlineInputBorder(),
                        ),
                        items: List.generate(
                          7,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(
                              [
                                l10n.weekdayMonShort,
                                l10n.weekdayTueShort,
                                l10n.weekdayWedShort,
                                l10n.weekdayThuShort,
                                l10n.weekdayFriShort,
                                l10n.weekdaySatShort,
                                l10n.weekdaySunShort,
                              ][i],
                            ),
                          ),
                        ),
                        onChanged: (v) =>
                            setState(() => weekStartsOn = v ?? 1),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => _submit(context),
                        child: Text(l10n.continueCta),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
