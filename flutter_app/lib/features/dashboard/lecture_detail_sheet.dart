import 'package:flutter/material.dart';

import '../../core/platform/adaptive.dart';
import '../../core/ui/keyboard_inset.dart';
import '../../core/ui/linkified_text.dart';
import '../../core/util/open_url.dart';
import '../../l10n/app_localizations.dart';
import '../../models/schedule_models.dart';
import 'dashboard_utils.dart';

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
          child: Row(
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
                  onChanged: (v) => link.url = v,
                ),
              ),
              IconButton(
                onPressed: () => setLocal(() => draftMeetingLinks.remove(link)),
                icon: const Icon(Icons.remove_circle_outline),
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

/// Dialog or bottom sheet: status, recording, links, lecture notes.
Future<void> showLectureDetailEditor(
  BuildContext context, {
  required SemesterSchedule schedule,
  required Lecture lecture,
  required List<Lecture> allLectures,
  required AppLocalizations l10n,
  required void Function(Lecture, LectureStatus) onStatus,
  required void Function(Course course, Meeting meeting, List<NamedLink> links)
      onMeetingLinksSaved,
}) async {
  final course = courseById(schedule, lecture.courseId);
  final meeting = course != null ? meetingForLecture(course, lecture) : null;
  final draftMeetingLinks = <NamedLink>[];
  if (meeting != null) {
    for (final l in meeting.links) {
      draftMeetingLinks.add(NamedLink(title: l.title, url: l.url));
    }
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
  final bool? saved = useDialog
      ? await showDialog<bool>(
          context: context,
          builder: (_) => StatefulBuilder(
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
                            Icon(Icons.location_on_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lecture.room,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.save),
                ),
              ],
            ),
          ),
        )
      : await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          builder: (sheetContext) => wrapBottomSheetKeyboardPadding(
            sheetContext: sheetContext,
            child: StatefulBuilder(
              builder: (context, setLocal) => SingleChildScrollView(
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
                            Icon(Icons.location_on_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lecture.room,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.pop(sheetContext, true),
                          child: Text(l10n.save),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        );
  if (saved == true && context.mounted) {
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
}
