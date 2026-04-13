import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/about_info.dart';
import '../../core/notifications/meeting_notifications.dart';
import '../../core/platform/adaptive.dart';
import '../../core/ui/app_icons.dart';
import '../../l10n/app_localizations.dart';
import '../../models/schedule_models.dart';
import 'dashboard_utils.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({
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
    required this.onChangeLanguage,
    required this.onChangeVisibleDays,
    required this.onToggleMeetingNumbers,
    required this.onUse24HourTimeChanged,
    required this.onChangeWeekStart,
    required this.onChangeStartDate,
    required this.onChangeEndDate,
    required this.onAddVacationRange,
    required this.onClearAllNoClassDays,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onManageCourses,
    required this.onReset,
    required this.onLogout,
    required this.l10n,
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
  final ValueChanged<String> onChangeLanguage;
  final ValueChanged<Set<int>> onChangeVisibleDays;
  final ValueChanged<bool> onToggleMeetingNumbers;
  final ValueChanged<bool> onUse24HourTimeChanged;
  final ValueChanged<int> onChangeWeekStart;
  final ValueChanged<DateTime> onChangeStartDate;
  final ValueChanged<DateTime> onChangeEndDate;
  final void Function(DateTime start, DateTime end) onAddVacationRange;
  final VoidCallback onClearAllNoClassDays;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onManageCourses;
  final VoidCallback onReset;
  final VoidCallback onLogout;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final orderedStartDays = orderedWeekdaysFromStart(schedule.weekStartsOn);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Adaptive.isDesktop(context) ? 720 : double.infinity,
        ),
        child: ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.semestersSectionTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.semestersSectionSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                ...scheduleRoot.slots.map((s) {
                  final active = s.id == scheduleRoot.activeSemesterId;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      active ? Icons.check_circle : Icons.calendar_month_outlined,
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(s.name),
                    subtitle: Text(
                      '${s.schedule.startDate.toString().split(' ').first} – ${s.schedule.endDate.toString().split(' ').first}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.renameSemesterTitle,
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _showRenameSemesterDialog(
                            context,
                            s.id,
                            s.name,
                          ),
                        ),
                        if (scheduleRoot.slots.length > 1)
                          IconButton(
                            tooltip: l10n.deleteSemesterTitle,
                            icon: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () => _confirmDeleteSemester(context, s.id),
                          ),
                      ],
                    ),
                    onTap: () {
                      if (!active) onSwitchActiveSemester(s.id);
                    },
                  );
                }),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _showAddSemesterDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addSemesterButton),
                  ),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.library_books_outlined),
            title: Text(l10n.manageCourses),
            subtitle: Text(l10n.manageCoursesSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: onManageCourses,
          ),
        ),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.schedule),
            title: Text(l10n.use24HourTimeTitle),
            subtitle: Text(l10n.use24HourTimeSubtitle),
            value: schedule.use24HourTime,
            onChanged: onUse24HourTimeChanged,
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.themeModeLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(l10n.themeModeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(l10n.themeModeDark),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(l10n.themeModeSystem),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (s) {
                    if (s.isNotEmpty) onThemeModeChanged(s.first);
                  },
                ),
              ],
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(AppIcons.language),
            title: Text(l10n.language),
            subtitle: DropdownButtonFormField<String>(
              initialValue: schedule.language,
              items: const [
                DropdownMenuItem(value: 'he', child: Text('עברית')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (v) {
                if (v != null) onChangeLanguage(v);
              },
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<int>(
              initialValue: schedule.weekStartsOn,
              decoration: InputDecoration(
                labelText: l10n.weekStartsOn,
                prefixIcon: const Icon(AppIcons.weekday),
              ),
              items: orderedStartDays
                  .map(
                    (day) => DropdownMenuItem<int>(
                      value: day,
                      child: Text(weekdayLabelL10n(day, l10n)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChangeWeekStart(v);
              },
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(AppIcons.weekday),
            title: Text(l10n.shownDays),
            subtitle: Text(
              orderedStartDays
                  .where((d) => schedule.visibleWeekdays.contains(d))
                  .map((d) => weekdayLabelL10n(d, l10n))
                  .join(', '),
            ),
            trailing: OutlinedButton(
              onPressed: () => _showVisibleDaysPopup(context, orderedStartDays),
              child: Text(l10n.change),
            ),
          ),
        ),
        Card(
          child: SwitchListTile(
            value: schedule.enableMeetingNumbers,
            onChanged: onToggleMeetingNumbers,
            secondary: const Icon(AppIcons.numbering),
            title: Text(l10n.autoMeetingNumbers),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(AppIcons.semester),
            title: Text(l10n.semesterStart),
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
              child: Text(l10n.change),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(AppIcons.semester),
            title: Text(l10n.semesterEnd),
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
              child: Text(l10n.change),
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.vacationsSectionTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.vacationsSectionSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.noClassDaysCount(schedule.noClassDateKeys.length),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => _pickVacationRange(context),
                      icon: const Icon(Icons.date_range_outlined),
                      label: Text(l10n.addVacationRange),
                    ),
                    OutlinedButton(
                      onPressed: schedule.noClassDateKeys.isEmpty
                          ? null
                          : () => _confirmClearAllNoClass(context),
                      child: Text(l10n.clearAllNoClassDays),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (meetingNotificationsSupportedOnPlatform)
          Card(
            child: _MeetingNotificationSettings(
              l10n: l10n,
              onPrefsChanged: onMeetingNotifPrefsChanged,
            ),
          )
        else
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_off_outlined),
              title: Text(l10n.meetingNotifTitle),
              subtitle: Text(l10n.meetingNotifUnavailablePlatform),
            ),
          ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: Text(l10n.exportDataTitle),
                subtitle: Text(l10n.exportDataSubtitle),
                onTap: () => onExportSchedule(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: Text(l10n.importDataTitle),
                subtitle: Text(l10n.importDataSubtitle),
                onTap: () => onImportSchedule(context),
              ),
            ],
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(AppIcons.reset),
            title: Text(l10n.resetSemester),
            trailing: OutlinedButton(onPressed: onReset, child: Text(l10n.reset)),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(AppIcons.logout),
            title: Text(l10n.logout),
            trailing: OutlinedButton(
              onPressed: onLogout,
              child: Text(l10n.logout),
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.aboutSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${l10n.developerLabel}: '),
                    Expanded(child: Text(AboutInfo.developerName)),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final ok = await launchUrl(
                      AboutInfo.githubUri,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.openLinkFailed)),
                      );
                    }
                  },
                  child: Text(
                    AboutInfo.githubUri.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return Text(l10n.versionLabel);
                    }
                    final p = snap.data!;
                    return Text(
                      '${l10n.versionLabel}: v${p.version} (${p.buildNumber})',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    ),
      ),
    );
  }

  Future<void> _showAddSemesterDialog(BuildContext context) async {
    final nameCtrl = TextEditingController(text: l10n.semesterDefaultName);
    var start = schedule.startDate;
    var end = schedule.endDate;
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(l10n.newSemesterTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.semesterNameLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text(l10n.semesterStart),
                    subtitle: Text(start.toString().split(' ').first),
                    onTap: () async {
                      final p = await showDatePicker(
                        context: ctx,
                        initialDate: start,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (p != null) setLocal(() => start = p);
                    },
                  ),
                  ListTile(
                    title: Text(l10n.semesterEnd),
                    subtitle: Text(end.toString().split(' ').first),
                    onTap: () async {
                      final p = await showDatePicker(
                        context: ctx,
                        initialDate: end,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (p != null) setLocal(() => end = p);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      );
      if (ok == true && context.mounted) {
        onAddSemester(nameCtrl.text.trim(), start, end);
      }
    } finally {
      nameCtrl.dispose();
    }
  }

  Future<void> _showRenameSemesterDialog(
    BuildContext context,
    String semesterId,
    String currentName,
  ) async {
    final ctrl = TextEditingController(text: currentName);
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.renameSemesterTitle),
          content: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              labelText: l10n.semesterNameLabel,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.save),
            ),
          ],
        ),
      );
      if (ok == true && context.mounted) {
        onRenameSemester(semesterId, ctrl.text.trim());
      }
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _confirmDeleteSemester(BuildContext context, String semesterId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSemesterTitle),
        content: Text(l10n.deleteSemesterBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteCourseAction),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await onDeleteSemester(semesterId);
    }
  }

  Future<void> _pickVacationRange(BuildContext context) async {
    final semStart = DateTime(
      schedule.startDate.year,
      schedule.startDate.month,
      schedule.startDate.day,
    );
    final semEnd = DateTime(
      schedule.endDate.year,
      schedule.endDate.month,
      schedule.endDate.day,
    );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: semStart,
      lastDate: semEnd,
      initialDateRange: DateTimeRange(start: semStart, end: semStart),
    );
    if (picked != null && context.mounted) {
      onAddVacationRange(picked.start, picked.end);
    }
  }

  Future<void> _confirmClearAllNoClass(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearAllNoClassDays),
        content: Text(l10n.clearAllNoClassDaysConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.clearAllNoClassDays),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      onClearAllNoClassDays();
    }
  }

  Future<void> _showVisibleDaysPopup(
    BuildContext context,
    List<int> orderedStartDays,
  ) async {
    var draft = {...schedule.visibleWeekdays};
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.shownDays),
        content: StatefulBuilder(
          builder: (context, setLocal) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: orderedStartDays.map((day) {
              final selected = draft.contains(day);
              return FilterChip(
                selected: selected,
                label: Text(weekdayLabelL10n(day, l10n)),
                onSelected: (_) {
                  setLocal(() {
                    if (selected) {
                      if (draft.length == 1) return;
                      draft.remove(day);
                    } else {
                      draft.add(day);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              onChangeVisibleDays(draft);
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

class _MeetingNotificationSettings extends StatefulWidget {
  const _MeetingNotificationSettings({
    required this.l10n,
    required this.onPrefsChanged,
  });

  final AppLocalizations l10n;
  final VoidCallback onPrefsChanged;

  @override
  State<_MeetingNotificationSettings> createState() =>
      _MeetingNotificationSettingsState();
}

class _MeetingNotificationSettingsState
    extends State<_MeetingNotificationSettings> {
  bool _loading = true;
  bool _enabled = false;
  double _delay = 5;
  bool _headsUp = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await getMeetingNotificationsEnabled();
    final d = await getMeetingNotificationDelayMinutes();
    final h = await getMeetingNotificationsHeadsUp();
    if (!mounted) return;
    setState(() {
      _enabled = e;
      _delay = d.toDouble();
      _headsUp = h;
      _loading = false;
    });
  }

  Future<void> _applyEnabled(bool v) async {
    if (v && defaultTargetPlatform == TargetPlatform.android) {
      final granted = await requestAndroidNotificationPermission();
      if (!mounted) return;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.l10n.notificationPermissionDenied),
          ),
        );
        return;
      }
    }
    await setMeetingNotificationsEnabled(v);
    if (!mounted) return;
    setState(() => _enabled = v);
    widget.onPrefsChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final l10n = widget.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            title: Text(l10n.meetingNotifTitle),
            subtitle: Text(l10n.meetingNotifSubtitle),
            value: _enabled,
            onChanged: (v) => unawaited(_applyEnabled(v)),
          ),
          Text(
            l10n.meetingNotifDelayLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Slider(
            value: _delay.clamp(0, 120),
            min: 0,
            max: 120,
            divisions: 24,
            label: '${_delay.round()} min',
            onChanged: _enabled
                ? (v) => setState(() => _delay = v)
                : null,
            onChangeEnd: _enabled
                ? (v) async {
                    await setMeetingNotificationDelayMinutes(v.round());
                    if (mounted) widget.onPrefsChanged();
                  }
                : null,
          ),
          SwitchListTile(
            title: Text(l10n.meetingNotifHeadsUpTitle),
            subtitle: Text(l10n.meetingNotifHeadsUpSubtitle),
            value: _headsUp,
            onChanged: !_enabled
                ? null
                : (v) async {
                    await setMeetingNotificationsHeadsUp(v);
                    if (!mounted) return;
                    setState(() => _headsUp = v);
                    widget.onPrefsChanged();
                  },
          ),
        ],
      ),
    );
  }
}

