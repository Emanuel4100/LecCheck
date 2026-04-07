import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/ui/app_icons.dart';
import '../../core/ui/motion_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/schedule_models.dart';
import 'dashboard_utils.dart';

/// Single-pass aggregation for dashboard stats.
class LectureStatsSnapshot {
  LectureStatsSnapshot({
    required this.countAttended,
    required this.countWatchedRecording,
    required this.countMissed,
    required this.countPending,
    required this.countSkipped,
    required this.countCanceled,
    required this.pastAttendedOrWatched,
    required this.pastMissed,
    required this.overduePending,
    required this.upcomingNext7Days,
    required this.thisCalendarWeekUpcoming,
    required this.learningStreakDays,
    required this.perCoursePast,
  });

  final int countAttended;
  final int countWatchedRecording;
  final int countMissed;
  final int countPending;
  final int countSkipped;
  final int countCanceled;
  final int pastAttendedOrWatched;
  final int pastMissed;
  final int overduePending;
  final int upcomingNext7Days;
  final int thisCalendarWeekUpcoming;
  final int learningStreakDays;
  final List<PerCoursePast> perCoursePast;

  static LectureStatsSnapshot build(
    List<Lecture> all,
    int weekStartsOn,
  ) {
    final now = DateTime.now();
    final weekStart = weekStartForDate(now, weekStartsOn);
    final weekEndEx = weekStart.add(const Duration(days: 7));
    final next7Ex = now.add(const Duration(days: 7));

    var countAttended = 0;
    var countWatchedRecording = 0;
    var countMissed = 0;
    var countPending = 0;
    var countSkipped = 0;
    var countCanceled = 0;
    var pastAttendedOrWatched = 0;
    var pastMissed = 0;
    var overduePending = 0;
    var upcomingNext7Days = 0;
    var thisCalendarWeekUpcoming = 0;

    final courseMap = <String, PerCoursePast>{};

    for (final l in all) {
      switch (l.status) {
        case LectureStatus.attended:
          countAttended++;
        case LectureStatus.watchedRecording:
          countWatchedRecording++;
        case LectureStatus.missed:
          countMissed++;
        case LectureStatus.pending:
          countPending++;
        case LectureStatus.skipped:
          countSkipped++;
        case LectureStatus.canceled:
          countCanceled++;
      }

      final end = lectureEndDateTime(l);
      final start = lectureStartDateTime(l);
      final isPast = end.isBefore(now);

      if (isPast) {
        if (l.status == LectureStatus.attended ||
            l.status == LectureStatus.watchedRecording) {
          pastAttendedOrWatched++;
          courseMap
              .putIfAbsent(
                l.courseId,
                () => PerCoursePast(
                  courseId: l.courseId,
                  name: l.courseName,
                  color: l.color,
                ),
              )
              .attended++;
        } else if (l.status == LectureStatus.missed) {
          pastMissed++;
          courseMap
              .putIfAbsent(
                l.courseId,
                () => PerCoursePast(
                  courseId: l.courseId,
                  name: l.courseName,
                  color: l.color,
                ),
              )
              .missed++;
        }
      }

      if (isPast &&
          l.status == LectureStatus.pending) {
        overduePending++;
      }

      if (start.isAfter(now) && start.isBefore(next7Ex)) {
        upcomingNext7Days++;
      }
      if (start.isAfter(now) &&
          !start.isBefore(weekStart) &&
          start.isBefore(weekEndEx)) {
        thisCalendarWeekUpcoming++;
      }
    }

    final streak = _learningStreakDays(all, now);
    final perCourseList = courseMap.values.toList()
      ..sort(
        (a, b) =>
            (b.attended + b.missed).compareTo(a.attended + a.missed),
      );

    return LectureStatsSnapshot(
      countAttended: countAttended,
      countWatchedRecording: countWatchedRecording,
      countMissed: countMissed,
      countPending: countPending,
      countSkipped: countSkipped,
      countCanceled: countCanceled,
      pastAttendedOrWatched: pastAttendedOrWatched,
      pastMissed: pastMissed,
      overduePending: overduePending,
      upcomingNext7Days: upcomingNext7Days,
      thisCalendarWeekUpcoming: thisCalendarWeekUpcoming,
      learningStreakDays: streak,
      perCoursePast: perCourseList,
    );
  }

