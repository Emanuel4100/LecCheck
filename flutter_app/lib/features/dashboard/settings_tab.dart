import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/about_info.dart';
import '../../core/notifications/meeting_notifications.dart';
import '../../core/platform/adaptive.dart';
import '../../core/schedule/schedule_persistence.dart';
import 'dev_settings.dart';
import '../../core/ui/app_icons.dart';
import '../../l10n/app_localizations.dart';
import '../../models/schedule_models.dart';
import 'dashboard_utils.dart';

class SettingsTab extends StatefulWidget {
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
    required this.onRecountMeetings,
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
    required this.onLogin,
    required this.isSignedIn,
    required this.syncStatus,
    required this.onClearCache,
    required this.onRebootstrap,
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
  final VoidCallback onRecountMeetings;
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
  final VoidCallback onLogin;
  final bool isSignedIn;
  final ValueListenable<SyncStatus> syncStatus;
  final VoidCallback onClearCache;
  final VoidCallback onRebootstrap;
  final AppLocalizations l10n;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  int _aboutTapCount = 0;
  bool _devMode = false;

  @override
  void initState() {
    super.initState();
    _loadDevMode();
  }

  Future<void> _loadDevMode() async {
    final enabled = await isDevModeEnabled();
    if (mounted && enabled != _devMode) setState(() => _devMode = enabled);
  }

