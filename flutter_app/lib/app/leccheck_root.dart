import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/leccheck_auth.dart';
import '../core/auth/linux_auth_bridge.dart';
import '../core/config/feature_flags.dart';
import '../core/config/test_zone.dart';
import '../core/firebase/leccheck_firebase.dart';
import '../core/platform/adaptive.dart';
import '../core/schedule/firestore_schedule_store.dart';
import '../core/schedule/local_schedule_store.dart';
import '../core/schedule/merge_prefs.dart';
import '../core/notifications/meeting_notifications.dart';
import '../features/dashboard/dashboard_utils.dart' show lectureEndDateTime;
import '../core/schedule/schedule_backup.dart';
import '../core/schedule/schedule_bootstrap.dart';
import '../core/schedule/schedule_persistence.dart';
import '../core/ui/app_icons.dart';
import '../features/course_setup/course_editor_page.dart';
import '../features/course_setup/course_list_page.dart';
import '../features/course_setup/course_setup_screen.dart';
import '../features/dashboard/dashboard_shell.dart';
import '../features/dashboard/dashboard_types.dart';
import '../features/dashboard/lecture_detail_sheet.dart';
import '../l10n/app_localizations.dart';
import '../models/schedule_models.dart';
import '../models/schedule_lectures.dart';
import '../models/schedule_serialization.dart';

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

  /// Debug / `flutter test` only: skips [loadInitialScheduleState] when set.
  static Future<({ScheduleRootState? root, User? user})> Function()?
      debugBootstrapOverride;

  @override
  State<LecCheckRoot> createState() => _LecCheckRootState();
}