  /// Consecutive calendar days ending at [now] with at least one attended or
  /// watched recording on that day.
  static int _learningStreakDays(List<Lecture> all, DateTime now) {
    var day = DateTime(now.year, now.month, now.day);
    var streak = 0;
    for (var i = 0; i < 400; i++) {
      final hit = all.any((l) {
        if (l.status != LectureStatus.attended &&
            l.status != LectureStatus.watchedRecording) {
          return false;
        }
        final d = l.date;
        return d.year == day.year &&
            d.month == day.month &&
            d.day == day.day;
      });
      if (!hit) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

class PerCoursePast {
  PerCoursePast({
    required this.courseId,
    required this.name,
    required this.color,
  });

  final String courseId;
  final String name;
  final Color color;
  int attended = 0;
  int missed = 0;
}

class StatsTab extends StatelessWidget {
  const StatsTab({
    super.key,
    required this.schedule,
    required this.allLectures,
    required this.attendance,
    required this.l10n,
  });

  final SemesterSchedule schedule;
  final List<Lecture> allLectures;
  final double attendance;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final snap = LectureStatsSnapshot.build(
      allLectures,
      schedule.weekStartsOn,
    );
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: attendance),
          duration: MotionTokens.slow,
          curve: MotionTokens.standardCurve,
          builder: (context, value, _) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      l10n.statsAttendanceHeroTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 120,
                            width: 120,
                            child: CircularProgressIndicator(
                              value: value,
                              strokeWidth: 10,
                              backgroundColor: cs.surfaceContainerHighest,
                              color: cs.primary,
                            ),
                          ),
                          Text(
                            '${(value * 100).round()}%',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.statsAttendanceHeroSubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _MetricRow(
          icon: Icons.local_fire_department_outlined,
          label: l10n.statsStreakLabel,
          value: '${snap.learningStreakDays}',
          color: Colors.deepOrange,
        ),
        _MetricRow(
          icon: Icons.warning_amber_outlined,
          label: l10n.statsOverduePendingLabel,
          value: '${snap.overduePending}',
          color: cs.error,
        ),
        _MetricRow(
          icon: Icons.date_range,
          label: l10n.statsThisWeekUpcomingLabel,
          value: '${snap.thisCalendarWeekUpcoming}',
          color: cs.secondary,
        ),
        _MetricRow(
          icon: Icons.upcoming,
          label: l10n.statsNext7DaysLabel,
          value: '${snap.upcomingNext7Days}',
          color: cs.tertiary,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.statsStatusMixTitle,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _StatusPieChart(snapshot: snap, l10n: l10n),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.statsPerCourseTitle,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _LegendDot(color: Colors.green, label: l10n.statsBarLegendAttended),
                      const SizedBox(width: 16),
                      _LegendDot(color: Colors.orange, label: l10n.statsBarLegendMissed),
                    ],
                  ),
                  Expanded(
                    child: _CourseBarChart(
                      courses: snap.perCoursePast.take(6).toList(),
                      l10n: l10n,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _SummaryTiles(snapshot: snap, l10n: l10n),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _StatusPieChart extends StatelessWidget {
  const _StatusPieChart({
    required this.snapshot,
    required this.l10n,
  });

  final LectureStatsSnapshot snapshot;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final data = <_PieSeg>[
      _PieSeg(
        snapshot.countAttended.toDouble(),
        l10n.attended,
        Colors.green,
      ),
      _PieSeg(
        snapshot.countWatchedRecording.toDouble(),
        l10n.statusWatchedRecording,
        Colors.teal,
      ),
      _PieSeg(snapshot.countMissed.toDouble(), l10n.missed, Colors.orange),
      _PieSeg(snapshot.countPending.toDouble(), l10n.pending, Colors.blueGrey),
      _PieSeg(snapshot.countSkipped.toDouble(), l10n.skipped, Colors.grey),
      _PieSeg(
        snapshot.countCanceled.toDouble(),
        l10n.statusCanceled,
        Colors.red,
      ),
    ].where((e) => e.value > 0).toList();

    if (data.isEmpty) {
      return Center(child: Text(l10n.statsNoDataYet));
    }

    final total = data.fold<double>(0, (a, b) => a + b.value);
    if (total <= 0) {
      return Center(child: Text(l10n.statsNoDataYet));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 44,
        sections: data.map((s) {
          final pct = (s.value / total * 100).round();
          return PieChartSectionData(
            color: s.color,
            value: s.value,
            title: '$pct%',
            radius: 58,
            titleStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: s.color.computeLuminance() > 0.55
                  ? Colors.black87
                  : Colors.white,
            ),
            badgePositionPercentageOffset: 1.2,
          );
        }).toList(),
      ),
    );
  }
}

class _PieSeg {
  _PieSeg(this.value, this.label, this.color);
  final double value;
  final String label;
  final Color color;
}

class _CourseBarChart extends StatelessWidget {
  const _CourseBarChart({
    required this.courses,
    required this.l10n,
  });

