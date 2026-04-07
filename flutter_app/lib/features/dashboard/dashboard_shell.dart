import 'package:flutter/material.dart';
import '../../core/platform/adaptive.dart';
import '../../core/ui/app_icons.dart';
import '../../core/ui/motion_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/schedule_models.dart';
import 'dashboard_types.dart';
import 'lectures_tab.dart';
import 'settings_tab.dart';
import 'stats_tab.dart';
import 'weekly_tab.dart';
import 'dashboard_utils.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({
    super.key,
    required this.schedule,
    required this.tab,
    required this.allLectures,
    required this.attendance,
    required this.weeklyWeekSyncToken,
    required this.onJumpToCurrentWeek,
    required this.lecturesSearchFocusToken,
    required this.onRequestLecturesSearchFocus,
    required this.onChangeTab,
    required this.onStatus,
    required this.onAddMeeting,
    required this.onOpenCourseEditor,
    required this.onOpenManageCourses,
    required this.onMeetingLinksSaved,
    required this.onChangeLanguage,
    required this.onChangeWeekStart,
    required this.onChangeVisibleDays,
    required this.onToggleMeetingNumbers,
    required this.onChangeStartDate,
    required this.onChangeEndDate,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onReset,
    required this.onLogout,
  });

  final SemesterSchedule schedule;
  final DashboardTab tab;
  final List<Lecture> allLectures;
  final double attendance;
  final int weeklyWeekSyncToken;
  final VoidCallback onJumpToCurrentWeek;
  final int lecturesSearchFocusToken;
  final VoidCallback onRequestLecturesSearchFocus;
  final ValueChanged<DashboardTab> onChangeTab;
  final void Function(Lecture, LectureStatus) onStatus;
  final void Function(Course, Meeting) onAddMeeting;
  final void Function(BuildContext context) onOpenCourseEditor;
  final void Function(BuildContext context) onOpenManageCourses;
  final void Function(Course course, Meeting meeting, List<NamedLink> links)
      onMeetingLinksSaved;
  final ValueChanged<String> onChangeLanguage;
  final ValueChanged<int> onChangeWeekStart;
  final ValueChanged<Set<int>> onChangeVisibleDays;
  final ValueChanged<bool> onToggleMeetingNumbers;
  final ValueChanged<DateTime> onChangeStartDate;
  final ValueChanged<DateTime> onChangeEndDate;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onReset;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = Adaptive.isDesktop(context);
    final showAppBar = isDesktop || Adaptive.isWebLike(context);
    final hasBottomNav = !isDesktop;
    return Scaffold(
      appBar: showAppBar
          ? AppBar(title: Text(l10n.appTitle))
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: (tab == DashboardTab.weekly ||
              tab == DashboardTab.lectures)
          ? (hasBottomNav
              ? FloatingActionButton.small(
                  onPressed: () => _showAddMenu(context, l10n),
                  child: const Icon(AppIcons.add),
                )
              : FloatingActionButton(
                  onPressed: () => _showAddMenu(context, l10n),
                  child: const Icon(AppIcons.add),
                ))
          : null,
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: tab.index,
              onDestinationSelected: (i) => onChangeTab(DashboardTab.values[i]),
              destinations: [
                NavigationDestination(
                  icon: const Icon(AppIcons.weekly),
                  label: l10n.weekly,
                ),
                NavigationDestination(
                  icon: const Icon(AppIcons.lectures),
                  label: l10n.lectures,
                ),
                NavigationDestination(
                  icon: const Icon(AppIcons.stats),
                  label: l10n.stats,
                ),
                NavigationDestination(
                  icon: const Icon(AppIcons.settings),
                  label: l10n.settings,
                ),
              ],
            ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: tab.index,
              onDestinationSelected: (i) => onChangeTab(DashboardTab.values[i]),
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(AppIcons.weekly),
                  label: Text(l10n.weekly),
                ),
                NavigationRailDestination(
                  icon: const Icon(AppIcons.lectures),
                  label: Text(l10n.lectures),
                ),
                NavigationRailDestination(
                  icon: const Icon(AppIcons.stats),
                  label: Text(l10n.stats),
                ),
                NavigationRailDestination(
                  icon: const Icon(AppIcons.settings),
                  label: Text(l10n.settings),
                ),
              ],
            ),
          Expanded(
            child: SafeArea(
              top: !showAppBar,
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: tab == DashboardTab.weekly
                        ? double.infinity
                        : Adaptive.maxBodyWidth(context),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(Adaptive.horizontalPadding(context)),
                    child: AnimatedSwitcher(
                    duration: MotionTokens.normal,
                    switchInCurve: MotionTokens.standardCurve,
                    child: switch (tab) {
                      DashboardTab.weekly => WeeklyTab(
                        schedule: schedule,
                        allLectures: allLectures,
                        attendance: attendance,
                        weekSyncToken: weeklyWeekSyncToken,
                        onStatus: onStatus,
                        onMeetingLinksSaved: onMeetingLinksSaved,
                        l10n: l10n,
                      ),
                      DashboardTab.lectures => LecturesTab(
                        schedule: schedule,
                        data: allLectures,
                        showMeetingNumber: schedule.enableMeetingNumbers,
                        l10n: l10n,
                        onStatus: onStatus,
                        focusSearchToken: lecturesSearchFocusToken,
                      ),
                      DashboardTab.stats => StatsTab(
                        schedule: schedule,
                        allLectures: allLectures,
                        attendance: attendance,
                        l10n: l10n,
                      ),
                      DashboardTab.settings => SettingsTab(
                        schedule: schedule,
                        onChangeLanguage: onChangeLanguage,
                        onChangeWeekStart: onChangeWeekStart,
                        onChangeVisibleDays: onChangeVisibleDays,
                        onToggleMeetingNumbers: onToggleMeetingNumbers,
                        onChangeStartDate: onChangeStartDate,
                        onChangeEndDate: onChangeEndDate,
                        themeMode: themeMode,
                        onThemeModeChanged: onThemeModeChanged,
                        onManageCourses: () => onOpenManageCourses(context),
                        onReset: onReset,
                        onLogout: onLogout,
                        l10n: l10n,
                      ),
                    },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddMenu(BuildContext context, AppLocalizations l10n) async {
    final useCenteredMenu =
        Adaptive.isDesktop(context) || Adaptive.isWebLike(context);

    List<Widget> menuBody(BuildContext ctx) => [
          ListTile(
            title: Text(l10n.addCourse),
            leading: const Icon(AppIcons.addCourse),
            onTap: () => Navigator.pop(ctx, 'course'),
          ),
          ListTile(
            title: Text(l10n.fabManageCourses),
            leading: const Icon(Icons.edit_note),
            onTap: () => Navigator.pop(ctx, 'manage'),
          ),
          ListTile(
            title: Text(l10n.addMeeting),
            leading: const Icon(AppIcons.addMeeting),
            onTap: () => Navigator.pop(ctx, 'meeting'),
          ),
          if (tab == DashboardTab.weekly)
            ListTile(
              title: Text(l10n.goToCurrentWeek),
              leading: const Icon(Icons.today),
              onTap: () => Navigator.pop(ctx, 'week'),
            ),
          if (tab == DashboardTab.lectures)
            ListTile(
              title: Text(l10n.focusSearchField),
              leading: const Icon(Icons.search),
              onTap: () => Navigator.pop(ctx, 'search'),
            ),
        ];

    final String? pick = useCenteredMenu
        ? await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.addActionsTitle),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: menuBody(ctx),
                  ),
                ),
              ),
            ),
          )
        : await showModalBottomSheet<String>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: menuBody(ctx),
              ),
            ),
          );
    if (!context.mounted) return;

    if (pick == 'week') {
      onJumpToCurrentWeek();
      return;
    }
    if (pick == 'search') {
      onRequestLecturesSearchFocus();
      return;
    }
    if (pick == 'course') {
      onOpenCourseEditor(context);
    } else if (pick == 'manage') {
      onOpenManageCourses(context);
    } else if (pick == 'meeting') {
      if (schedule.courses.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.addCourseFirst)));
      } else {
        _showAddMeetingDialog(context, l10n);
      }
    }
  }

  Future<void> _showAddMeetingDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final roomCtrl = TextEditingController(text: 'A1');
    final startTimes = _timeOptions();
    String start = startTimes[4];
    String end = startTimes[6];
    String type = l10n.lectureType;
    String selectedCourseId = schedule.courses.first.id;
    final activeDays = orderedWeekdaysForSchedule(schedule);
    int weekday = activeDays.first;
    final wideMeeting =
        Adaptive.isDesktop(context) || Adaptive.isWebLike(context);
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(l10n.addMeeting),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: wideMeeting ? 520 : 360),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              DropdownButtonFormField<String>(
                initialValue: selectedCourseId,
                decoration: InputDecoration(labelText: l10n.course),
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
                        child: Text(weekdayLabelL10n(d, l10n)),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setLocal(() => weekday = v ?? activeDays.first),
                decoration: InputDecoration(labelText: l10n.weekday),
              ),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: InputDecoration(labelText: l10n.type),
                items: [
                  DropdownMenuItem(
                    value: l10n.lectureType,
                    child: Text(l10n.lectureType),
                  ),
                  DropdownMenuItem(
                    value: l10n.practiceType,
                    child: Text(l10n.practiceType),
                  ),
                  DropdownMenuItem(value: l10n.labType, child: Text(l10n.labType)),
                ],
                onChanged: (v) => setLocal(() => type = v ?? l10n.lectureType),
              ),
              DropdownButtonFormField<String>(
                initialValue: start,
                decoration: InputDecoration(labelText: l10n.startTime),
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
                decoration: InputDecoration(labelText: l10n.endTime),
                items: startTimes
                    .where((t) => _toMinutes(t) > _toMinutes(start))
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setLocal(() => end = v ?? end),
              ),
              TextField(
                controller: roomCtrl,
                decoration: InputDecoration(labelText: l10n.room),
              ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (_toMinutes(end) <= _toMinutes(start)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.endAfterStartError)),
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
              child: Text(l10n.save),
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
      if (h < 23) options.add('${h.toString().padLeft(2, '0')}:30');
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
}
