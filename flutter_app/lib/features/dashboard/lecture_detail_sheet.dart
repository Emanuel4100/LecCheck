import 'package:flutter/material.dart';

import '../../core/platform/adaptive.dart';
import '../../core/ui/keyboard_inset.dart';
import '../../core/ui/linkified_text.dart';
import '../../core/util/open_url.dart';
import '../../l10n/app_localizations.dart';
import '../../models/schedule_models.dart';
import 'dashboard_utils.dart';

/// Result of [showLectureDetailEditor]; `null` if dismissed without saving.
enum LectureDetailOutcome {
  saved,
  oneOffRemoved,
  oneOffRescheduled,
}

List<Widget> buildLectureResourceEditorSection(
  BuildContext context,
  void Function(void Function()) setLocal,
  AppLocalizations l10n,
  Course course,
  Meeting? meeting,
  List<NamedLink> draftMeetingLinks,
) {
  final tiles = <Widget>[
    const SizedBox(height: 16),
    Text(
      l10n.resourcesSection,
      style: Theme.of(context).textTheme.titleSmall,
    ),
  ];
  if (course.link.trim().isNotEmpty) {
    tiles.add(
      ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.primaryCourseLink),
        subtitle: LinkifiedText(
          text: course.link,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.open_in_new, size: 20),
        onTap: () => tryLaunchLectureUrl(context, course.link),
      ),
    );
  }
  for (final l in course.extraLinks) {
    if (l.url.trim().isEmpty) continue;
    tiles.add(
      ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(l.title.trim().isEmpty ? l.url : l.title),
        subtitle: LinkifiedText(
          text: l.url,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.open_in_new, size: 20),
        onTap: () => tryLaunchLectureUrl(context, l.url),
      ),
    );
  }
  if (meeting != null) {
    tiles.addAll([
      const SizedBox(height: 8),
      Text(
        l10n.meetingLinksSection,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      Text(
        l10n.editMeetingResourcesHint,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      const SizedBox(height: 8),
    ]);
    tiles.addAll(
      draftMeetingLinks.map(
        (link) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ObjectKey(link),
                      initialValue: link.title,
                      decoration: InputDecoration(
                        labelText: l10n.linkTitleLabel,
                        isDense: true,
                      ),
                      onChanged: (v) => link.title = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      key: ValueKey('${identityHashCode(link)}_url'),
                      initialValue: link.url,
                      decoration: InputDecoration(
                        labelText: l10n.linkUrlLabel,
                        isDense: true,
                      ),
                      onChanged: (v) => setLocal(() => link.url = v),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        setLocal(() => draftMeetingLinks.remove(link)),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
              if (link.url.trim().isNotEmpty)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  title: LinkifiedText(
                    text: link.url.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.open_in_new, size: 20),
                  onTap: () => tryLaunchLectureUrl(context, link.url),
                ),
            ],
          ),
        ),
      ),
    );
    tiles.add(
      OutlinedButton.icon(
        onPressed: () => setLocal(
          () => draftMeetingLinks.add(NamedLink(title: '', url: '')),
        ),
        icon: const Icon(Icons.add_link, size: 18),
        label: Text(l10n.addNamedLink),
      ),
    );
  }
  return tiles;
}

