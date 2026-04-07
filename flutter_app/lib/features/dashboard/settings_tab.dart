import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/about_info.dart';
import '../../core/ui/app_icons.dart';
import '../../l10n/app_localizations.dart';
import '../../models/schedule_models.dart';
import 'dashboard_utils.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({
    super.key,
    required this.schedule,
    required this.onChangeLanguage,
    required this.onChangeVisibleDays,
    required this.onToggleMeetingNumbers,
    required this.onChangeWeekStart,
    required this.onChangeStartDate,
    required this.onChangeEndDate,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onManageCourses,
    required this.onReset,
    required this.onLogout,
    required this.l10n,
  });

  final SemesterSchedule schedule;
  final ValueChanged<String> onChangeLanguage;
  final ValueChanged<Set<int>> onChangeVisibleDays;
  final ValueChanged<bool> onToggleMeetingNumbers;
  final ValueChanged<int> onChangeWeekStart;
  final ValueChanged<DateTime> onChangeStartDate;
  final ValueChanged<DateTime> onChangeEndDate;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onManageCourses;
  final VoidCallback onReset;
  final VoidCallback onLogout;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final orderedStartDays = orderedWeekdaysFromStart(schedule.weekStartsOn);
    return ListView(
      children: [
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
    );
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
