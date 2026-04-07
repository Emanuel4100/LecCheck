import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/config/feature_flags.dart';
import 'core/platform/adaptive.dart';
import 'core/ui/app_icons.dart';
import 'core/ui/motion_tokens.dart';
import 'features/course_setup/course_setup_screen.dart';
import 'models/schedule_models.dart';

void main() => runApp(const LecCheckApp());

class LecCheckApp extends StatefulWidget {
  const LecCheckApp({super.key});

  @override
  State<LecCheckApp> createState() => _LecCheckAppState();
}

class _LecCheckAppState extends State<LecCheckApp> {
  Locale _locale = const Locale('en');

  void _setLanguage(String languageCode) {
    setState(() {
      _locale = Locale(languageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LecCheck',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('he')],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2A7BCC)),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: LecCheckRoot(onLanguageChanged: _setLanguage),
    );
  }
}

enum AppScreen { login, onboarding, addCourse, dashboard }

enum DashboardTab { weekly, lectures, stats, settings }

class LecCheckRoot extends StatefulWidget {
  const LecCheckRoot({super.key, required this.onLanguageChanged});
  final ValueChanged<String> onLanguageChanged;

  @override
  State<LecCheckRoot> createState() => _LecCheckRootState();
}

class _LecCheckRootState extends State<LecCheckRoot> {
  AppScreen screen = AppScreen.login;
  SemesterSchedule? schedule;
  DashboardTab tab = DashboardTab.weekly;
  int selectedDay = DateTime.now().weekday;
  bool gridMode = false;

  List<Lecture> get allLectures =>
      schedule?.courses.expand((course) => course.lectures).toList() ?? [];

  List<Lecture> get dayLectures {
    final sc = schedule;
    if (sc == null) return [];
    final activeDays = orderedWeekdaysForSchedule(sc);
    final effectiveSelectedDay = activeDays.contains(selectedDay)
        ? selectedDay
        : activeDays.first;
    final now = DateTime.now();
    final delta = (now.weekday - sc.weekStartsOn + 7) % 7;
    final weekStart = now.subtract(Duration(days: delta));
    final selected = weekStart.add(
      Duration(days: activeDays.indexOf(effectiveSelectedDay)),
    );
    return allLectures
        .where(
          (l) =>
              l.date.year == selected.year &&
              l.date.month == selected.month &&
              l.date.day == selected.day,
        )
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  double get attendancePercent {
    final past = allLectures
        .where((l) => l.date.isBefore(DateTime.now()))
        .toList();
    final attended = past
        .where((l) => l.status == LectureStatus.attended)
        .length;
    final missed = past.where((l) => l.status == LectureStatus.missed).length;
    final total = attended + missed;
    if (total == 0) return 0;
    return attended / total;
  }

  void createSchedule(
    String lang,
    DateTime start,
    DateTime end,
    int weekStartsOn,
    bool includeWeekend,
  ) {
    setState(() {
      schedule = SemesterSchedule(
        startDate: start,
        endDate: end,
        language: lang,
        weekStartsOn: weekStartsOn,
        showWeekend: includeWeekend,
      );
      selectedDay = weekStartsOn;
      screen = AppScreen.addCourse;
    });
    widget.onLanguageChanged(lang);
  }

  Course? addCourse(
    String name,
    String lecturer,
    String code,
    String link,
    Color color,
  ) {
    final sc = schedule;
    if (sc == null) return null;
    final course = Course(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      lecturer: lecturer,
      code: code,
      link: link,
      color: color,
    );
    sc.courses.add(course);
    setState(() {});
    return course;
  }

  void addMeeting(Course course, Meeting meeting) {
    final sc = schedule;
    if (sc == null) return;
    course.meetings.add(meeting);
    DateTime date = sc.startDate;
    while (!date.isAfter(sc.endDate)) {
      if (date.weekday == meeting.weekday) {
        course.lectures.add(
          Lecture(
            courseId: course.id,
            courseName: course.name,
            date: date,
            start: meeting.start,
            end: meeting.end,
            room: meeting.room,
            type: meeting.type,
            color: course.color,
          ),
        );
      }
      date = date.add(const Duration(days: 1));
    }
    setState(() {});
  }

  void updateLanguage(String language) {
    final sc = schedule;
    if (sc == null) return;
    setState(() => sc.language = language);
    widget.onLanguageChanged(language);
  }

  void updateShowWeekend(bool value) {
    final sc = schedule;
    if (sc == null) return;
    setState(() => sc.showWeekend = value);
  }

  void updateMeetingNumbers(bool value) {
    final sc = schedule;
    if (sc == null) return;
    setState(() => sc.enableMeetingNumbers = value);
  }

  void updateStartDate(DateTime date) {
    final sc = schedule;
    if (sc == null) return;
    setState(() => sc.startDate = date);
  }

  void updateEndDate(DateTime date) {
    final sc = schedule;
    if (sc == null) return;
    setState(() => sc.endDate = date);
  }

  @override
  Widget build(BuildContext context) {
    switch (screen) {
      case AppScreen.login:
        return _Login(
          onGuest: () => setState(() => screen = AppScreen.onboarding),
        );
      case AppScreen.onboarding:
        return _Onboarding(onStart: createSchedule);
      case AppScreen.addCourse:
        return CourseSetupScreen(
          schedule: schedule!,
          onAddCourse: addCourse,
          onAddMeeting: addMeeting,
          onContinue: () => setState(() => screen = AppScreen.dashboard),
          onBack: () => setState(() => screen = AppScreen.onboarding),
        );
      case AppScreen.dashboard:
        return _Dashboard(
          schedule: schedule!,
          tab: tab,
          selectedDay: selectedDay,
          gridMode: gridMode,
          lectures: dayLectures,
          allLectures: allLectures,
          attendance: attendancePercent,
          onChangeTab: (v) => setState(() => tab = v),
          onChangeDay: (v) => setState(() => selectedDay = v),
          onToggleMode: (v) => setState(() => gridMode = v),
          onStatus: (l, s) => setState(() => l.status = s),
          onAddCourse: addCourse,
          onAddMeeting: addMeeting,
          onChangeLanguage: updateLanguage,
          onToggleWeekend: updateShowWeekend,
          onToggleMeetingNumbers: updateMeetingNumbers,
          onChangeStartDate: updateStartDate,
          onChangeEndDate: updateEndDate,
          onReset: () => setState(() {
            schedule = null;
            screen = AppScreen.onboarding;
          }),
          onLogout: () => setState(() {
            schedule = null;
            screen = AppScreen.login;
          }),
        );
    }
  }
}

class _Login extends StatelessWidget {
  const _Login({required this.onGuest});
  final VoidCallback onGuest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                      onPressed: onGuest,
                      child: Text(l10n.continueLocal),
                    ),
                    if (FeatureFlags.enableGoogleSignIn)
                      OutlinedButton(
                        onPressed: () {},
                        child: Text(l10n.continueCloudComingSoon),
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
  const _Onboarding({required this.onStart});
  final void Function(
    String lang,
    DateTime start,
    DateTime end,
    int weekStartsOn,
    bool includeWeekend,
  )
  onStart;

  @override
  State<_Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<_Onboarding> {
  String lang = 'en';
  DateTime start = DateTime.now();
  DateTime end = DateTime.now().add(const Duration(days: 120));
  int weekStartsOn = 1;
  bool includeWeekend = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Adaptive.maxBodyWidth(context)),
          child: Card(
            child: SizedBox(
              width: 560,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.semesterSetupTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'he', label: Text('עברית')),
                        ButtonSegment(value: 'en', label: Text('English')),
                      ],
                      selected: {lang},
                      onSelectionChanged: (s) => setState(() => lang = s.first),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text(l10n.startDate),
                      subtitle: Text('${start.toLocal()}'.split(' ')[0]),
                      trailing: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: start,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) setState(() => start = picked);
                        },
                        child: Text(l10n.pickDate),
                      ),
                    ),
                    ListTile(
                      title: Text(l10n.endDate),
                      subtitle: Text('${end.toLocal()}'.split(' ')[0]),
                      trailing: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: end,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) setState(() => end = picked);
                        },
                        child: Text(l10n.pickDate),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: weekStartsOn,
                      decoration: InputDecoration(labelText: l10n.weekStartsOn),
                      items: const [
                        DropdownMenuItem(value: 7, child: Text('Sunday')),
                        DropdownMenuItem(value: 1, child: Text('Monday')),
                      ],
                      onChanged: (v) => setState(() => weekStartsOn = v ?? 1),
                    ),
                    SwitchListTile(
                      value: includeWeekend,
                      onChanged: (v) => setState(() => includeWeekend = v),
                      title: Text(l10n.includeWeekend),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => widget.onStart(
                        lang,
                        start,
                        end,
                        weekStartsOn,
                        includeWeekend,
                      ),
                      child: Text(l10n.continueCta),
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

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.schedule,
    required this.tab,
    required this.selectedDay,
    required this.gridMode,
    required this.lectures,
    required this.allLectures,
    required this.attendance,
    required this.onChangeTab,
    required this.onChangeDay,
    required this.onToggleMode,
    required this.onStatus,
    required this.onAddCourse,
    required this.onAddMeeting,
    required this.onChangeLanguage,
    required this.onToggleWeekend,
    required this.onToggleMeetingNumbers,
    required this.onChangeStartDate,
    required this.onChangeEndDate,
    required this.onReset,
    required this.onLogout,
  });
  final SemesterSchedule schedule;
  final DashboardTab tab;
  final int selectedDay;
  final bool gridMode;
  final List<Lecture> lectures;
  final List<Lecture> allLectures;
  final double attendance;
  final ValueChanged<DashboardTab> onChangeTab;
  final ValueChanged<int> onChangeDay;
  final ValueChanged<bool> onToggleMode;
  final void Function(Lecture, LectureStatus) onStatus;
  final Course? Function(String, String, String, String, Color) onAddCourse;
  final void Function(Course, Meeting) onAddMeeting;
  final ValueChanged<String> onChangeLanguage;
  final ValueChanged<bool> onToggleWeekend;
  final ValueChanged<bool> onToggleMeetingNumbers;
  final ValueChanged<DateTime> onChangeStartDate;
  final ValueChanged<DateTime> onChangeEndDate;
  final VoidCallback onReset;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lecture Tracker')),
      floatingActionButton: tab == DashboardTab.settings
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddMenu(context),
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (i) => onChangeTab(DashboardTab.values[i]),
        destinations: const [
          NavigationDestination(icon: Icon(AppIcons.weekly), label: 'Weekly'),
          NavigationDestination(
            icon: Icon(AppIcons.lectures),
            label: 'Lectures',
          ),
          NavigationDestination(icon: Icon(AppIcons.stats), label: 'Stats'),
          NavigationDestination(
            icon: Icon(AppIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: AnimatedSwitcher(
          duration: MotionTokens.normal,
          switchInCurve: MotionTokens.standardCurve,
          child: switch (tab) {
            DashboardTab.weekly => _weeklyBody(),
            DashboardTab.lectures => _lecturesBody(allLectures),
            DashboardTab.stats => _statsBody(),
            DashboardTab.settings => _settingsBody(context),
          },
        ),
      ),
    );
  }

  Future<void> _showAddMenu(BuildContext context) async {
    final pick = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Add Course'),
              leading: const Icon(AppIcons.addCourse),
              onTap: () => Navigator.pop(context, 'course'),
            ),
            ListTile(
              title: const Text('Add Meeting'),
              leading: const Icon(AppIcons.addMeeting),
              onTap: () => Navigator.pop(context, 'meeting'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;

    if (pick == 'course') {
      _showAddCourseDialog(context);
    } else if (pick == 'meeting') {
      if (schedule.courses.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Add a course first.')));
      } else {
        _showAddMeetingDialog(context);
      }
    }
  }

  Future<void> _showAddCourseDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final lecturerCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    bool hasLecturer = false;
    bool hasLink = false;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Add Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Course name'),
                ),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Course code'),
                ),
                CheckboxListTile(
                  value: hasLecturer,
                  onChanged: (v) => setLocal(() => hasLecturer = v ?? false),
                  title: const Text('Add lecturer'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (hasLecturer)
                  TextField(
                    controller: lecturerCtrl,
                    decoration: const InputDecoration(labelText: 'Lecturer'),
                  ),
                CheckboxListTile(
                  value: hasLink,
                  onChanged: (v) => setLocal(() => hasLink = v ?? false),
                  title: const Text('Add course link'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (hasLink)
                  TextField(
                    controller: linkCtrl,
                    decoration: const InputDecoration(labelText: 'Link'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final color =
                    Colors.primaries[Random().nextInt(Colors.primaries.length)];
                onAddCourse(
                  nameCtrl.text.trim(),
                  hasLecturer ? lecturerCtrl.text.trim() : '',
                  codeCtrl.text.trim(),
                  hasLink ? linkCtrl.text.trim() : '',
                  color,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddMeetingDialog(BuildContext context) async {
    final roomCtrl = TextEditingController(text: 'A1');
    final startTimes = _timeOptions();
    String start = startTimes[4];
    String end = startTimes[6];
    String type = 'Lecture';
    String selectedCourseId = schedule.courses.first.id;
    final activeDays = orderedWeekdaysForSchedule(schedule);
    int weekday = activeDays.first;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Add Meeting'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedCourseId,
                decoration: const InputDecoration(labelText: 'Course'),
                items: schedule.courses
                    .map(
                      (course) => DropdownMenuItem(
                        value: course.id,
                        child: Text(course.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setLocal(() => selectedCourseId = v ?? ''),
              ),
              DropdownButtonFormField<int>(
                initialValue: weekday,
                items: activeDays
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(weekdayLabel(d)),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setLocal(() => weekday = v ?? activeDays.first),
                decoration: const InputDecoration(labelText: 'Weekday'),
              ),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'Lecture', child: Text('Lecture')),
                  DropdownMenuItem(value: 'Practice', child: Text('Practice')),
                  DropdownMenuItem(value: 'Lab', child: Text('Lab')),
                ],
                onChanged: (v) => setLocal(() => type = v ?? 'Lecture'),
              ),
              DropdownButtonFormField<String>(
                initialValue: start,
                decoration: const InputDecoration(labelText: 'Start time'),
                items: startTimes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setLocal(() {
                  start = v ?? start;
                  final suggestedEnd = _suggestEnd(start);
                  if (_toMinutes(suggestedEnd) > _toMinutes(start)) {
                    end = suggestedEnd;
                  }
                }),
              ),
              DropdownButtonFormField<String>(
                initialValue: end,
                decoration: const InputDecoration(labelText: 'End time'),
                items: startTimes
                    .where((t) => _toMinutes(t) > _toMinutes(start))
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setLocal(() => end = v ?? end),
              ),
              TextField(
                controller: roomCtrl,
                decoration: const InputDecoration(labelText: 'Room'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (_toMinutes(end) <= _toMinutes(start)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('End time must be after start time.'),
                    ),
                  );
                  return;
                }
                final course = schedule.courses.firstWhere(
                  (c) => c.id == selectedCourseId,
                  orElse: () => schedule.courses.first,
                );
                onAddMeeting(
                  course,
                  Meeting(
                    weekday: weekday,
                    start: start,
                    end: end,
                    room: roomCtrl.text.trim(),
                    type: type,
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weeklyBody() {
    final activeDays = orderedWeekdaysForSchedule(schedule);
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: activeDays.map((d) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(weekdayLabel(d)),
                  selected: d == selectedDay,
                  onSelected: (_) => onChangeDay(d),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('List')),
                ButtonSegment(value: true, label: Text('Grid')),
              ],
              selected: {gridMode},
              onSelectionChanged: (v) => onToggleMode(v.first),
            ),
            const Spacer(),
            Text('Attendance ${(attendance * 100).toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: attendance),
        const SizedBox(height: 12),
        Expanded(
          child: gridMode
              ? const Center(child: Text('Weekly grid view'))
              : ListView.builder(
                  itemCount: lectures.length,
                  itemBuilder: (_, i) => _lectureCard(lectures[i]),
                ),
        ),
      ],
    );
  }

  Widget _lecturesBody(List<Lecture> data) {
    final sorted = [...data]..sort((a, b) => b.date.compareTo(a.date));
    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (_, i) => _lectureCard(sorted[i]),
    );
  }

  Widget _statsBody() {
    final attended = allLectures
        .where((l) => l.status == LectureStatus.attended)
        .length;
    final missed = allLectures
        .where((l) => l.status == LectureStatus.missed)
        .length;
    final pending = allLectures
        .where((l) => l.status == LectureStatus.pending)
        .length;
    return ListView(
      children: [
        Card(
          child: ListTile(
            title: const Text('Attendance'),
            subtitle: Text('${(attendance * 100).toStringAsFixed(0)}%'),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Attended'),
            trailing: Text('$attended'),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Missed'),
            trailing: Text('$missed'),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Pending'),
            trailing: Text('$pending'),
          ),
        ),
      ],
    );
  }

  Widget _settingsBody(BuildContext context) {
    return ListView(
      children: [
        Card(
          child: ListTile(
            title: const Text('Language'),
            subtitle: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'he', label: Text('עברית')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {schedule.language},
              onSelectionChanged: (v) => onChangeLanguage(v.first),
            ),
          ),
        ),
        Card(
          child: SwitchListTile(
            value: schedule.showWeekend,
            onChanged: onToggleWeekend,
            title: const Text('Show weekend'),
          ),
        ),
        Card(
          child: SwitchListTile(
            value: schedule.enableMeetingNumbers,
            onChanged: onToggleMeetingNumbers,
            title: const Text('Auto meeting numbers'),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Semester start'),
            subtitle: Text('${schedule.startDate.toLocal()}'.split(' ')[0]),
            trailing: OutlinedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: schedule.startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) onChangeStartDate(picked);
              },
              child: const Text('Change'),
            ),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Semester end'),
            subtitle: Text('${schedule.endDate.toLocal()}'.split(' ')[0]),
            trailing: OutlinedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: schedule.endDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) onChangeEndDate(picked);
              },
              child: const Text('Change'),
            ),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Reset Semester'),
            trailing: OutlinedButton(
              onPressed: onReset,
              child: const Text('Reset'),
            ),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Logout'),
            trailing: OutlinedButton(
              onPressed: onLogout,
              child: const Text('Logout'),
            ),
          ),
        ),
      ],
    );
  }

  static List<String> _timeOptions() {
    final options = <String>[];
    for (var h = 8; h <= 23; h++) {
      options.add('${h.toString().padLeft(2, '0')}:00');
      if (h < 23) {
        options.add('${h.toString().padLeft(2, '0')}:30');
      }
    }
    return options;
  }

  static int _toMinutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String _suggestEnd(String start) {
    final mins = _toMinutes(start) + 60;
    final hour = (mins ~/ 60).clamp(0, 23);
    final minute = mins % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Widget _lectureCard(Lecture lecture) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 8,
          height: 42,
          decoration: BoxDecoration(
            color: lecture.color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        title: Text('${lecture.courseName} • ${lecture.type}'),
        subtitle: Text(
          '${lecture.start}-${lecture.end} • ${lecture.room} • ${lecture.status.name}',
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              onPressed: () => onStatus(lecture, LectureStatus.attended),
              icon: const Icon(Icons.check, color: Colors.green),
            ),
            IconButton(
              onPressed: () => onStatus(lecture, LectureStatus.missed),
              icon: const Icon(Icons.close, color: Colors.red),
            ),
            IconButton(
              onPressed: () => onStatus(lecture, LectureStatus.canceled),
              icon: const Icon(Icons.block),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCourseBootstrap extends StatefulWidget {
  const _AddCourseBootstrap({
    required this.schedule,
    required this.onAddCourse,
    required this.onAddMeeting,
    required this.onContinue,
    required this.onBack,
  });

  final SemesterSchedule schedule;
  final Course? Function(String, String, String, String, Color) onAddCourse;
  final void Function(Course, Meeting) onAddMeeting;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  State<_AddCourseBootstrap> createState() => _AddCourseBootstrapState();
}

class _AddCourseBootstrapState extends State<_AddCourseBootstrap> {
  Future<void> _openAddDialog() async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final lecturerCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    bool hasLecturer = false;
    bool hasLink = false;
    final meetings = <Meeting>[];
    const meetingTypes = ['Lecture', 'Practice', 'Lab', 'Other'];
    String sessionType = meetingTypes.first;
    int weekday = 1;
    final startTimes = _timeOptions();
    String start = startTimes[4];
    int durationMinutes = 60;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Add Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Course name'),
                ),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Course code'),
                ),
                CheckboxListTile(
                  value: hasLecturer,
                  onChanged: (v) => setLocal(() => hasLecturer = v ?? false),
                  title: const Text('Add lecturer'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (hasLecturer)
                  TextField(
                    controller: lecturerCtrl,
                    decoration: const InputDecoration(labelText: 'Lecturer'),
                  ),
                CheckboxListTile(
                  value: hasLink,
                  onChanged: (v) => setLocal(() => hasLink = v ?? false),
                  title: const Text('Add course link'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (hasLink)
                  TextField(
                    controller: linkCtrl,
                    decoration: const InputDecoration(labelText: 'Link'),
                  ),
                const Divider(height: 24),
                Text(
                  'Add weekly sessions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                DropdownButtonFormField<String>(
                  initialValue: sessionType,
                  decoration: const InputDecoration(labelText: 'Session type'),
                  items: meetingTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) =>
                      setLocal(() => sessionType = v ?? meetingTypes.first),
                ),
                DropdownButtonFormField<int>(
                  initialValue: weekday,
                  decoration: const InputDecoration(labelText: 'Weekday'),
                  items: List.generate(
                    7,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(
                        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
                      ),
                    ),
                  ),
                  onChanged: (v) => setLocal(() => weekday = v ?? 1),
                ),
                DropdownButtonFormField<String>(
                  initialValue: start,
                  decoration: const InputDecoration(labelText: 'Start time'),
                  items: startTimes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setLocal(() => start = v ?? start),
                ),
                DropdownButtonFormField<int>(
                  initialValue: durationMinutes,
                  decoration: const InputDecoration(labelText: 'Length'),
                  items: const [
                    DropdownMenuItem(value: 30, child: Text('30 min')),
                    DropdownMenuItem(value: 60, child: Text('60 min')),
                    DropdownMenuItem(value: 90, child: Text('90 min')),
                    DropdownMenuItem(value: 120, child: Text('120 min')),
                    DropdownMenuItem(value: 150, child: Text('150 min')),
                    DropdownMenuItem(value: 180, child: Text('180 min')),
                  ],
                  onChanged: (v) => setLocal(() => durationMinutes = v ?? 60),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      meetings.add(
                        Meeting(
                          weekday: weekday,
                          start: start,
                          end: _endFromStartAndDuration(start, durationMinutes),
                          room: '',
                          type: sessionType,
                        ),
                      );
                      setLocal(() {});
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add session'),
                  ),
                ),
                if (meetings.isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('No sessions added yet.'),
                  ),
                ...meetings.asMap().entries.map((entry) {
                  final index = entry.key;
                  final meeting = entry.value;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${meeting.type} - ${_weekdayLabel(meeting.weekday)}',
                    ),
                    subtitle: Text(
                      '${meeting.start} - ${meeting.end} (${_durationText(meeting.start, meeting.end)})',
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        meetings.removeAt(index);
                        setLocal(() {});
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || meetings.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Add course name and at least one session.',
                      ),
                    ),
                  );
                  return;
                }
                final color =
                    Colors.primaries[Random().nextInt(Colors.primaries.length)];
                final course = widget.onAddCourse(
                  nameCtrl.text.trim(),
                  hasLecturer ? lecturerCtrl.text.trim() : '',
                  codeCtrl.text.trim(),
                  hasLink ? linkCtrl.text.trim() : '',
                  color,
                );
                if (course != null) {
                  for (final meeting in meetings) {
                    widget.onAddMeeting(course, meeting);
                  }
                }
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courses = widget.schedule.courses;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Setup Courses'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add your courses for this semester',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: courses.isEmpty
                  ? const Center(
                      child: Text('No courses yet. Add your first course.'),
                    )
                  : ListView.builder(
                      itemCount: courses.length,
                      itemBuilder: (_, i) {
                        final c = courses[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: c.color),
                            title: Text(c.name),
                            subtitle: Text(
                              [
                                if (c.code.isNotEmpty) 'Code: ${c.code}',
                                if (c.lecturer.isNotEmpty)
                                  'Lecturer: ${c.lecturer}',
                              ].join(' • '),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _openAddDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add course'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: widget.onContinue,
                  child: const Text('Continue'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static List<String> _timeOptions() {
    final options = <String>[];
    for (var h = 8; h <= 23; h++) {
      options.add('${h.toString().padLeft(2, '0')}:00');
      if (h < 23) {
        options.add('${h.toString().padLeft(2, '0')}:30');
      }
    }
    return options;
  }

  static int _toMinutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String _endFromStartAndDuration(String start, int durationMinutes) {
    final total = (_toMinutes(start) + durationMinutes).clamp(0, 23 * 60 + 59);
    final hour = total ~/ 60;
    final minute = total % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static String _durationText(String start, String end) {
    final diff = _toMinutes(end) - _toMinutes(start);
    if (diff <= 0) return '0m';
    final h = diff ~/ 60;
    final m = diff % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  static String _weekdayLabel(int day) {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];
  }
}
