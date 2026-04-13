import 'package:flutter/material.dart';

import '../../core/platform/adaptive.dart';
import '../../l10n/app_localizations.dart';
import '../../models/schedule_models.dart';
import 'dashboard_utils.dart';
import 'lecture_detail_sheet.dart';

class WeeklyTab extends StatefulWidget {
  const WeeklyTab({
    super.key,
    required this.schedule,
    required this.allLectures,
    required this.attendance,
    required this.weekSyncToken,
    required this.onStatus,
    required this.onMeetingLinksSaved,
    required this.onMarkNoClassDay,
    required this.onClearNoClassDay,
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
  /// Add [date] (date-only) to no-class set and cancel all lectures that day.
  final void Function(DateTime date) onMarkNoClassDay;
  /// Remove [date] from no-class set and reset lectures that day to pending.
  final void Function(DateTime date) onClearNoClassDay;
  final AppLocalizations l10n;

  @override
  State<WeeklyTab> createState() => _WeeklyTabState();
}

class _WeeklyTabState extends State<WeeklyTab> {
  late DateTime _currentWeekStart;
  double _gridScale = 1.0;
  double _pinchBaseScale = 1.0;

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
    final usePinchZoom =
        !Adaptive.isDesktop(context) && !Adaptive.isTablet(context);
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
        if (usePinchZoom) ...[
          const SizedBox(height: 2),
          Text(
            widget.l10n.gridPinchZoomHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        const SizedBox(height: 8),
        LinearProgressIndicator(value: widget.attendance),
        const SizedBox(height: 12),
        Expanded(
          child: usePinchZoom
              ? GestureDetector(
                  onScaleStart: (_) =>
                      _pinchBaseScale = _gridScale.clamp(0.65, 1.45),
                  onScaleUpdate: (details) {
                    if (details.scale == 1.0) return;
                    final next =
                        (_pinchBaseScale * details.scale).clamp(0.65, 1.45);
                    if ((next - _gridScale).abs() > 0.002) {
                      setState(() => _gridScale = next);
                    }
                  },
                  onDoubleTap: () {
                    if ((_gridScale - 1.0).abs() > 0.01) {
                      setState(() => _gridScale = 1.0);
                    }
                  },
                  child: _buildGrid(context, activeDays),
                )
              : _buildGrid(context, activeDays),
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
        final desktop = Adaptive.isDesktop(context);
        final minCellWidth = desktop
            ? 240.0
            : Adaptive.isTablet(context)
                ? 180.0
                : 72.0;
        final maxCellWidth = desktop ? double.infinity : 320.0;
        final availW =
            (constraints.maxWidth - timeAxisWidth).clamp(1.0, double.infinity);
        final baseCell =
            (availW / columns).clamp(minCellWidth, maxCellWidth) * _gridScale;
        final cellWidth = baseCell;
        final maxHourH = desktop ? 80.0 : 64.0;
        final hourHeight = ((constraints.maxHeight - dayHeaderHeight) /
                    totalHours)
                .clamp(32.0, maxHourH) *
            _gridScale;
        final gridHeight = hourHeight * totalHours;
        final compactTile = cellWidth < 120;
        final titleOnlyTile = cellWidth < 96;
        final isCurrentWeek = _isCurrentWeek();
        final now = DateTime.now();
        final nowTop =
            (((now.hour * 60 + now.minute) - (8 * 60)) / 60.0) * hourHeight;
        final endD = widget.schedule.endDate;
        Widget grid = SingleChildScrollView(
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
                          final label = formatHourLabel(
                            hour,
                            widget.l10n,
                            use24HourTime: widget.schedule.use24HourTime,
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
                    final colDate = _dateForDay(day, activeDays);
                    final afterSem = colDate.isAfter(endD);
                    final isSemesterEndDay = colDate.year == endD.year &&
                        colDate.month == endD.month &&
                        colDate.day == endD.day;
                    final noClassKey = scheduleDateKey(colDate);
                    final markedNoClass = widget.schedule.noClassDateKeys
                        .contains(noClassKey);
                    final rawItems = byDay[day] ?? const <Lecture>[];
                    final items = rawItems
                        .where((l) => !l.date.isAfter(endD))
                        .toList();
                    return SizedBox(
                      width: cellWidth,
                      child: Column(
                        children: [
                          Material(
                            color: afterSem
                                ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.85)
                                : Colors.transparent,
                            child: InkWell(
                              onTap: afterSem
                                  ? null
                                  : () => _onDayHeaderTap(context, colDate),
                              child: Builder(
                                builder: (ctx) {
                                  Widget inner = Container(
                                    height: dayHeaderHeight,
                                    decoration: BoxDecoration(
                                      border: isSemesterEndDay
                                          ? Border(
                                              top: BorderSide(
                                                color: Theme.of(ctx)
                                                    .colorScheme
                                                    .tertiary,
                                                width: 3,
                                              ),
                                            )
                                          : null,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (markedNoClass)
                                            Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .only(end: 2),
                                              child: Icon(
                                                Icons.event_busy,
                                                size: compactTile ? 11 : 13,
                                              ),
                                            ),
                                          Flexible(
                                            child: Text(
                                              afterSem
                                                  ? widget
                                                      .l10n.afterSemesterShort
                                                  : '${weekdayLabelL10n(day, widget.l10n)} ${colDate.day}/${colDate.month}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: compactTile ? 10 : 12,
                                              ),
                                              maxLines: 2,
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                  if (isSemesterEndDay && !afterSem) {
                                    inner = Tooltip(
                                      message:
                                          widget.l10n.semesterEndsThisDay,
                                      child: inner,
                                    );
                                  }
                                  return inner;
                                },
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
                                      colDate.year == now.year &&
                                      colDate.month == now.month &&
                                      colDate.day == now.day)
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
                                        ((startM - (8 * 60)) / 60.0) *
                                            hourHeight;
                                    final height = ((endM - startM) / 60.0) *
                                        hourHeight;
                                    final maxTileH = desktop
                                        ? gridHeight - top.clamp(0, gridHeight - 30)
                                        : (hourHeight * 6).clamp(48.0, 200.0);
                                    return Positioned(
                                      left: compactTile ? 2 : 6,
                                      right: compactTile ? 2 : 6,
                                      top: top.clamp(0, gridHeight - 24),
                                      height: height.clamp(30, maxTileH),
                                      child: GestureDetector(
                                        onTap: () =>
                                            _onGridTap(context, lecture),
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
                                              color:
                                                  statusColor(lecture.status),
                                              width: 1.2,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          clipBehavior: Clip.hardEdge,
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              return FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.topLeft,
                                                child: ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    maxWidth:
                                                        constraints.maxWidth,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      if (!titleOnlyTile)
                                                        Container(
                                                          width: double.infinity,
                                                          height: 4,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: statusColor(
                                                                lecture
                                                                    .status),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        3),
                                                          ),
                                                        ),
                                                      if (!titleOnlyTile)
                                                        SizedBox(
                                                            height: compactTile
                                                                ? 2
                                                                : 4),
                                                      FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        alignment:
                                                            Alignment.topLeft,
                                                        child: Text(
                                                          localizeCourseName(
                                                            lecture.courseName,
                                                            widget.l10n,
                                                          ),
                                                          maxLines:
                                                              titleOnlyTile
                                                                  ? 1
                                                                  : 2,
                                                          softWrap: true,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize:
                                                                titleOnlyTile
                                                                    ? 10
                                                                    : (compactTile
                                                                        ? 9
                                                                        : 11),
                                                            height: 1.1,
                                                          ),
                                                        ),
                                                      ),
                                                      if (!titleOnlyTile) ...[
                                                        Text(
                                                          formatTimeRange(
                                                            lecture.start,
                                                            lecture.end,
                                                            widget.l10n,
                                                            use24HourTime:
                                                                widget.schedule
                                                                    .use24HourTime,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize:
                                                                compactTile
                                                                    ? 9
                                                                    : 11,
                                                          ),
                                                        ),
                                                        if (widget.schedule
                                                            .enableMeetingNumbers)
                                                          Text(
                                                            '#${effectiveMeetingNumber(lecture, widget.allLectures)}',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  compactTile
                                                                      ? 9
                                                                      : 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                      ],
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
        return grid;
      },
    );
  }

  Future<void> _onGridTap(BuildContext context, Lecture lecture) async {
    await showLectureDetailEditor(
      context,
      schedule: widget.schedule,
      lecture: lecture,
      allLectures: widget.allLectures,
      l10n: widget.l10n,
      onStatus: widget.onStatus,
      onMeetingLinksSaved: widget.onMeetingLinksSaved,
    );
    if (mounted) setState(() {});
  }

  Future<void> _onDayHeaderTap(BuildContext context, DateTime columnDate) async {
    final key = scheduleDateKey(columnDate);
    final marked = widget.schedule.noClassDateKeys.contains(key);
    final l10n = widget.l10n;
    final useDialog = Adaptive.isDesktop(context) || Adaptive.isWebLike(context);
    final pick = useDialog
        ? await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.dayOptionsTitle),
              content: Text(
                formatLectureDateMedium(columnDate, l10n),
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                if (marked)
                  FilledButton.tonal(
                    onPressed: () => Navigator.pop(ctx, 'clear'),
                    child: Text(l10n.clearNoClassDay),
                  ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, 'mark'),
                  child: Text(l10n.markNoClassDay),
                ),
              ],
            ),
          )
        : await showModalBottomSheet<String>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    title: Text(l10n.dayOptionsTitle),
                    subtitle: Text(formatLectureDateMedium(columnDate, l10n)),
                  ),
                  if (marked)
                    ListTile(
                      leading: const Icon(Icons.event_available_outlined),
                      title: Text(l10n.clearNoClassDay),
                      onTap: () => Navigator.pop(ctx, 'clear'),
                    ),
                  ListTile(
                    leading: const Icon(Icons.event_busy),
                    title: Text(l10n.markNoClassDay),
                    subtitle: Text(l10n.markNoClassDaySubtitle),
                    onTap: () => Navigator.pop(ctx, 'mark'),
                  ),
                ],
              ),
            ),
          );
    if (!context.mounted) return;
    if (pick == 'mark') {
      widget.onMarkNoClassDay(columnDate);
      if (mounted) setState(() {});
    } else if (pick == 'clear') {
      widget.onClearNoClassDay(columnDate);
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