Future<(String start, String end)?> _pickOneOffStartEnd(
  BuildContext context,
  AppLocalizations l10n,
  SemesterSchedule schedule,
  String initialStart,
  String initialEnd,
) {
  final options = defaultLectureTimeOptions();
  var start =
      options.contains(initialStart) ? initialStart : options.first;
  var end = options.contains(initialEnd) ? initialEnd : options.first;
  if (timeStringToMinutes(end) <= timeStringToMinutes(start)) {
    final next = options.where((t) => timeStringToMinutes(t) > timeStringToMinutes(start));
    end = next.isEmpty ? start : next.first;
  }
  final useDialog = Adaptive.isDesktop(context) || Adaptive.isWebLike(context);
  if (useDialog) {
    return showDialog<(String, String)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l10n.rescheduleOneOffDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.startTime, style: Theme.of(ctx).textTheme.labelMedium),
              const SizedBox(height: 4),
              DropdownButton<String>(
                isExpanded: true,
                value: start,
                items: options
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          formatTimeSlotLabel(
                            t,
                            l10n,
                            use24HourTime: schedule.use24HourTime,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setLocal(() {
                    start = v;
                    if (timeStringToMinutes(end) <= timeStringToMinutes(start)) {
                      final next = options.where(
                        (t) =>
                            timeStringToMinutes(t) > timeStringToMinutes(start),
                      );
                      end = next.isEmpty ? start : next.first;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              Text(l10n.endTime, style: Theme.of(ctx).textTheme.labelMedium),
              const SizedBox(height: 4),
              DropdownButton<String>(
                isExpanded: true,
                value: end,
                items: options
                    .where(
                      (t) => timeStringToMinutes(t) > timeStringToMinutes(start),
                    )
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          formatTimeSlotLabel(
                            t,
                            l10n,
                            use24HourTime: schedule.use24HourTime,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setLocal(() => end = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, (start, end)),
              child: Text(l10n.rescheduleOneOffApply),
            ),
          ],
        ),
      ),
    );
  }
  return showModalBottomSheet<(String, String)>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.rescheduleOneOffDialogTitle,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(l10n.startTime, style: Theme.of(ctx).textTheme.labelMedium),
              const SizedBox(height: 4),
              DropdownButton<String>(
                isExpanded: true,
                value: start,
                items: options
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          formatTimeSlotLabel(
                            t,
                            l10n,
                            use24HourTime: schedule.use24HourTime,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setLocal(() {
                    start = v;
                    if (timeStringToMinutes(end) <= timeStringToMinutes(start)) {
                      final next = options.where(
                        (t) =>
                            timeStringToMinutes(t) > timeStringToMinutes(start),
                      );
                      end = next.isEmpty ? start : next.first;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              Text(l10n.endTime, style: Theme.of(ctx).textTheme.labelMedium),
              const SizedBox(height: 4),
              DropdownButton<String>(
                isExpanded: true,
                value: end,
                items: options
                    .where(
                      (t) => timeStringToMinutes(t) > timeStringToMinutes(start),
                    )
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          formatTimeSlotLabel(
                            t,
                            l10n,
                            use24HourTime: schedule.use24HourTime,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setLocal(() => end = v);
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, (start, end)),
                    child: Text(l10n.rescheduleOneOffApply),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Dialog or bottom sheet: status, recording, links, lecture notes.
Future<LectureDetailOutcome?> showLectureDetailEditor(
  BuildContext context, {
  required SemesterSchedule schedule,
  required Lecture lecture,
  required List<Lecture> allLectures,
  required AppLocalizations l10n,
  required void Function(Lecture, LectureStatus) onStatus,
  required void Function(Course course, Meeting meeting, List<NamedLink> links)
      onMeetingLinksSaved,
  void Function(Course course, Meeting meeting)? onRemoveOneOffMeeting,
  void Function(Course course, Meeting meeting, DateTime date, String start,
          String end)?
      onRescheduleOneOffMeeting,
}) async {
  final course = courseById(schedule, lecture.courseId);
  final meeting = course != null ? meetingForLecture(course, lecture) : null;
  final draftMeetingLinks = <NamedLink>[];
  if (meeting != null) {
    for (final l in meeting.links) {
      draftMeetingLinks.add(NamedLink(title: l.title, url: l.url));
    }
  }
  final oneOffHandlersReady = meeting?.isOneOff == true &&
      course != null &&
      onRemoveOneOffMeeting != null &&
      onRescheduleOneOffMeeting != null;

  Future<void> removeOneOff(BuildContext modalCtx) async {
    final c = course;
    final meet = meeting;
    final onRemove = onRemoveOneOffMeeting;
    if (c == null || meet == null || !meet.isOneOff || onRemove == null) {
      return;
    }
    final ok = await showDialog<bool>(
      context: modalCtx,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeOneOffSession),
        content: Text(l10n.removeOneOffSessionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.removeOneOffSession),
          ),
        ],
      ),
    );
    if (ok == true && modalCtx.mounted) {
      onRemove(c, meet);
      Navigator.pop(modalCtx, LectureDetailOutcome.oneOffRemoved);
    }
  }

  Future<void> rescheduleOneOff(BuildContext modalCtx) async {
    final m = meeting;
    final c = course;
    final onReschedule = onRescheduleOneOffMeeting;
    if (m == null || c == null || !m.isOneOff || onReschedule == null) {
      return;
    }
    final initial = m.specificDate!;
    final first = DateTime(
      schedule.startDate.year,
      schedule.startDate.month,
      schedule.startDate.day,
    );
    final last = DateTime(
      schedule.endDate.year,
      schedule.endDate.month,
      schedule.endDate.day,
    );
    final picked = await showDatePicker(
      context: modalCtx,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: l10n.selectDate,
    );
    if (picked == null || !modalCtx.mounted) return;
    final normalized = DateTime(picked.year, picked.month, picked.day);
    if (normalized.isBefore(first) || normalized.isAfter(last)) {
      if (modalCtx.mounted) {
        ScaffoldMessenger.of(modalCtx).showSnackBar(
          SnackBar(content: Text(l10n.oneOffOutsideSemesterWarning)),
        );
      }
      return;
    }
    final times = await _pickOneOffStartEnd(
      modalCtx,
      l10n,
      schedule,
      m.start,
      m.end,
    );
    if (times == null || !modalCtx.mounted) return;
    onReschedule(c, m, normalized, times.$1, times.$2);
    Navigator.pop(modalCtx, LectureDetailOutcome.oneOffRescheduled);
  }

  List<Widget> oneOffSection(BuildContext modalCtx) {
    if (!oneOffHandlersReady) return <Widget>[];
    return [
      const Divider(height: 24),
      Text(
        l10n.oneTimeMeeting,
        style: Theme.of(modalCtx).textTheme.titleSmall,
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.delete_outline),
        title: Text(l10n.removeOneOffSession),
        onTap: () => removeOneOff(modalCtx),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.event_repeat),
        title: Text(l10n.rescheduleOneOffSession),
        onTap: () => rescheduleOneOff(modalCtx),
      ),
    ];
  }

  final options = [
    (LectureStatus.pending, l10n.statusPending),
    (LectureStatus.attended, l10n.markAttended),
    (LectureStatus.watchedRecording, l10n.markWatchedRecording),
    (LectureStatus.missed, l10n.markMissed),
    (LectureStatus.skipped, l10n.markSkipped),
    (LectureStatus.canceled, l10n.markCanceled),
  ];
  var selected = lecture.status;
  var hasRecording = (lecture.recordingLink ?? '').trim().isNotEmpty;
  final ctrl = TextEditingController(text: lecture.recordingLink ?? '');
  final notesCtrl = TextEditingController(text: lecture.notes);
  final useDialog = Adaptive.isDesktop(context) || Adaptive.isWebLike(context);
  final LectureDetailOutcome? outcome;
  if (useDialog) {
    outcome = await showDialog<LectureDetailOutcome?>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setLocal) => AlertDialog(
              title: Text(l10n.lectureDetailsTitle),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${localizeCourseName(lecture.courseName, l10n)} • ${lecture.type}${schedule.enableMeetingNumbers ? ' • #${effectiveMeetingNumber(lecture, allLectures)}' : ''}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${formatLectureDateMedium(lecture.date, l10n)} • ${formatTimeRange(lecture.start, lecture.end, l10n, use24HourTime: schedule.use24HourTime)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      if (lecture.room.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lecture.room,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      DropdownButtonFormField<LectureStatus>(
                        initialValue: selected,
                        decoration: InputDecoration(
                          labelText: l10n.statusLabel,
                        ),
                        items: options
                            .map(
                              (entry) => DropdownMenuItem(
                                value: entry.$1,
                                child: Row(
                                  children: [
                                    Icon(statusIcon(entry.$1)),
                                    const SizedBox(width: 8),
                                    Text(entry.$2),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setLocal(() => selected = v!),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.lectureNotesLabel,
                          hintText: l10n.lectureNotesHint,
                          alignLabelWithHint: true,
                        ),
                        minLines: 2,
                        maxLines: 6,
                      ),
                      LinkifiedNotesPreview(controller: notesCtrl),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: hasRecording,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setLocal(() => hasRecording = v!),
                        title: Text(l10n.addRecordingLink),
                      ),
                      if (hasRecording)
                        TextField(
                          controller: ctrl,
                          decoration: InputDecoration(
                            labelText: l10n.recordingLink,
                          ),
                        ),
                      if (course != null)
                        ...buildLectureResourceEditorSection(
                          context,
                          setLocal,
                          l10n,
                          course,
                          meeting,
                          draftMeetingLinks,
                        ),
                      ...oneOffSection(dialogContext),
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
                  onPressed: () =>
                      Navigator.pop(context, LectureDetailOutcome.saved),
                  child: Text(l10n.save),
                ),
              ],
            ),
          ),
        );
  } else {
    outcome = await showModalBottomSheet<LectureDetailOutcome?>(
          context: context,
          isScrollControlled: true,
          builder: (sheetContext) => wrapBottomSheetKeyboardPadding(
            sheetContext: sheetContext,
            child: StatefulBuilder(
              builder: (context, setLocal) => Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${localizeCourseName(lecture.courseName, l10n)} • ${lecture.type}${schedule.enableMeetingNumbers ? ' • #${effectiveMeetingNumber(lecture, allLectures)}' : ''}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${formatLectureDateMedium(lecture.date, l10n)} • ${formatTimeRange(lecture.start, lecture.end, l10n, use24HourTime: schedule.use24HourTime)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      if (lecture.room.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lecture.room,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      DropdownButtonFormField<LectureStatus>(
                        initialValue: selected,
                        decoration: InputDecoration(
                          labelText: l10n.statusLabel,
                        ),
                        items: options
                            .map(
                              (entry) => DropdownMenuItem(
                                value: entry.$1,
                                child: Row(
                                  children: [
                                    Icon(statusIcon(entry.$1)),
                                    const SizedBox(width: 8),
                                    Text(entry.$2),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setLocal(() => selected = v!),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.lectureNotesLabel,
                          hintText: l10n.lectureNotesHint,
                          alignLabelWithHint: true,
                        ),
                        minLines: 2,
                        maxLines: 6,
                      ),
                      LinkifiedNotesPreview(controller: notesCtrl),
                      CheckboxListTile(
                        value: hasRecording,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setLocal(() => hasRecording = v!),
                        title: Text(l10n.addRecordingLink),
                      ),
                      if (hasRecording)
                        TextField(
                          controller: ctrl,
                          decoration: InputDecoration(
                            labelText: l10n.recordingLink,
                          ),
                        ),
                      if (course != null)
                        ...buildLectureResourceEditorSection(
                          context,
                          setLocal,
                          l10n,
                          course,
                          meeting,
                          draftMeetingLinks,
                        ),
                      ...oneOffSection(sheetContext),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: Text(l10n.cancel),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => Navigator.pop(
                              sheetContext,
                              LectureDetailOutcome.saved,
                            ),
                            child: Text(l10n.save),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
  }
  if (outcome == LectureDetailOutcome.saved && context.mounted) {
    lecture.recordingLink = hasRecording ? ctrl.text.trim() : null;
    lecture.notes = notesCtrl.text.trim();
    onStatus(lecture, selected);
    if (course != null && meeting != null) {
      onMeetingLinksSaved(
        course,
        meeting,
        draftMeetingLinks
            .map((l) => NamedLink(title: l.title.trim(), url: l.url.trim()))
            .where((l) => l.title.isNotEmpty || l.url.isNotEmpty)
            .toList(),
      );
    }
  }
  return outcome;
}
