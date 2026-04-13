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
    required this.scheduleRoot,
    required this.onSwitchActiveSemester,
    required this.onAddSemester,
    required this.onRenameSemester,
    required this.onDeleteSemester,
    required this.onExportSchedule,
    required this.onImportSchedule,
    required this.onMeetingNotifPrefsChanged,
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
    required this.onLectureDetail,
    required this.onMarkNoClassDay,
    required this.onClearNoClassDay,
    required this.onChangeLanguage,
    required this.onChangeWeekStart,
    required this.onChangeVisibleDays,
    required this.onToggleMeetingNumbers,
    required this.onUse24HourTimeChanged,
    required this.onChangeStartDate,
    required this.onChangeEndDate,
    required this.onAddVacationRange,
    required this.onClearAllNoClassDays,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onReset,
    required this.onLogout,
  });

  final SemesterSchedule schedule;
  final ScheduleRootState scheduleRoot;
  final ValueChanged<String> onSwitchActiveSemester;
  final void Function(String name, DateTime start, DateTime end) onAddSemester;
  final void Function(String semesterId, String newName) onRenameSemester;
  final Future<void> Function(String semesterId) onDeleteSemester;
  final void Function() onExportSchedule;
  final void Function(BuildContext context) onImportSchedule;
  final void Function() onMeetingNotifPrefsChanged;
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
  final Future<void> Function(BuildContext context, Lecture lecture)
      onLectureDetail;
  final ValueChanged<DateTime> onMarkNoClassDay;
  final ValueChanged<DateTime> onClearNoClassDay;
  final ValueChanged<String> onChangeLanguage;
  final ValueChanged<int> onChangeWeekStart;
  final ValueChanged<Set<int>> onChangeVisibleDays;
  final ValueChanged<bool> onToggleMeetingNumbers;
  final ValueChanged<bool> onUse24HourTimeChanged;
  final ValueChanged<DateTime> onChangeStartDate;
  final ValueChanged<DateTime> onChangeEndDate;
  final void Function(DateTime start, DateTime end) onAddVacationRange;
  final VoidCallback onClearAllNoClassDays;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onReset;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = Adaptive.isDesktop(context);
    final showAppBar = !Adaptive.isLinuxDesktop &&
        (isDesktop || Adaptive.isWebLike(context));
    return Scaffold(
      appBar: showAppBar
          ? AppBar(title: Text(l10n.appTitle))
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: (!isDesktop &&
              (tab == DashboardTab.weekly || tab == DashboardTab.lectures))
          ? FloatingActionButton.small(
              onPressed: () => _showAddMenu(context, l10n),
              child: const Icon(AppIcons.add),
            )
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
              child: Column(
                children: [
                  if (isDesktop) _buildDesktopToolbar(context, l10n),
                  Expanded(
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
                        onMarkNoClassDay: onMarkNoClassDay,
                        onClearNoClassDay: onClearNoClassDay,
                        l10n: l10n,
                      ),
                      DashboardTab.lectures => LecturesTab(
                        schedule: schedule,
                        data: allLectures,
                        showMeetingNumber: schedule.enableMeetingNumbers,
                        l10n: l10n,
                        onStatus: onStatus,
                        onLectureDetail: onLectureDetail,
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
                        scheduleRoot: scheduleRoot,
                        onSwitchActiveSemester: onSwitchActiveSemester,
                        onAddSemester: onAddSemester,
                        onRenameSemester: onRenameSemester,
                        onDeleteSemester: onDeleteSemester,
                        onExportSchedule: onExportSchedule,
                        onImportSchedule: onImportSchedule,
                        onMeetingNotifPrefsChanged: onMeetingNotifPrefsChanged,
                        onChangeLanguage: onChangeLanguage,
                        onChangeWeekStart: onChangeWeekStart,
                        onChangeVisibleDays: onChangeVisibleDays,
                        onToggleMeetingNumbers: onToggleMeetingNumbers,
                        onUse24HourTimeChanged: onUse24HourTimeChanged,
                        onChangeStartDate: onChangeStartDate,
                        onChangeEndDate: onChangeEndDate,
                        onAddVacationRange: onAddVacationRange,
                        onClearAllNoClassDays: onClearAllNoClassDays,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopToolbar(BuildContext context, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant, width: 0.5)),
      ),
      child: Row(
        children: [
          _ToolbarButton(
            icon: AppIcons.addCourse,
            label: l10n.addCourse,
            onPressed: () => onOpenCourseEditor(context),
          ),
          const SizedBox(width: 4),
          _ToolbarButton(
            icon: AppIcons.addMeeting,
            label: l10n.addMeeting,
            onPressed: () {
              if (schedule.courses.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.addCourseFirst)),
                );
              } else {
                _showAddMeetingDialog(context, l10n);
              }
            },
          ),
          const SizedBox(width: 4),
          _ToolbarButton(
            icon: Icons.edit_note,
            label: l10n.fabManageCourses,
            onPressed: () => onOpenManageCourses(context),
          ),
          if (tab == DashboardTab.weekly) ...[
            const SizedBox(width: 4),
            _ToolbarButton(
              icon: Icons.today,
              label: l10n.goToCurrentWeek,
              onPressed: onJumpToCurrentWeek,
            ),
          ],
          if (tab == DashboardTab.lectures) ...[
            const SizedBox(width: 4),
            _ToolbarButton(
              icon: Icons.search,
              label: l10n.focusSearchField,
              onPressed: onRequestLecturesSearchFocus,
            ),
          ],
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
    if (activeDays.isEmpty) return;
    int weekday = activeDays.first;
    bool isOneOff = false;
    DateTime? specificDate;
    final wideMeeting =
        Adaptive.isDesktop(context) || Adaptive.isWebLike(context);

    void submitMeeting(BuildContext ctx) {
      if (_toMinutes(end) <= _toMinutes(start)) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(l10n.endAfterStartError)),
        );
        return;
      }
      if (isOneOff && specificDate == null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(l10n.selectDate)),
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
          weekday: isOneOff ? (specificDate?.weekday ?? weekday) : weekday,
          start: start,
          end: end,
          room: roomCtrl.text.trim(),
          type: type,
          specificDate: isOneOff ? specificDate : null,
        ),
      );
      Navigator.pop(ctx);
    }

    Widget formFields(void Function(void Function()) setLocal) {
      return Column(
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
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text(l10n.weeklyRecurring),
              ),
              ButtonSegment(
                value: true,
                label: Text(l10n.oneTimeMeeting),
              ),
            ],
            selected: {isOneOff},
            onSelectionChanged: (v) {
              if (v.isEmpty) return;
              setLocal(() {
                isOneOff = v.first;
                if (isOneOff && specificDate == null) {
                  final now = DateTime.now();
                  specificDate = now.isBefore(schedule.startDate)
                      ? schedule.startDate
                      : now.isAfter(schedule.endDate)
                          ? schedule.endDate
                          : now;
                }
              });
            },
          ),
          const SizedBox(height: 8),
          if (!isOneOff)
            DropdownButtonFormField<int>(
              key: const ValueKey('weekday_dropdown'),
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
            )
          else
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.selectDate),
              trailing: Text(
                specificDate != null
                    ? '${specificDate!.day}/${specificDate!.month}/${specificDate!.year}'
                    : '—',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: specificDate ?? DateTime.now(),
                  firstDate: schedule.startDate,
                  lastDate: schedule.endDate,
                );
                if (picked != null) {
                  setLocal(() => specificDate = picked);
                }
              },
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
              DropdownMenuItem(
                value: l10n.labType,
                child: Text(l10n.labType),
              ),
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
            textInputAction: TextInputAction.done,
          ),
        ],
      );
    }

    try {
      if (!wideMeeting) {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (sheetCtx) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom,
              ),
              child: StatefulBuilder(
                builder: (context, setLocal) {
                  final theme = Theme.of(context);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.addMeeting,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        formFields(setLocal),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(l10n.cancel),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: () => submitMeeting(context),
                              child: Text(l10n.save),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      } else {
        await showDialog<void>(
          context: context,
          builder: (dialogCtx) => StatefulBuilder(
            builder: (context, setLocal) => AlertDialog(
              title: Text(l10n.addMeeting),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  child: formFields(setLocal),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => submitMeeting(context),
                  child: Text(l10n.save),
                ),
              ],
            ),
          ),
        );
      }
    } finally {
      roomCtrl.dispose();
    }
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

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
