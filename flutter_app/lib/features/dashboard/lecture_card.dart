import 'package:flutter/material.dart';
import '../../core/ui/app_icons.dart';
import '../../l10n/app_localizations.dart';
import '../../models/schedule_models.dart';
import 'dashboard_utils.dart';

class LectureCard extends StatelessWidget {
  const LectureCard({
    super.key,
    required this.lecture,
    required this.allLectures,
    required this.showMeetingNumber,
    required this.l10n,
    required this.onStatus,
  });

  final Lecture lecture;
  final List<Lecture> allLectures;
  final bool showMeetingNumber;
  final AppLocalizations l10n;
  final void Function(Lecture, LectureStatus) onStatus;

  static const _compactBtnStyle = ButtonStyle(
    visualDensity: VisualDensity.compact,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    padding: WidgetStatePropertyAll(EdgeInsets.all(6)),
    minimumSize: WidgetStatePropertyAll(Size(32, 32)),
  );

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final useMenu = w < 400;

    final titleText =
        '${localizeCourseName(lecture.courseName, l10n)} • ${lecture.type}${showMeetingNumber ? ' • #${effectiveMeetingNumber(lecture, allLectures)}' : ''}';
    final metaText =
        '${formatTimeRange(lecture.start, lecture.end, l10n)} • ${lecture.room} • ${statusLabelL10n(lecture.status, l10n)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 40,
                  decoration: BoxDecoration(
                    color: lecture.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            meetingTypeIcon(lecture.type, l10n),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              titleText,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metaText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (useMenu)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _MarkMenuButton(
                  l10n: l10n,
                  lecture: lecture,
                  onStatus: onStatus,
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    IconButton(
                      style: _compactBtnStyle,
                      tooltip: l10n.markAttended,
                      onPressed: () =>
                          onStatus(lecture, LectureStatus.attended),
                      icon: const Icon(AppIcons.attended, color: Colors.green),
                    ),
                    IconButton(
                      style: _compactBtnStyle,
                      tooltip: l10n.markMissed,
                      onPressed: () => onStatus(lecture, LectureStatus.missed),
                      icon: const Icon(AppIcons.missed, color: Colors.red),
                    ),
                    IconButton(
                      style: _compactBtnStyle,
                      tooltip: l10n.markSkipped,
                      onPressed: () =>
                          onStatus(lecture, LectureStatus.skipped),
                      icon: const Icon(AppIcons.skipped),
                    ),
                    IconButton(
                      style: _compactBtnStyle,
                      tooltip: l10n.markWatchedRecording,
                      onPressed: () => onStatus(
                        lecture,
                        LectureStatus.watchedRecording,
                      ),
                      icon: const Icon(
                        AppIcons.watchedRecording,
                        color: Colors.blue,
                      ),
                    ),
                    IconButton(
                      style: _compactBtnStyle,
                      tooltip: l10n.markCanceled,
                      onPressed: () =>
                          onStatus(lecture, LectureStatus.canceled),
                      icon: const Icon(Icons.block, color: Colors.orange),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MarkMenuButton extends StatelessWidget {
  const _MarkMenuButton({
    required this.l10n,
    required this.lecture,
    required this.onStatus,
  });

  final AppLocalizations l10n;
  final Lecture lecture;
  final void Function(Lecture, LectureStatus) onStatus;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (context, controller, child) {
        return FilledButton.tonalIcon(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.more_horiz),
          label: Text(l10n.statusLabel),
        );
      },
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(AppIcons.attended, color: Colors.green),
          child: Text(l10n.markAttended),
          onPressed: () => onStatus(lecture, LectureStatus.attended),
        ),
        MenuItemButton(
          leadingIcon: const Icon(AppIcons.missed, color: Colors.red),
          child: Text(l10n.markMissed),
          onPressed: () => onStatus(lecture, LectureStatus.missed),
        ),
        MenuItemButton(
          leadingIcon: const Icon(AppIcons.skipped),
          child: Text(l10n.markSkipped),
          onPressed: () => onStatus(lecture, LectureStatus.skipped),
        ),
        MenuItemButton(
          leadingIcon:
              const Icon(AppIcons.watchedRecording, color: Colors.blue),
          child: Text(l10n.markWatchedRecording),
          onPressed: () =>
              onStatus(lecture, LectureStatus.watchedRecording),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.block, color: Colors.orange),
          child: Text(l10n.markCanceled),
          onPressed: () => onStatus(lecture, LectureStatus.canceled),
        ),
      ],
    );
  }
}
