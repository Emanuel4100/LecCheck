import 'schedule_models.dart';

String _lecturePreserveKey(DateTime date, String start, String end) =>
    '${date.year}-${date.month}-${date.day}|$start|$end';

/// Rebuilds [course.lectures] from [course.meetings] and semester bounds.
/// Preserves status, recording link, and notes when date/start/end match.
void rebuildLecturesForCourse(Course course, SemesterSchedule schedule) {
  final preserved = <String, (LectureStatus, String?, String)>{};
  for (final l in course.lectures) {
    preserved[_lecturePreserveKey(l.date, l.start, l.end)] =
        (l.status, l.recordingLink, l.notes);
  }

  course.lectures.clear();
  for (final meeting in course.meetings) {
    if (meeting.isOneOff) {
      final date = meeting.specificDate!;
      if (!date.isBefore(schedule.startDate) &&
          !date.isAfter(schedule.endDate)) {
        final k = _lecturePreserveKey(date, meeting.start, meeting.end);
        final p = preserved[k];
        course.lectures.add(
          Lecture(
            courseId: course.id,
            courseName: course.name,
            date: date,
            start: meeting.start,
            end: meeting.end,
            room: meeting.room,
            type: meeting.type,
            color: course.color,
            meetingId: meeting.id,
            status: p?.$1 ?? LectureStatus.pending,
            recordingLink: p?.$2,
            notes: p?.$3 ?? '',
          ),
        );
      }
    } else {
      var date = schedule.startDate;
      while (!date.isAfter(schedule.endDate)) {
        if (date.weekday == meeting.weekday) {
          final k = _lecturePreserveKey(date, meeting.start, meeting.end);
          final p = preserved[k];
          course.lectures.add(
            Lecture(
              courseId: course.id,
              courseName: course.name,
              date: date,
              start: meeting.start,
              end: meeting.end,
              room: meeting.room,
              type: meeting.type,
              color: course.color,
              meetingId: meeting.id,
              status: p?.$1 ?? LectureStatus.pending,
              recordingLink: p?.$2,
              notes: p?.$3 ?? '',
            ),
          );
        }
        date = date.add(const Duration(days: 1));
      }
    }
  }
  course.lectures.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    return a.start.compareTo(b.start);
  });
}

/// Sets [LectureStatus.canceled] for every lecture on dates in [SemesterSchedule.noClassDateKeys].
void applyNoClassDatesToSchedule(SemesterSchedule schedule) {
  for (final c in schedule.courses) {
    for (final l in c.lectures) {
      if (schedule.noClassDateKeys.contains(scheduleDateKey(l.date))) {
        l.status = LectureStatus.canceled;
      }
    }
  }
}