class _LecCheckRootState extends State<LecCheckRoot> with WidgetsBindingObserver {
  AppScreen screen = AppScreen.login;
  ScheduleRootState? _scheduleRoot;
  /// Active semester; kept in sync with [_scheduleRoot].
  SemesterSchedule? schedule;
  DashboardTab tab = DashboardTab.weekly;
  int selectedDay = DateTime.now().weekday;
  List<Lecture>? _allLecturesCache;
  int _weeklyWeekSyncToken = 0;
  int _lecturesSearchFocusToken = 0;
  late final SchedulePersistence _persistence = SchedulePersistence(
    firestore: _cloudStore(),
  );
  bool _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setMeetingNotificationActionHandler(_handleMeetingNotificationAction);
    });
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    setMeetingNotificationActionHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    final root = _scheduleRoot;
    if (root != null) {
      unawaited(
        _persistence.persistNow(root, user: firebaseCurrentUserIfReady),
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
      final root = _scheduleRoot;
      if (root != null) {
        unawaited(
          _persistence.persistNow(root, user: firebaseCurrentUserIfReady),
        );
      }
    }
  }

  Future<({ScheduleRootState? root, User? user})> _loadInitialSchedule() async {
    final loader = kDebugMode ? LecCheckRoot.debugBootstrapOverride : null;
    return (loader ?? loadInitialScheduleState)();
  }

  Future<void> _bootstrap() async {
    try {
      // Avoid reading currentUser / cloud before native auth has restored the session.
      final inWidgetTestZone =
          Zone.current[leccheckWidgetTestZoneKey] == true;
      if (firebaseSupportedOnThisPlatform &&
          isFirebaseInitialized &&
          !inWidgetTestZone) {
        try {
          await FirebaseAuth.instance
              .authStateChanges()
              .timeout(const Duration(seconds: 5))
              .first;
        } on TimeoutException {
          if (kDebugMode) {
            debugPrint(
              'authStateChanges().first timed out; continuing with currentUser.',
            );
          }
        }
      }
      final r = await _loadInitialSchedule();
      if (!mounted) return;
      setState(() {
        _applyLoadedState(r);
        _bootstrapping = false;
      });
      _scheduleSyncAppLocaleFromSchedule();
      unawaited(rescheduleMeetingNotifications(_scheduleRoot));
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('Bootstrap failed: $e\n$st');
      }
      if (!mounted) return;
      setState(() => _bootstrapping = false);
    }
  }

  void _applyLoadedState(({ScheduleRootState? root, User? user}) r) {
    _scheduleRoot = r.root;
    schedule = _scheduleRoot?.activeSchedule;
    if (schedule != null) {
      screen = schedule!.courses.isEmpty ? AppScreen.addCourse : AppScreen.dashboard;
      _invalidateLectureCache();
    } else if (currentAuthUid != null) {
      screen = AppScreen.onboarding;
    } else {
      screen = AppScreen.login;
    }
  }

  /// [MaterialApp] in [main.dart] defaults to English; sync from loaded semester
  /// so cold start matches [SemesterSchedule.language] (e.g. Hebrew).
  void _syncAppLocaleFromSchedule() {
    final lang = schedule?.language;
    if (lang == null || lang.isEmpty) return;
    if (lang != 'he' && lang != 'en') return;
    widget.onLanguageChanged(lang);
  }

  void _scheduleSyncAppLocaleFromSchedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncAppLocaleFromSchedule();
    });
  }

  void _persistSchedule() {
    final root = _scheduleRoot;
    if (root == null) return;
    _persistence.persistDebounced(root);
    unawaited(rescheduleMeetingNotifications(root));
  }

  void _handleMeetingNotificationAction(String payload, String actionId) {
    if (!mounted) return;
    final parts = payload.split('|');
    if (parts.length != 4) return;
    final courseId = parts[0];
    final dateKey = parts[1];
    final start = parts[2];
    final end = parts[3];
    final root = _scheduleRoot;
    if (root == null) return;
    final sch = root.activeSchedule;
    for (final c in sch.courses) {
      if (c.id != courseId) continue;
      for (final l in c.lectures) {
        if (scheduleDateKey(l.date) == dateKey &&
            l.start == start &&
            l.end == end) {
          final status = switch (actionId) {
            'attended' => LectureStatus.attended,
            'missed' => LectureStatus.missed,
            'skipped' => LectureStatus.skipped,
            _ => null,
          };
          if (status != null) {
            setState(() => l.status = status);
            _persistSchedule();
          }
          return;
        }
      }
    }
  }

  void _refreshMeetingNotifications() {
    unawaited(rescheduleMeetingNotifications(_scheduleRoot));
  }

  Future<void> _handleReset() async {
    final uid = currentAuthUid;
    await _persistence.clearLocal();
    await _clearPendingLocalMerge();
    if (uid != null && FeatureFlags.enableFirebaseSync) {
      await _persistence.clearCloud(uid);
    }
    if (!mounted) return;
    setState(() {
      _scheduleRoot = null;
      schedule = null;
      screen = AppScreen.onboarding;
      _invalidateLectureCache();
      _weeklyWeekSyncToken = 0;
    });
  }

  Future<void> _handleLogout() async {
    await signOutEverywhere();
    await _clearPendingLocalMerge();
    if (!mounted) return;
    setState(() {
      _scheduleRoot = null;
      schedule = null;
      screen = AppScreen.login;
      _invalidateLectureCache();
      _weeklyWeekSyncToken = 0;
    });
  }

  Future<void> _clearPendingLocalMerge() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(kPendingLocalMergeKey, false);
  }

  Future<void> _markPendingLocalMerge() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(kPendingLocalMergeKey, true);
  }

  Future<void> _onGoogleSignedIn(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingMerge = prefs.getBool(kPendingLocalMergeKey) ?? false;
    final user = firebaseCurrentUserIfReady;
    final uid = currentAuthUid;

    if (pendingMerge &&
        uid != null &&
        FeatureFlags.enableFirebaseSync &&
        isCloudAvailable) {
      final local = LocalScheduleStore();
      final cloud = _cloudStore();
      final localRaw = await local.loadRaw();
      final localRoot = scheduleRootFromJson(localRaw);
      if (localRoot != null) {
        final map = scheduleRootToJson(
          localRoot,
          savedAtMillis: DateTime.now().millisecondsSinceEpoch,
        );
        await local.saveRaw(map);
        await cloud.pushRaw(uid, map);
        await prefs.setBool(kPendingLocalMergeKey, false);
        if (!mounted) return;
        setState(() => _applyLoadedState((root: localRoot, user: user)));
        _scheduleSyncAppLocaleFromSchedule();
        return;
      }
      await prefs.setBool(kPendingLocalMergeKey, false);
    }

    if (uid != null &&
        FeatureFlags.enableFirebaseSync &&
        isCloudAvailable &&
        !pendingMerge) {
      final local = LocalScheduleStore();
      final cloud = _cloudStore();
      final localRaw = await local.loadRaw();
      final cloudRaw = await cloud.pullRaw(uid);
      final localRoot = scheduleRootFromJson(localRaw);
      final cloudRoot = scheduleRootFromJson(cloudRaw);
      final localAt = scheduleBundleSavedAt(localRaw) ?? 0;
      final cloudAt = scheduleBundleSavedAt(cloudRaw) ?? 0;
      if (localRoot != null &&
          cloudRoot != null &&
          localAt > 0 &&
          cloudAt > 0 &&
          localAt != cloudAt &&
          context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        final choice = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.syncConflictTitle),
            content: Text(l10n.syncConflictBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: Text(l10n.cancel),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(ctx, 'cloud'),
                child: Text(l10n.syncConflictUseCloud),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, 'local'),
                child: Text(l10n.syncConflictUseDevice),
              ),
            ],
          ),
        );
        if (!mounted) return;
        if (choice == 'local') {
          final map = scheduleRootToJson(
            localRoot,
            savedAtMillis: DateTime.now().millisecondsSinceEpoch,
          );
          await local.saveRaw(map);
          await cloud.pushRaw(uid, map);
          await prefs.setBool(kPendingLocalMergeKey, false);
          setState(() => _applyLoadedState((root: localRoot, user: user)));
          _scheduleSyncAppLocaleFromSchedule();
          return;
        }
        if (choice == 'cloud') {
          if (cloudRaw != null) await local.saveRaw(cloudRaw);
          await prefs.setBool(kPendingLocalMergeKey, false);
          setState(() => _applyLoadedState((root: cloudRoot, user: user)));
          _scheduleSyncAppLocaleFromSchedule();
          return;
        }
      }
    }

    final r = await _loadInitialSchedule();
    if (!mounted) return;
    await prefs.setBool(kPendingLocalMergeKey, false);
    setState(() => _applyLoadedState(r));
    _scheduleSyncAppLocaleFromSchedule();
  }

  /// Returns a [FirestoreScheduleStore] appropriate for the current platform
  /// (REST-based on Linux, SDK-based elsewhere).
  static FirestoreScheduleStore _cloudStore() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      return createLinuxFirestoreStore();
    }
    return FirestoreScheduleStore();
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
    final now = DateTime.now();
    final past = allLectures
        .where((l) => lectureEndDateTime(l).isBefore(now))
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

  String _newSemesterId() => 'sem_${DateTime.now().microsecondsSinceEpoch}';

  Future<void> createSchedule(
    String lang,
    DateTime start,
    DateTime end,
    int weekStartsOn,
  ) async {
    final sch = SemesterSchedule(
      startDate: start,
      endDate: end,
      language: lang,
      weekStartsOn: weekStartsOn,
    );
    final id = _newSemesterId();
    final root = ScheduleRootState(
      slots: [
        SemesterSlot(
          id: id,
          name: 'Semester',
          schedule: sch,
        ),
      ],
      activeSemesterId: id,
    );
    setState(() {
      _scheduleRoot = root;
      schedule = sch;
      selectedDay = weekStartsOn;
      screen = AppScreen.addCourse;
      _invalidateLectureCache();
    });
    widget.onLanguageChanged(lang);
    await _persistence.persistNow(root, user: firebaseCurrentUserIfReady);
  }

  void switchActiveSemester(String semesterId) {
    final root = _scheduleRoot;
    if (root == null) return;
    if (!root.slots.any((s) => s.id == semesterId)) return;
    setState(() {
      root.activeSemesterId = semesterId;
      schedule = root.activeSchedule;
      final activeDays = orderedWeekdaysForSchedule(schedule!);
      if (!activeDays.contains(selectedDay)) {
        selectedDay = activeDays.isEmpty ? schedule!.weekStartsOn : activeDays.first;
      }
      tab = DashboardTab.weekly;
      screen = schedule!.courses.isEmpty ? AppScreen.addCourse : AppScreen.dashboard;
      _invalidateLectureCache();
      _weeklyWeekSyncToken++;
    });
    _persistSchedule();
  }

  void addSemester(String name, DateTime start, DateTime end) {
    final root = _scheduleRoot;
    if (root == null) return;
    final template = schedule;
    final lang = template?.language ?? 'en';
    final weekStartsOn = template?.weekStartsOn ?? 1;
    final sch = SemesterSchedule(
      startDate: start,
      endDate: end,
      language: lang,
      weekStartsOn: weekStartsOn,
    );
    final id = _newSemesterId();
    final trimmed = name.trim();
    final slot = SemesterSlot(
      id: id,
      name: trimmed.isEmpty ? 'Semester' : trimmed,
      schedule: sch,
    );
    setState(() {
      root.slots.add(slot);
      root.activeSemesterId = id;
      schedule = sch;
      selectedDay = weekStartsOn;
      screen = AppScreen.addCourse;
      _invalidateLectureCache();
      _weeklyWeekSyncToken++;
    });
    _persistSchedule();
  }

  void renameSemester(String semesterId, String name) {
    final root = _scheduleRoot;
    if (root == null) return;
    for (final s in root.slots) {
      if (s.id == semesterId) {
        setState(() => s.name = name.trim());
        _persistSchedule();
        return;
      }
    }
  }

  Future<void> deleteSemester(String semesterId) async {
    final root = _scheduleRoot;
    if (root == null || root.slots.length <= 1) return;
    setState(() {
      root.slots.removeWhere((s) => s.id == semesterId);
      if (root.activeSemesterId == semesterId) {
        root.activeSemesterId = root.slots.first.id;
      }
      schedule = root.activeSchedule;
      final activeDays = orderedWeekdaysForSchedule(schedule!);
      if (!activeDays.contains(selectedDay)) {
        selectedDay = activeDays.isEmpty ? schedule!.weekStartsOn : activeDays.first;
      }
      screen = schedule!.courses.isEmpty ? AppScreen.addCourse : AppScreen.dashboard;
      _invalidateLectureCache();
      _weeklyWeekSyncToken++;
    });
    _persistSchedule();
  }

  Future<void> _exportScheduleData() async {
    final root = _scheduleRoot;
    if (root == null) return;
    await exportScheduleRoot(root);
  }

  Future<void> _importScheduleData(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final imported = await pickAndParseScheduleImport(context, l10n);
    if (imported == null || !context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.importReplaceConfirmTitle),
        content: Text(l10n.importReplaceConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.importDataTitle),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _scheduleRoot = imported;
      schedule = imported.activeSchedule;
      tab = DashboardTab.weekly;
      final activeDays = orderedWeekdaysForSchedule(schedule!);
      selectedDay = activeDays.contains(schedule!.weekStartsOn)
          ? schedule!.weekStartsOn
          : (activeDays.isEmpty ? schedule!.weekStartsOn : activeDays.first);
      screen = schedule!.courses.isEmpty ? AppScreen.addCourse : AppScreen.dashboard;
      _invalidateLectureCache();
      _weeklyWeekSyncToken++;
    });
    await _persistence.persistNow(imported, user: firebaseCurrentUserIfReady);
  }

  static Meeting _cloneMeeting(Meeting m) {
    return Meeting(
      id: m.id,
      weekday: m.weekday,
      start: m.start,
      end: m.end,
      room: m.room,
      type: m.type,
      specificDate: m.specificDate,
      links: m.links
          .map((l) => NamedLink(title: l.title, url: l.url))
          .toList(),
    );
  }

  void _rebuildAndApplyNoClass(Course course) {
    final sc = schedule;
    if (sc == null) return;
    rebuildLecturesForCourse(course, sc);
    applyNoClassDatesToSchedule(sc);
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
    _rebuildAndApplyNoClass(course);
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
    _rebuildAndApplyNoClass(course);
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
    _rebuildAndApplyNoClass(course);
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
    _rebuildAndApplyNoClass(course);
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

  void updateUse24HourTime(bool value) {
    final sc = schedule;
    if (sc == null) return;
    setState(() => sc.use24HourTime = value);
    _persistSchedule();
  }

  void markNoClassDay(DateTime date) {
    final sc = schedule;
    if (sc == null) return;
    final key = scheduleDateKey(date);
    setState(() {
      sc.noClassDateKeys.add(key);
      for (final c in sc.courses) {
        for (final l in c.lectures) {
          if (scheduleDateKey(l.date) == key) {
            l.status = LectureStatus.canceled;
          }
        }
      }
      _invalidateLectureCache();
    });
    _persistSchedule();
  }

  void clearNoClassDay(DateTime date) {
    final sc = schedule;
    if (sc == null) return;
    final key = scheduleDateKey(date);
    setState(() {
      sc.noClassDateKeys.remove(key);
      for (final c in sc.courses) {
        for (final l in c.lectures) {
          if (scheduleDateKey(l.date) == key) {
            l.status = LectureStatus.pending;
          }
        }
      }
      _invalidateLectureCache();
    });
    _persistSchedule();
  }

  void _pruneNoClassDateKeys(SemesterSchedule sc) {
    sc.noClassDateKeys.removeWhere((key) {
      final parts = key.split('-');
      if (parts.length != 3) return true;
      final y = int.tryParse(parts[0]);
      final mo = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y == null || mo == null || d == null) return true;
      final dt = DateTime(y, mo, d);
      return dt.isBefore(
            DateTime(sc.startDate.year, sc.startDate.month, sc.startDate.day),
          ) ||
          dt.isAfter(
            DateTime(sc.endDate.year, sc.endDate.month, sc.endDate.day),
          );
    });
  }

  void addVacationRange(DateTime start, DateTime end) {
    final sc = schedule;
    if (sc == null) return;
    var a = DateTime(start.year, start.month, start.day);
    var b = DateTime(end.year, end.month, end.day);
    if (a.isAfter(b)) {
      final t = a;
      a = b;
      b = t;
    }
    final semStart =
        DateTime(sc.startDate.year, sc.startDate.month, sc.startDate.day);
    final semEnd = DateTime(sc.endDate.year, sc.endDate.month, sc.endDate.day);
    setState(() {
      for (var d = a; !d.isAfter(b); d = d.add(const Duration(days: 1))) {
        if (d.isBefore(semStart) || d.isAfter(semEnd)) continue;
        final key = scheduleDateKey(d);
        sc.noClassDateKeys.add(key);
        for (final c in sc.courses) {
          for (final l in c.lectures) {
            if (scheduleDateKey(l.date) == key) {
              l.status = LectureStatus.canceled;
            }
          }
        }
      }
      _invalidateLectureCache();
    });
    _persistSchedule();
  }

  void clearAllNoClassDays() {
    final sc = schedule;
    if (sc == null) return;
    setState(() {
      final keys = sc.noClassDateKeys.toList();
      sc.noClassDateKeys.clear();
      for (final c in sc.courses) {
        for (final l in c.lectures) {
          if (keys.contains(scheduleDateKey(l.date))) {
            l.status = LectureStatus.pending;
          }
        }
      }
      _invalidateLectureCache();
    });
    _persistSchedule();
  }

  Future<void> openLectureDetail(BuildContext context, Lecture lecture) async {
    final sc = schedule;
    if (sc == null) return;
    final l10n = AppLocalizations.of(context)!;
    await showLectureDetailEditor(
      context,
      schedule: sc,
      lecture: lecture,
      allLectures: allLectures,
      l10n: l10n,
      onStatus: (l, s) {
        setState(() => l.status = s);
        _persistSchedule();
      },
      onMeetingLinksSaved: _updateMeetingLinks,
    );
    if (mounted) setState(_invalidateLectureCache);
  }

  void updateStartDate(DateTime date) {
    final sc = schedule;
    if (sc == null) return;
    setState(() {
      sc.startDate = date;
      _pruneNoClassDateKeys(sc);
      for (final c in sc.courses) {
        rebuildLecturesForCourse(c, sc);
      }
      applyNoClassDatesToSchedule(sc);
      _invalidateLectureCache();
    });
    _persistSchedule();
  }

  void updateEndDate(DateTime date) {
    final sc = schedule;
    if (sc == null) return;
    setState(() {
      sc.endDate = date;
      _pruneNoClassDateKeys(sc);
      for (final c in sc.courses) {
        rebuildLecturesForCourse(c, sc);
      }
      applyNoClassDatesToSchedule(sc);
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
          onGuest: () {
            unawaited(_markPendingLocalMerge());
            setState(() => screen = AppScreen.onboarding);
          },
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
          scheduleRoot: _scheduleRoot!,
          onSwitchActiveSemester: switchActiveSemester,
          onAddSemester: addSemester,
          onRenameSemester: renameSemester,
          onDeleteSemester: deleteSemester,
          onExportSchedule: () {
            unawaited(_exportScheduleData());
          },
          onImportSchedule: (ctx) {
            unawaited(_importScheduleData(ctx));
          },
          onMeetingNotifPrefsChanged: _refreshMeetingNotifications,
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
          onLectureDetail: openLectureDetail,
          onMarkNoClassDay: markNoClassDay,
          onClearNoClassDay: clearNoClassDay,
          onChangeLanguage: updateLanguage,
          onChangeWeekStart: updateWeekStartsOn,
          onChangeVisibleDays: updateVisibleDays,
          onToggleMeetingNumbers: updateMeetingNumbers,
          onUse24HourTimeChanged: updateUse24HourTime,
          onChangeStartDate: updateStartDate,
          onChangeEndDate: updateEndDate,
          onAddVacationRange: addVacationRange,
          onClearAllNoClassDays: clearAllNoClassDays,
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
  final Future<void> Function(BuildContext context) onGoogleSignedIn;

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _busy = false;
  late final AnimationController _gradientCtrl;

  @override
  void initState() {
    super.initState();
    _gradientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    super.dispose();
  }

  Future<void> _onGooglePressed(BuildContext context) async {
    if (!authSupportedOnThisPlatform) {
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
      // On Linux, cred is always null (REST auth), but if LinuxAuthSession
      // signed in successfully we should proceed. On other platforms null
      // means the user cancelled the picker.
      final isLinux = !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
      if (cred == null && !(isLinux && isLinuxAuthSignedIn)) return;
      await widget.onGoogleSignedIn(context);
    } on Object catch (e) {
      if (context.mounted) {
        final msg = isGoogleSignInAndroidDeveloperError(e)
            ? l10n.signInAndroidConfigHint
            : l10n.signInFailed('$e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 12),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final googleAvailable = FeatureFlags.enableGoogleSignIn &&
        googleSignInSupportedOnPlatform &&
        authSupportedOnThisPlatform;
    final hPad = Adaptive.horizontalPadding(context) + 12;
    final isCompact = Adaptive.isCompactPhone(context);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientCtrl,
        builder: (context, child) {
          final t = CurvedAnimation(
            parent: _gradientCtrl,
            curve: Curves.easeInOut,
          ).value;
          final washA = Color.lerp(cs.primary, cs.tertiary, t)!;
          final washB = Color.lerp(cs.secondary, cs.primaryContainer, 1 - t)!;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  washA.withValues(alpha: 0.18 + 0.12 * t),
                  cs.surface,
                  washB.withValues(alpha: 0.1 + 0.1 * (1 - t)),
                  cs.surfaceContainerLow,
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const maxCard = 440.0;
              final cardWidth = (constraints.maxWidth - hPad * 2).clamp(
                0.0,
                maxCard,
              );
              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardWidth),
                    child: Material(
                      elevation: isCompact ? 2 : 3,
                      shadowColor: cs.shadow.withValues(alpha: 0.15),
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(28),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isCompact ? 22 : 28,
                          32,
                          isCompact ? 22 : 28,
                          28,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: isCompact ? 72 : 88,
                              child: SvgPicture.asset(
                                'assets/branding/leccheck_logo.svg',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              l10n.welcomeTitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.welcomeSubtitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                            SizedBox(height: isCompact ? 28 : 32),
                            if (FeatureFlags.enableGoogleSignIn) ...[
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _busy || !googleAvailable
                                      ? null
                                      : () => _onGooglePressed(context),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  icon: _busy
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: cs.onPrimary,
                                          ),
                                        )
                                      : Icon(
                                          Icons.account_circle_outlined,
                                          color: cs.onPrimary,
                                        ),
                                  label: Text(
                                    googleAvailable
                                        ? l10n.continueWithGoogle
                                        : l10n.continueWithGoogleUnavailable,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ] else
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.cloudComingSoonMessage,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(l10n.continueCloudComingSoon),
                                ),
                              ),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _busy ? null : widget.onGuest,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: Text(l10n.continueLocal),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
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
