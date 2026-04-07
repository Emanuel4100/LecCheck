import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/ui/app_icons.dart';
import '../../l10n/app_localizations.dart';
import '../../models/schedule_models.dart';

Course? courseById(SemesterSchedule schedule, String courseId) {
  for (final c in schedule.courses) {
    if (c.id == courseId) return c;
  }
  return null;
}

/// Resolves the recurring [Meeting] for a grid [Lecture] (by id or weekday+time).
Meeting? meetingForLecture(Course course, Lecture lecture) {
  if (lecture.meetingId != null) {
    for (final m in course.meetings) {
      if (m.id == lecture.meetingId) return m;
    }
  }
  for (final m in course.meetings) {
    if (m.weekday == lecture.date.weekday &&
        m.start == lecture.start &&
        m.end == lecture.end) {
      return m;
    }
  }
  return null;
}

String weekdayLabelL10n(int day, AppLocalizations l10n) {
  switch (day) {
    case 1:
      return l10n.weekdayMonShort;
    case 2:
      return l10n.weekdayTueShort;
    case 3:
      return l10n.weekdayWedShort;
    case 4:
      return l10n.weekdayThuShort;
    case 5:
      return l10n.weekdayFriShort;
    case 6:
      return l10n.weekdaySatShort;
    case 7:
      return l10n.weekdaySunShort;
    default:
      return l10n.dayGeneric;
  }
}

String statusLabelL10n(LectureStatus status, AppLocalizations l10n) {
  switch (status) {
    case LectureStatus.pending:
      return l10n.statusPending;
    case LectureStatus.attended:
      return l10n.statusAttended;
    case LectureStatus.missed:
      return l10n.statusMissed;
    case LectureStatus.skipped:
      return l10n.statusSkipped;
    case LectureStatus.watchedRecording:
      return l10n.statusWatchedRecording;
    case LectureStatus.canceled:
      return l10n.statusCanceled;
  }
}

IconData statusIcon(LectureStatus status) {
  switch (status) {
    case LectureStatus.pending:
      return AppIcons.pending;
    case LectureStatus.attended:
      return AppIcons.attended;
    case LectureStatus.missed:
      return AppIcons.missed;
    case LectureStatus.skipped:
      return AppIcons.skipped;
    case LectureStatus.watchedRecording:
      return AppIcons.watchedRecording;
    case LectureStatus.canceled:
      return Icons.block;
  }
}

Color statusColor(LectureStatus status) {
  switch (status) {
    case LectureStatus.attended:
    case LectureStatus.watchedRecording:
      return Colors.green;
    case LectureStatus.missed:
      return Colors.orange;
    case LectureStatus.skipped:
      return Colors.grey;
    case LectureStatus.canceled:
      return Colors.red;
    case LectureStatus.pending:
      return Colors.blueGrey;
  }
}

IconData meetingTypeIcon(String type, AppLocalizations l10n) {
  if (type == l10n.labType) return AppIcons.meetingLab;
  if (type == l10n.practiceType) return AppIcons.meetingPractice;
  if (type == l10n.otherType) return AppIcons.meetingOther;
  return AppIcons.meetingLecture;
}

String localizeCourseName(String name, AppLocalizations l10n) {
  final hasHebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(name);
  if (l10n.localeName.startsWith('en') && hasHebrew) {
    return transliterateHebrewToLatin(name);
  }
  return name;
}

String transliterateHebrewToLatin(String text) {
  const map = {
    'א': 'a',
    'ב': 'b',
    'ג': 'g',
    'ד': 'd',
    'ה': 'h',
    'ו': 'v',
    'ז': 'z',
    'ח': 'ch',
    'ט': 't',
    'י': 'y',
    'כ': 'k',
    'ך': 'k',
    'ל': 'l',
    'מ': 'm',
    'ם': 'm',
    'נ': 'n',
    'ן': 'n',
    'ס': 's',
    'ע': 'a',
    'פ': 'p',
    'ף': 'p',
    'צ': 'tz',
    'ץ': 'tz',
    'ק': 'k',
    'ר': 'r',
    'ש': 'sh',
    'ת': 't',
    ' ': ' ',
  };
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(map[ch] ?? ch);
  }
  return toBeginningOfSentenceCase(buffer.toString()) ?? buffer.toString();
}

/// Start of the calendar week that contains [date], where weeks start on [weekStartsOn] (1=Mon … 7=Sun).
DateTime weekStartForDate(DateTime date, int weekStartsOn) {
  final delta = (date.weekday - weekStartsOn + 7) % 7;
  return DateTime(date.year, date.month, date.day).subtract(
    Duration(days: delta),
  );
}

/// First instant of the lecture session on its calendar day.
DateTime lectureStartDateTime(Lecture lecture) {
  final parts = lecture.start.split(':');
  return DateTime(
    lecture.date.year,
    lecture.date.month,
    lecture.date.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}

/// End instant of the lecture session on its calendar day.
DateTime lectureEndDateTime(Lecture lecture) {
  final parts = lecture.end.split(':');
  return DateTime(
    lecture.date.year,
    lecture.date.month,
    lecture.date.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}

/// The 7-day window starting the week after the week that contains [now].
({DateTime startInclusive, DateTime endExclusive}) nextWeekRange(
  DateTime now,
  int weekStartsOn,
) {
  final thisWeek = weekStartForDate(now, weekStartsOn);
  final start = thisWeek.add(const Duration(days: 7));
  final end = start.add(const Duration(days: 7));
  return (startInclusive: start, endExclusive: end);
}

/// Extends [nextWeekRange] by one more week when [includeWeekAfter] is true.
({DateTime startInclusive, DateTime endExclusive}) upcomingWeeksRange(
  DateTime now,
  int weekStartsOn, {
  bool includeWeekAfter = false,
}) {
  final base = nextWeekRange(now, weekStartsOn);
  final end = includeWeekAfter
      ? base.endExclusive.add(const Duration(days: 7))
      : base.endExclusive;
  return (startInclusive: base.startInclusive, endExclusive: end);
}

bool lectureStartInRange(
  Lecture lecture,
  DateTime startInclusive,
  DateTime endExclusive,
) {
  final s = lectureStartDateTime(lecture);
  return !s.isBefore(startInclusive) && s.isBefore(endExclusive);
}

Color tileBackgroundForCourse(Color courseColor, BuildContext context) {
  final surface = Theme.of(context).colorScheme.surfaceContainerHighest;
  return Color.alphaBlend(
    courseColor.withValues(alpha: 0.12),
    surface,
  );
}

DateTime _parseTime(String value) {
  final parts = value.split(':');
  final now = DateTime.now();
  return DateTime(
    now.year,
    now.month,
    now.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}

String formatTimeRange(String start, String end, AppLocalizations l10n) {
  final locale = l10n.localeName;
  final fmt = DateFormat.jm(locale);
  return '${fmt.format(_parseTime(start))} - ${fmt.format(_parseTime(end))}';
}

int effectiveMeetingNumber(Lecture lecture, List<Lecture> allLectures) {
  final sameSeries = allLectures
      .where(
        (l) =>
            l.courseId == lecture.courseId &&
            l.type == lecture.type &&
            l.start == lecture.start &&
            l.end == lecture.end,
      )
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  var counter = 0;
  for (final item in sameSeries) {
    if (item.status != LectureStatus.canceled &&
        item.status != LectureStatus.skipped) {
      counter += 1;
    }
    if (identical(item, lecture)) {
      return (item.status == LectureStatus.canceled ||
              item.status == LectureStatus.skipped)
          ? counter + 1
          : counter.clamp(1, 9999);
    }
  }
  return 1;
}