  final List<PerCoursePast> courses;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return Center(child: Text(l10n.statsNoCourseBars));
    }

    final maxY = courses
        .map((c) => (c.attended + c.missed).toDouble())
        .fold<double>(1, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.15,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= courses.length) return const SizedBox();
                final name = courses[i].name;
                final short =
                    name.length > 6 ? '${name.substring(0, 6)}…' : name;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    short,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(courses.length, (i) {
          final c = courses[i];
          final total = c.attended + c.missed;
          return BarChartGroupData(
            x: i,
            barRods: [
              if (total == 0)
                BarChartRodData(
                  toY: 0.01,
                  color: Colors.grey.shade300,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                )
              else
                BarChartRodData(
                  toY: total.toDouble(),
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                  rodStackItems: [
                    BarChartRodStackItem(
                      0,
                      c.missed.toDouble(),
                      Colors.orange,
                    ),
                    BarChartRodStackItem(
                      c.missed.toDouble(),
                      total.toDouble(),
                      Colors.green,
                    ),
                  ],
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _SummaryTiles extends StatelessWidget {
  const _SummaryTiles({
    required this.snapshot,
    required this.l10n,
  });

  final LectureStatsSnapshot snapshot;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(AppIcons.attendance),
            title: Text(l10n.statsPastDecidedLabel),
            subtitle: Text(
              '${l10n.attended} + ${l10n.statusWatchedRecording}: ${snapshot.pastAttendedOrWatched} • ${l10n.missed}: ${snapshot.pastMissed}',
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(AppIcons.attended, color: Colors.green),
            title: Text(l10n.attended),
            trailing: Text('${snapshot.countAttended}'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(AppIcons.watchedRecording, color: Colors.teal),
            title: Text(l10n.statusWatchedRecording),
            trailing: Text('${snapshot.countWatchedRecording}'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(AppIcons.missed, color: Colors.red),
            title: Text(l10n.missed),
            trailing: Text('${snapshot.countMissed}'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(AppIcons.pending),
            title: Text(l10n.pending),
            trailing: Text('${snapshot.countPending}'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(AppIcons.skipped),
            title: Text(l10n.skipped),
            trailing: Text('${snapshot.countSkipped}'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.block, color: Colors.orange),
            title: Text(l10n.statusCanceled),
            trailing: Text('${snapshot.countCanceled}'),
          ),
        ),
      ],
    );
  }
}