  void _onAboutTap(BuildContext context) {
    _aboutTapCount++;
    final l10n = widget.l10n;
    if (_aboutTapCount == 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.devNoDevOptions)),
      );
    } else if (_aboutTapCount == 30) {
      setDevModeEnabled(true);
      setState(() => _devMode = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.devModeEnabled)),
      );
    }
  }

  // Convenience accessors to avoid `widget.` everywhere.
  SemesterSchedule get schedule => widget.schedule;
  ScheduleRootState get scheduleRoot => widget.scheduleRoot;
  AppLocalizations get l10n => widget.l10n;
  ValueChanged<String> get onSwitchActiveSemester => widget.onSwitchActiveSemester;
  void Function(String, DateTime, DateTime) get onAddSemester => widget.onAddSemester;
  void Function(String, String) get onRenameSemester => widget.onRenameSemester;
  Future<void> Function(String) get onDeleteSemester => widget.onDeleteSemester;
  VoidCallback get onExportSchedule => widget.onExportSchedule;
  void Function(BuildContext) get onImportSchedule => widget.onImportSchedule;
  VoidCallback get onMeetingNotifPrefsChanged => widget.onMeetingNotifPrefsChanged;
  ValueChanged<String> get onChangeLanguage => widget.onChangeLanguage;
  ValueChanged<Set<int>> get onChangeVisibleDays => widget.onChangeVisibleDays;
  ValueChanged<bool> get onToggleMeetingNumbers => widget.onToggleMeetingNumbers;
  VoidCallback get onRecountMeetings => widget.onRecountMeetings;
  ValueChanged<bool> get onUse24HourTimeChanged => widget.onUse24HourTimeChanged;
  ValueChanged<int> get onChangeWeekStart => widget.onChangeWeekStart;
  ValueChanged<DateTime> get onChangeStartDate => widget.onChangeStartDate;
  ValueChanged<DateTime> get onChangeEndDate => widget.onChangeEndDate;
  void Function(DateTime, DateTime) get onAddVacationRange => widget.onAddVacationRange;
  VoidCallback get onClearAllNoClassDays => widget.onClearAllNoClassDays;
  ThemeMode get themeMode => widget.themeMode;
  ValueChanged<ThemeMode> get onThemeModeChanged => widget.onThemeModeChanged;
  VoidCallback get onManageCourses => widget.onManageCourses;
  VoidCallback get onReset => widget.onReset;
  VoidCallback get onLogout => widget.onLogout;
  VoidCallback get onLogin => widget.onLogin;
  bool get isSignedIn => widget.isSignedIn;
  ValueListenable<SyncStatus> get syncStatus => widget.syncStatus;

  @override
  Widget build(BuildContext context) {
    final orderedStartDays = orderedWeekdaysFromStart(schedule.weekStartsOn);
    final theme = Theme.of(context);

    Widget sectionHeader(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 6),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Adaptive.isDesktop(context) ? 720 : double.infinity,
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            // ── Cloud Sync ──
            ValueListenableBuilder<SyncStatus>(
              valueListenable: syncStatus,
              builder: (context, status, _) {
                final (Color color, IconData icon, String label) = switch (status) {
                  SyncStatus.synced    => (Colors.green,        Icons.cloud_done,         l10n.syncStatusSynced),
                  SyncStatus.syncing   => (Colors.blue,         Icons.cloud_upload,        l10n.syncStatusSyncing),
                  SyncStatus.noNetwork => (Colors.orange,       Icons.cloud_off,           l10n.syncStatusNoNetwork),
                  SyncStatus.error     => (Colors.red,          Icons.error_outline,       l10n.syncStatusError),
                  SyncStatus.offline   => (Colors.grey,         Icons.cloud_off_outlined,  l10n.syncStatusOffline),
                };
                return Card(
                  child: ListTile(
                    leading: Icon(icon, color: color),
                    title: Text(l10n.syncStatusLabel),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(label, style: TextStyle(color: color)),
                      ],
                    ),
                  ),
                );
              },
            ),

            // ── Semesters ──
            sectionHeader(l10n.semestersSectionTitle),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.semestersSectionSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...scheduleRoot.slots.map((s) {
                      final active = s.id == scheduleRoot.activeSemesterId;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          active ? Icons.check_circle : Icons.calendar_month_outlined,
                          color: active ? theme.colorScheme.primary : null,
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
                                  color: theme.colorScheme.error,
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

            // ── Courses ──
            sectionHeader(l10n.settingsSectionCourses),
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
              child: Column(
                children: [
                  SwitchListTile(
                    value: schedule.enableMeetingNumbers,
                    onChanged: onToggleMeetingNumbers,
                    secondary: const Icon(AppIcons.numbering),
                    title: Text(l10n.autoMeetingNumbers),
                  ),
                  if (schedule.enableMeetingNumbers)
                    Padding(
                      padding: const EdgeInsets.only(left: 56, right: 16, bottom: 12),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: () {
                            onRecountMeetings();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.recountMeetingsDone)),
                            );
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(l10n.recountMeetings),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Schedule ──
            sectionHeader(l10n.settingsSectionSchedule),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.vacationsSectionTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.vacationsSectionSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noClassDaysCount(schedule.noClassDateKeys.length),
                      style: theme.textTheme.bodyMedium,
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

            // ── Appearance ──
            sectionHeader(l10n.settingsSectionAppearance),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.themeModeLabel,
                      style: theme.textTheme.titleSmall,
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
              child: SwitchListTile(
                secondary: const Icon(Icons.schedule),
                title: Text(l10n.use24HourTimeTitle),
                subtitle: Text(l10n.use24HourTimeSubtitle),
                value: schedule.use24HourTime,
                onChanged: onUse24HourTimeChanged,
              ),
            ),

            // ── Notifications ──
            sectionHeader(l10n.settingsSectionNotifications),
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

            // ── Data ──
            sectionHeader(l10n.settingsSectionData),
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

            // ── Account ──
            sectionHeader(l10n.settingsSectionAccount),
            Card(
              child: ListTile(
                leading: Icon(isSignedIn ? AppIcons.logout : Icons.login),
                title: Text(isSignedIn ? l10n.logout : l10n.login),
                trailing: OutlinedButton(
                  onPressed: isSignedIn ? onLogout : onLogin,
                  child: Text(isSignedIn ? l10n.logout : l10n.login),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(AppIcons.reset),
                title: Text(l10n.resetSemester),
                trailing: OutlinedButton(onPressed: onReset, child: Text(l10n.reset)),
              ),
            ),

            // ── Developer (easter egg) ──
            if (_devMode) ...[
              sectionHeader(l10n.settingsSectionDeveloper),
              DevSettingsSection(
                l10n: l10n,
                syncStatus: syncStatus,
                onClearCache: widget.onClearCache,
                onRebootstrap: widget.onRebootstrap,
                onDevModeDisabled: () => setState(() => _devMode = false),
              ),
            ],

            // ── About ──
            GestureDetector(
              onTap: () => _onAboutTap(context),
              child: sectionHeader(l10n.aboutSectionTitle),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          color: theme.colorScheme.primary,
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
            const SizedBox(height: 16),
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
      final granted = await ensureAndroidNotificationSchedulingReady();
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

