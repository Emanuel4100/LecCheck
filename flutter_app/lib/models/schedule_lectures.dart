import 'schedule_models.dart';

String _lecturePreserveKey(DateTime date, String start, String end) =>
    '${date.year}-${date.month}-${date.day}|$start|$end';

/// Rebuilds [course.lectures] from [course.meetings] and semester bounds.
/// Preserves [LectureStatus] and [Lecture.recordingLink] when date/start/end match.
void rebuildLecturesForCourse(Course course, SemesterSchedule schedule) {
  final preserved = <String, (LectureStatus, String?)>{};
  for (final l in course.lectures) {
    preserved[_lecturePreserveKey(l.date, l.start, l.end)] =
        (l.status, l.recordingLink);
  }

  course.lectures.clear();
  for (final meeting in course.meetings) {
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
          ),
        );
      }
      date = date.add(const Duration(days: 1));
    }
  }
  course.lectures.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    return a.start.compareTo(b.start);
  });
}
