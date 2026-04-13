import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/platform/adaptive.dart';
import '../../core/ui/app_icons.dart';
import '../../core/ui/linkified_text.dart';
import '../../l10n/app_localizations.dart';
import '../../models/schedule_models.dart';
import '../dashboard/dashboard_utils.dart' show weekdayLabelL10n;

/// Full-screen add/edit course: info, extra links, weekly meetings (+ links).
class CourseEditorPage extends StatefulWidget {
  const CourseEditorPage({
    super.key,
    required this.schedule,
    this.existing,
    required this.onSaved,
    this.onDeleted,
  });

  final SemesterSchedule schedule;
  final Course? existing;
  final void Function(CourseEditorPayload payload, List<Meeting> meetings) onSaved;
  final VoidCallback? onDeleted;

  @override
  State<CourseEditorPage> createState() => _CourseEditorPageState();
}

class _CourseEditorPageState extends State<CourseEditorPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _lecturerCtrl;
  late final TextEditingController _linkCtrl;
  late final TextEditingController _notesCtrl;
  late Color _color;
  final List<NamedLink> _extraLinks = [];
  final List<Meeting> _meetings = [];

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    if (c != null) {
      _nameCtrl = TextEditingController(text: c.name);
      _codeCtrl = TextEditingController(text: c.code);
      _lecturerCtrl = TextEditingController(text: c.lecturer);
      _linkCtrl = TextEditingController(text: c.link);
      _notesCtrl = TextEditingController(text: c.notes);
      _color = c.color;
      for (final e in c.extraLinks) {
        _extraLinks.add(NamedLink(title: e.title, url: e.url));
      }
      for (final m in c.meetings) {
        _meetings.add(
          Meeting(
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
          ),
        );
      }
    } else {
      _nameCtrl = TextEditingController();
      _codeCtrl = TextEditingController();
      _lecturerCtrl = TextEditingController();
      _linkCtrl = TextEditingController();
      _notesCtrl = TextEditingController();
      _color = Colors.primaries[Random().nextInt(Colors.primaries.length)];
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _lecturerCtrl.dispose();
    _linkCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
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

  static const List<Color> _quickPalette = <Color>[
    Color(0xFF2A7BCC),
    Color(0xFFD32F2F),
    Color(0xFF388E3C),
    Color(0xFFF57C00),
    Color(0xFF7B1FA2),
    Color(0xFF0097A7),
    Color(0xFFC0CA33),
    Color(0xFF5D4037),
    Color(0xFF455A64),
    Color(0xFFE91E63),
    Color(0xFF3F51B5),
    Color(0xFF795548),
  ];

  Future<void> _openFullPalette(BuildContext context, AppLocalizations l10n) async {
    final extended = <Color>[
      ..._quickPalette,
      ...Colors.primaries.map((m) => m.shade600),
      ...Colors.accents.map((m) => m.shade400),
    ];
    final colors = <Color>{...extended}.toList();
    if (!context.mounted) return;
    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.pickColorTitle),
        content: SizedBox(
          width: 300,
          height: 320,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: colors.length,
            itemBuilder: (context, i) {
              final c = colors[i];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(ctx, c),
                  customBorder: const CircleBorder(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    if (picked != null && mounted) setState(() => _color = picked);
  }

  void _addMeeting(AppLocalizations l10n) {
    final orderedDays = orderedWeekdaysForSchedule(widget.schedule);
    if (orderedDays.isEmpty) return;
    final startTimes = _timeOptions();
    final meetingTypes = [
      l10n.lectureType,
      l10n.practiceType,
      l10n.labType,
      l10n.otherType,
    ];
    setState(() {
      _meetings.add(
        Meeting(
          weekday: orderedDays.first,
          start: startTimes[4],
          end: _endFromStartAndDuration(startTimes[4], 60),
          room: '',
          type: meetingTypes.first,
        ),
      );
    });
  }

  void _save(BuildContext context, AppLocalizations l10n) {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.courseNameRequired)),
      );
      return;
    }
    for (final m in _meetings) {
      if (_toMinutes(m.end) <= _toMinutes(m.start)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.endAfterStartError)),
        );
        return;
      }
    }
    final payload = CourseEditorPayload(
      name: _nameCtrl.text.trim(),
      lecturer: _lecturerCtrl.text.trim(),
      code: _codeCtrl.text.trim(),
      link: _linkCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      extraLinks: _extraLinks
          .where((e) => e.title.trim().isNotEmpty || e.url.trim().isNotEmpty)
          .map((e) => NamedLink(title: e.title.trim(), url: e.url.trim()))
          .toList(),
      color: _color,
    );
    final meetingsCopy = _meetings
        .map(
          (m) => Meeting(
            id: m.id,
            weekday: m.weekday,
            start: m.start,
            end: m.end,
            room: m.room,
            type: m.type,
            specificDate: m.specificDate,
            links: m.links
                .where(
                  (l) => l.title.trim().isNotEmpty || l.url.trim().isNotEmpty,
                )
                .map(
                  (l) => NamedLink(title: l.title.trim(), url: l.url.trim()),
                )
                .toList(),
          ),
        )
        .toList();
    widget.onSaved(payload, meetingsCopy);
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete(BuildContext context, AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCourseConfirmTitle),
        content: Text(l10n.deleteCourseConfirmBody),
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
      widget.onDeleted?.call();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final orderedDays = orderedWeekdaysForSchedule(widget.schedule);
    final meetingTypes = [
      l10n.lectureType,
      l10n.practiceType,
      l10n.labType,
      l10n.otherType,
    ];
    final startTimes = _timeOptions();
    final maxW = min(640.0, MediaQuery.sizeOf(context).width - 24);

    final hPad = Adaptive.horizontalPadding(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          widget.existing == null ? l10n.addCourse : l10n.editCourseTitle,
        ),
        actions: [
          if (widget.onDeleted != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, l10n),
            ),
          TextButton(
            onPressed: () => _save(context, l10n),
            child: Text(l10n.save),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            hPad,
            hPad,
            hPad,
            hPad + bottomInset,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.courseInfoSection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.courseName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.courseCodeOptional,
                    hintText: l10n.optionalFieldHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lecturerCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.lecturer,
                    hintText: l10n.optionalFieldHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _linkCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.link,
                    hintText: l10n.optionalFieldHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.courseNotesLabel,
                    hintText: l10n.courseNotesHint,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                LinkifiedNotesPreview(controller: _notesCtrl),
                const SizedBox(height: 16),
                Text(
                  l10n.courseColorLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ..._quickPalette.map((c) {
                      final selected = c == _color;
                      return InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _color = c),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                              width: selected ? 2.5 : 1,
                            ),
                          ),
                          child: selected
                              ? Icon(
                                  Icons.check,
                                  size: 20,
                                  color: ThemeData.estimateBrightnessForColor(
                                            c,
                                          ) ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                )
                              : null,
                        ),
                      );
                    }),
                    Tooltip(
                      message: l10n.moreColors,
                      child: IconButton.filledTonal(
                        onPressed: () => _openFullPalette(context, l10n),
                        icon: const Icon(Icons.palette_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.courseExtraLinksSection,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.namedLinkExampleHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                ..._extraLinks.asMap().entries.map((e) {
                  final i = e.key;
                  final link = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: ObjectKey(link),
                            initialValue: link.title,
                            decoration: InputDecoration(
                              labelText: l10n.linkTitleLabel,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (v) => link.title = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            key: ValueKey('${link.hashCode}_url'),
                            initialValue: link.url,
                            decoration: InputDecoration(
                              labelText: l10n.linkUrlLabel,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (v) => link.url = v,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _extraLinks.removeAt(i)),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                      ],
                    ),
                  );
                }),
                OutlinedButton.icon(
                  onPressed: () => setState(
                    () => _extraLinks.add(NamedLink(title: '', url: '')),
                  ),
                  icon: const Icon(Icons.add_link),
                  label: Text(l10n.addNamedLink),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.meetingsSection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ..._meetings.asMap().entries.map((entry) {
                  final index = entry.key;
                  final m = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  m.isOneOff
                                      ? l10n.oneOffSessionTitle(index + 1)
                                      : l10n.weeklySessionTitle(index + 1),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall,
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(
                                  () => _meetings.removeAt(index),
                                ),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
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
                            selected: {m.isOneOff},
                            onSelectionChanged: (v) {
                              if (v.isEmpty) return;
                              setState(() {
                                if (v.first) {
                                  if (m.specificDate == null) {
                                    final now = DateTime.now();
                                    final sch = widget.schedule;
                                    m.specificDate = now.isBefore(sch.startDate)
                                        ? sch.startDate
                                        : now.isAfter(sch.endDate)
                                            ? sch.endDate
                                            : now;
                                  }
                                } else {
                                  m.specificDate = null;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            key: ValueKey('${m.id}_type'),
                            initialValue: meetingTypes.contains(m.type)
                                ? m.type
                                : meetingTypes.first,
                            decoration: InputDecoration(
                              labelText: l10n.type,
                              border: const OutlineInputBorder(),
                            ),
                            items: meetingTypes
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => m.type = v!),
                          ),
                          const SizedBox(height: 8),
                          if (m.isOneOff)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(l10n.selectDate),
                              trailing: Text(
                                m.specificDate != null
                                    ? '${m.specificDate!.day}/${m.specificDate!.month}/${m.specificDate!.year}'
                                    : '—',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: m.specificDate ?? DateTime.now(),
                                  firstDate: widget.schedule.startDate,
                                  lastDate: widget.schedule.endDate,
                                );
                                if (picked != null) {
                                  setState(() {
                                    m.specificDate = picked;
                                    m.weekday = picked.weekday;
                                  });
                                }
                              },
                            )
                          else
                            DropdownButtonFormField<int>(
                              key: ValueKey('${m.id}_day'),
                              initialValue: orderedDays.contains(m.weekday)
                                  ? m.weekday
                                  : orderedDays.first,
                              decoration: InputDecoration(
                                labelText: l10n.weekday,
                                border: const OutlineInputBorder(),
                              ),
                              items: orderedDays
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(weekdayLabelL10n(d, l10n)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => m.weekday = v!),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  key: ValueKey('${m.id}_start'),
                                  initialValue: startTimes.contains(m.start)
                                      ? m.start
                                      : startTimes[4],
                                  decoration: InputDecoration(
                                    labelText: l10n.startTime,
                                    border: const OutlineInputBorder(),
                                  ),
                                  items: startTimes
                                      .map(
                                        (t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(t),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(() {
                                    m.start = v ?? m.start;
                                    if (_toMinutes(m.end) <= _toMinutes(m.start)) {
                                      m.end = _endFromStartAndDuration(
                                        m.start,
                                        60,
                                      );
                                    }
                                  }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  key: ValueKey('${m.id}_end'),
                                  initialValue: startTimes.contains(m.end)
                                      ? m.end
                                      : _endFromStartAndDuration(m.start, 60),
                                  decoration: InputDecoration(
                                    labelText: l10n.endTime,
                                    border: const OutlineInputBorder(),
                                  ),
                                  items: startTimes
                                      .map(
                                        (t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(t),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => m.end = v ?? m.end),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: ObjectKey(m),
                            initialValue: m.room,
                            decoration: InputDecoration(
                              labelText: l10n.meetingLocationLabel,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (v) => m.room = v,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.meetingLinksSection,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.meetingLinkExampleHint,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          ...m.links.asMap().entries.map((le) {
                            final li = le.key;
                            final link = le.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      key: ObjectKey(link),
                                      initialValue: link.title,
                                      decoration: InputDecoration(
                                        labelText: l10n.linkTitleLabel,
                                        border: const OutlineInputBorder(),
                                      ),
                                      onChanged: (v) => link.title = v,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      key: ValueKey('${link.hashCode}_murl'),
                                      initialValue: link.url,
                                      decoration: InputDecoration(
                                        labelText: l10n.linkUrlLabel,
                                        border: const OutlineInputBorder(),
                                      ),
                                      onChanged: (v) => link.url = v,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        setState(() => m.links.removeAt(li)),
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                ],
                              ),
                            );
                          }),
                          OutlinedButton.icon(
                            onPressed: () => setState(
                              () => m.links.add(NamedLink(title: '', url: '')),
                            ),
                            icon: const Icon(Icons.add_link),
                            label: Text(l10n.addNamedLink),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                OutlinedButton.icon(
                  onPressed: () => _addMeeting(l10n),
                  icon: const Icon(AppIcons.addMeeting),
                  label: Text(l10n.addSession),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _save(context, l10n),
                  icon: const Icon(Icons.check),
                  label: Text(l10n.save),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData meetingTypeIcon(String type, AppLocalizations l10n) {
  if (type == l10n.labType) return AppIcons.meetingLab;
  if (type == l10n.practiceType) return AppIcons.meetingPractice;
  if (type == l10n.otherType) return AppIcons.meetingOther;
  return AppIcons.meetingLecture;
}

String formatTimeRangeLocalized(
  String start,
  String end,
  AppLocalizations l10n,
) {
  final locale = l10n.localeName;
  final now = DateTime.now();
  final startParts = start.split(':');
  final endParts = end.split(':');
  final startDt = DateTime(
    now.year,
    now.month,
    now.day,
    int.parse(startParts[0]),
    int.parse(startParts[1]),
  );
  final endDt = DateTime(
    now.year,
    now.month,
    now.day,
    int.parse(endParts[0]),
    int.parse(endParts[1]),
  );
  final fmt = DateFormat.jm(locale);
  return '${fmt.format(startDt)} - ${fmt.format(endDt)}';
}
