import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/platform/adaptive.dart';
import '../../l10n/app_localizations.dart';
import '../../models/schedule_models.dart';
import 'dashboard_utils.dart';

class WeeklyTab extends StatefulWidget {
  const WeeklyTab({
    super.key,
    required this.schedule,
    required this.allLectures,
    required this.attendance,
    required this.weekSyncToken,
    required this.onStatus,
    required this.onMeetingLinksSaved,
    required this.l10n,
  });

  final SemesterSchedule schedule;
  final List<Lecture> allLectures;
  final double attendance;
  /// When this value changes, grid week jumps to the week containing today.
  final int weekSyncToken;
  final void Function(Lecture, LectureStatus) onStatus;
  final void Function(Course course, Meeting meeting, List<NamedLink> links)
      onMeetingLinksSaved;
  final AppLocalizations l10n;

  @override
  State<WeeklyTab> createState() => _WeeklyTabState();
}

class _WeeklyTabState extends State<WeeklyTab> {
  late DateTime _currentWeekStart;

  @override
  void initState() {
    super.initState();
    _currentWeekStart =
        weekStartForDate(DateTime.now(), widget.schedule.weekStartsOn);
  }

  @override
  void didUpdateWidget(covariant WeeklyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekSyncToken != widget.weekSyncToken) {
      _currentWeekStart =
          weekStartForDate(DateTime.now(), widget.schedule.weekStartsOn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDays = orderedWeekdaysForSchedule(widget.schedule);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${widget.l10n.attendance} ${(widget.attendance * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: _canGoPrevWeek() ? _goPrevWeek : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                _weekRangeLabel(activeDays),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: _canGoNextWeek() ? _goNextWeek : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: widget.attendance),
        const SizedBox(height: 12),
        Expanded(
          child: _buildGrid(context, activeDays),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, List<int> activeDays) {
    final byDay = <int, List<Lecture>>{};
    for (final day in activeDays) {
      final date = _dateForDay(day, activeDays);
      byDay[day] = widget.allLectures
          .where(
            (l) =>
                l.date.year == date.year &&
                l.date.month == date.month &&
                l.date.day == date.day,
          )
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = activeDays.isEmpty ? 1 : activeDays.length;
        const totalHours = 16;
        const timeAxisWidth = 56.0;
        const dayHeaderHeight = 32.0;
        final minCellWidth = Adaptive.isDesktop(context)
            ? 200.0
            : Adaptive.isTablet(context)
                ? 180.0
                : 72.0;
        final availW =
            (constraints.maxWidth - timeAxisWidth).clamp(1.0, double.infinity);
        final cellWidth =
            (availW / columns).clamp(minCellWidth, 320.0);
        final hourHeight = ((constraints.maxHeight - dayHeaderHeight) /
                totalHours)
            .clamp(32.0, 64.0);
        final gridHeight = hourHeight * totalHours;
        final compactTile = cellWidth < 120;
        final isCurrentWeek = _isCurrentWeek();
        final now = DateTime.now();
        final nowTop =
            (((now.hour * 60 + now.minute) - (8 * 60)) / 60.0) * hourHeight;
        return SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: timeAxisWidth + (cellWidth * columns),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: timeAxisWidth,
                    child: Column(
                      children: [
                        SizedBox(height: dayHeaderHeight),
                        ...List.generate(totalHours, (index) {
                          final hour = 8 + index;
                          final label = TimeOfDay(hour: hour, minute: 0).format(
                            context,
                          );
                          return SizedBox(
                            height: hourHeight,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: compactTile ? 10 : 12,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  ...activeDays.map((day) {
                    final items = byDay[day] ?? const <Lecture>[];
                    return SizedBox(
                      width: cellWidth,
                      child: Column(
                        children: [
                          SizedBox(
                            height: dayHeaderHeight,
                            child: Center(
                              child: Text(
                                '${weekdayLabelL10n(day, widget.l10n)} ${_dateForDay(day, activeDays).day}/${_dateForDay(day, activeDays).month}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: compactTile ? 10 : 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: gridHeight,
                            child: RepaintBoundary(
                              child: Stack(
                                children: [
                                ...List.generate(
                                  totalHours,
                                  (index) => Positioned(
                                    left: 0,
                                    right: 0,
                                    top: index * hourHeight,
                                    child: const Divider(height: 1),
                                  ),
                                ),
                                if (isCurrentWeek &&
                                    nowTop >= 0 &&
                                    nowTop <= gridHeight &&
                                    _dateForDay(day, activeDays).year ==
                                        now.year &&
                                    _dateForDay(day, activeDays).month ==
                                        now.month &&
                                    _dateForDay(day, activeDays).day == now.day)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: nowTop,
                                    child: Container(
                                      height: 2,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ...items.map((lecture) {
                                  final startM = _toMinutes(lecture.start);
                                  final endM = _toMinutes(lecture.end);
                                  final top =
                                      ((startM - (8 * 60)) / 60.0) * hourHeight;
                                  final height = ((endM - startM) / 60.0) *
                                      hourHeight;
                                  return Positioned(
                                    left: compactTile ? 2 : 6,
                                    right: compactTile ? 2 : 6,
                                    top: top.clamp(0, gridHeight - 24),
                                    height: height.clamp(
                                      30,
                                      (hourHeight * 6).clamp(48, 200),
                                    ),
                                    child: GestureDetector(
                                      onTap: () => _onGridTap(context, lecture),
                                      child: Container(
                                        padding: EdgeInsets.all(
                                          compactTile ? 4 : 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: tileBackgroundForCourse(
                                            lecture.color,
                                            context,
                                          ),
                                          border: Border.all(
                                            color: statusColor(lecture.status),
                                            width: 1.2,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        clipBehavior: Clip.hardEdge,
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            return FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.topLeft,
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth: constraints.maxWidth,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: double.infinity,
                                                      height: 4,
                                                      decoration: BoxDecoration(
                                                        color: statusColor(
                                                            lecture.status),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(3),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                        height:
                                                            compactTile ? 2 : 4),
                                                    FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      alignment:
                                                          Alignment.topLeft,
                                                      child: Text(
                                                        localizeCourseName(
                                                          lecture.courseName,
                                                          widget.l10n,
                                                        ),
                                                        maxLines: 2,
                                                        softWrap: true,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: compactTile
                                                              ? 9
                                                              : 11,
                                                          height: 1.1,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      formatTimeRange(
                                                        lecture.start,
                                                        lecture.end,
                                                        widget.l10n,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize:
                                                            compactTile ? 9 : 11,
                                                      ),
                                                    ),
                                                    if (widget.schedule
                                                        .enableMeetingNumbers)
                                                      Text(
                                                        '#${effectiveMeetingNumber(lecture, widget.allLectures)}',
                                                        style: TextStyle(
                                                          fontSize:
                                                              compactTile ? 9 : 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _tryLaunchUrl(BuildContext context, String raw) async {
    var url = raw.trim();
    if (url.isEmpty) return;
    if (!url.contains('://')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.l10n.openLinkFailed)),
        );
      }
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.l10n.openLinkFailed)),
      );
    }
  }

  List<Widget> _resourceEditorSection(
    BuildContext context,
    void Function(void Function()) setLocal,
    Course course,
    Meeting? meeting,
    List<NamedLink> draftMeetingLinks,
  ) {
    final l10n = widget.l10n;
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
          subtitle: Text(
            course.link,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.open_in_new, size: 20),
          onTap: () => _tryLaunchUrl(context, course.link),
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
          subtitle: Text(l.url, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.open_in_new, size: 20),
          onTap: () => _tryLaunchUrl(context, l.url),
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
                  onPressed: () =>
                      setLocal(() => draftMeetingLinks.remove(link)),
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

  void _onGridTap(BuildContext context, Lecture lecture) async {
    final course = courseById(widget.schedule, lecture.courseId);
    final meeting =
        course != null ? meetingForLecture(course, lecture) : null;
    final draftMeetingLinks = <NamedLink>[];
    if (meeting != null) {
      for (final l in meeting.links) {
        draftMeetingLinks.add(NamedLink(title: l.title, url: l.url));
      }
    }
    final options = [
      (LectureStatus.pending, widget.l10n.statusPending),
      (LectureStatus.attended, widget.l10n.markAttended),
      (LectureStatus.watchedRecording, widget.l10n.markWatchedRecording),
      (LectureStatus.missed, widget.l10n.markMissed),
      (LectureStatus.skipped, widget.l10n.markSkipped),
      (LectureStatus.canceled, widget.l10n.markCanceled),
    ];
    var selected = lecture.status;
    var hasRecording = (lecture.recordingLink ?? '').trim().isNotEmpty;
    final ctrl = TextEditingController(text: lecture.recordingLink ?? '');
    final useDialog = Adaptive.isDesktop(context) || Adaptive.isWebLike(context);
    final bool? saved = useDialog
        ? await showDialog<bool>(
            context: context,
            builder: (_) => StatefulBuilder(
              builder: (context, setLocal) => AlertDialog(
                title: Text(widget.l10n.lectureDetailsTitle),
                content: SizedBox(
                  width: 460,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${localizeCourseName(lecture.courseName, widget.l10n)} • ${lecture.type}${widget.schedule.enableMeetingNumbers ? ' • #${effectiveMeetingNumber(lecture, widget.allLectures)}' : ''}',
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<LectureStatus>(
                          initialValue: selected,
                          decoration: InputDecoration(
                            labelText: widget.l10n.statusLabel,
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
                        CheckboxListTile(
                          value: hasRecording,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) => setLocal(() => hasRecording = v!),
                          title: Text(widget.l10n.addRecordingLink),
                        ),
                        if (hasRecording)
                          TextField(
                            controller: ctrl,
                            decoration: InputDecoration(
                              labelText: widget.l10n.recordingLink,
                            ),
                          ),
                        if (course != null)
                          ..._resourceEditorSection(
                            context,
                            setLocal,
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
                    child: Text(widget.l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(widget.l10n.save),
                  ),
                ],
              ),
            ),
          )
        : await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            builder: (_) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: StatefulBuilder(
                  builder: (context, setLocal) => SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${localizeCourseName(lecture.courseName, widget.l10n)} • ${lecture.type}${widget.schedule.enableMeetingNumbers ? ' • #${effectiveMeetingNumber(lecture, widget.allLectures)}' : ''}',
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<LectureStatus>(
                          initialValue: selected,
                          decoration: InputDecoration(
                            labelText: widget.l10n.statusLabel,
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
                        CheckboxListTile(
                          value: hasRecording,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) => setLocal(() => hasRecording = v!),
                          title: Text(widget.l10n.addRecordingLink),
                        ),
                        if (hasRecording)
                          TextField(
                            controller: ctrl,
                            decoration: InputDecoration(
                              labelText: widget.l10n.recordingLink,
                            ),
                          ),
                        if (course != null)
                          ..._resourceEditorSection(
                            context,
                            setLocal,
                            course,
                            meeting,
                            draftMeetingLinks,
                          ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(widget.l10n.save),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
    if (saved == true) {
      widget.onStatus(lecture, selected);
      lecture.recordingLink = hasRecording ? ctrl.text.trim() : null;
      if (course != null && meeting != null) {
        widget.onMeetingLinksSaved(
          course,
          meeting,
          draftMeetingLinks
              .map((l) => NamedLink(title: l.title.trim(), url: l.url.trim()))
              .where((l) => l.title.isNotEmpty || l.url.isNotEmpty)
              .toList(),
        );
      }
      if (mounted) setState(() {});
    }
  }

  int _toMinutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  DateTime _dateForDay(int day, List<int> activeDays) {
    return _currentWeekStart.add(Duration(days: activeDays.indexOf(day)));
  }

  bool _isCurrentWeek() {
    final nowStart =
        weekStartForDate(DateTime.now(), widget.schedule.weekStartsOn);
    return nowStart.year == _currentWeekStart.year &&
        nowStart.month == _currentWeekStart.month &&
        nowStart.day == _currentWeekStart.day;
  }

  DateTime _semesterStartWeek() =>
      weekStartForDate(widget.schedule.startDate, widget.schedule.weekStartsOn);
  DateTime _semesterEndWeek() =>
      weekStartForDate(widget.schedule.endDate, widget.schedule.weekStartsOn);

  bool _canGoPrevWeek() => _currentWeekStart.isAfter(_semesterStartWeek());
  bool _canGoNextWeek() => _currentWeekStart.isBefore(_semesterEndWeek());

  void _goPrevWeek() {
    if (!_canGoPrevWeek()) return;
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _goNextWeek() {
    if (!_canGoNextWeek()) return;
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }

  String _weekRangeLabel(List<int> activeDays) {
    if (activeDays.isEmpty) return '';
    final startDate = _dateForDay(activeDays.first, activeDays);
    final endDate = _dateForDay(activeDays.last, activeDays);
    final semWeek = ((_currentWeekStart
                    .difference(_semesterStartWeek())
                    .inDays) ~/
                7) +
        1;
    return '${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month} • ${widget.l10n.semesterWeekLabel} $semWeek';
  }
}
