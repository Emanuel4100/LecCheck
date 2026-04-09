import 'package:flutter/material.dart';

import 'schedule_models.dart';

const int kScheduleBundleVersion = 1;
const int kRootBundleVersion = 2;

int _colorToArgb(Color c) {
  final a = (c.a * 255.0).round() & 0xff;
  final r = (c.r * 255.0).round() & 0xff;
  final g = (c.g * 255.0).round() & 0xff;
  final b = (c.b * 255.0).round() & 0xff;
  return (a << 24) | (r << 16) | (g << 8) | b;
}

Color _colorFromArgb(int v) => Color(v);

String _lectureStatusName(LectureStatus s) => s.name;

LectureStatus _lectureStatusFromName(String? raw) {
  if (raw == null) return LectureStatus.pending;
  return LectureStatus.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => LectureStatus.pending,
  );
}

Map<String, dynamic> _namedLinkToJson(NamedLink l) => {
      'title': l.title,
      'url': l.url,
    };

NamedLink _namedLinkFromJson(Map<String, dynamic> m) => NamedLink(
      title: m['title'] as String? ?? '',
      url: m['url'] as String? ?? '',
    );

Map<String, dynamic> _meetingToJson(Meeting m) => {
      'id': m.id,
      'weekday': m.weekday,
      'start': m.start,
      'end': m.end,
      'room': m.room,
      'type': m.type,
      'links': m.links.map(_namedLinkToJson).toList(),
    };

Meeting _meetingFromJson(Map<String, dynamic> m) => Meeting(
      id: m['id'] as String?,
      weekday: (m['weekday'] as num?)?.toInt() ?? 1,
      start: m['start'] as String? ?? '',
      end: m['end'] as String? ?? '',
      room: m['room'] as String? ?? '',
      type: m['type'] as String? ?? '',
      links: (m['links'] as List<dynamic>?)
              ?.map((e) => _namedLinkFromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );

Map<String, dynamic> _lectureToJson(Lecture l) => {
      'courseId': l.courseId,
      'courseName': l.courseName,
      'date': l.date.toIso8601String(),
      'start': l.start,
      'end': l.end,
      'room': l.room,
      'type': l.type,
      'color': _colorToArgb(l.color),
      'status': _lectureStatusName(l.status),
      'recordingLink': l.recordingLink,
      'meetingId': l.meetingId,
      if (l.notes.isNotEmpty) 'notes': l.notes,
    };

Lecture _lectureFromJson(Map<String, dynamic> m) {
  final dateRaw = m['date'] as String?;
  final date = dateRaw != null
      ? DateTime.tryParse(dateRaw) ?? DateTime.now()
      : DateTime.now();
  return Lecture(
    courseId: m['courseId'] as String? ?? '',
    courseName: m['courseName'] as String? ?? '',
    date: DateTime(date.year, date.month, date.day),
    start: m['start'] as String? ?? '',
    end: m['end'] as String? ?? '',
    room: m['room'] as String? ?? '',
    type: m['type'] as String? ?? '',
    color: _colorFromArgb((m['color'] as num?)?.toInt() ?? 0xFF2A7BCC),
    status: _lectureStatusFromName(m['status'] as String?),
    recordingLink: m['recordingLink'] as String?,
    meetingId: m['meetingId'] as String?,
    notes: m['notes'] as String? ?? '',
  );
}

Map<String, dynamic> _courseToJson(Course c) => {
      'id': c.id,
      'name': c.name,
      'lecturer': c.lecturer,
      'code': c.code,
      'link': c.link,
      'notes': c.notes,
      'color': _colorToArgb(c.color),
      'extraLinks': c.extraLinks.map(_namedLinkToJson).toList(),
      'meetings': c.meetings.map(_meetingToJson).toList(),
      'lectures': c.lectures.map(_lectureToJson).toList(),
    };

Course _courseFromJson(Map<String, dynamic> m) {
  final course = Course(
    id: m['id'] as String? ?? '',
    name: m['name'] as String? ?? '',
    lecturer: m['lecturer'] as String? ?? '',
    code: m['code'] as String? ?? '',
    link: m['link'] as String? ?? '',
    notes: m['notes'] as String? ?? '',
    color: _colorFromArgb((m['color'] as num?)?.toInt() ?? 0xFF2A7BCC),
    extraLinks: (m['extraLinks'] as List<dynamic>?)
            ?.map((e) => _namedLinkFromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [],
  );
  final meetings = m['meetings'] as List<dynamic>? ?? [];
  for (final e in meetings) {
    course.meetings.add(_meetingFromJson(Map<String, dynamic>.from(e as Map)));
  }
  final lectures = m['lectures'] as List<dynamic>? ?? [];
  for (final e in lectures) {
    course.lectures.add(_lectureFromJson(Map<String, dynamic>.from(e as Map)));
  }
  _sortLectures(course.lectures);
  return course;
}

void _sortLectures(List<Lecture> lectures) {
  lectures.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    return a.start.compareTo(b.start);
  });
}

Map<String, dynamic> _semesterPayloadToJson(SemesterSchedule schedule) {
  return {
    'startDate': schedule.startDate.toIso8601String(),
    'endDate': schedule.endDate.toIso8601String(),
    'language': schedule.language,
    'weekStartsOn': schedule.weekStartsOn,
    'visibleWeekdays': schedule.visibleWeekdays.toList()..sort(),
    'enableMeetingNumbers': schedule.enableMeetingNumbers,
    'noClassDates': schedule.noClassDateKeys.toList()..sort(),
    'use24HourTime': schedule.use24HourTime,
    'courses': schedule.courses.map(_courseToJson).toList(),
  };
}

SemesterSchedule? _semesterScheduleFromPayloadMap(Map<String, dynamic> raw) {
  final start = DateTime.tryParse(raw['startDate'] as String? ?? '');
  final end = DateTime.tryParse(raw['endDate'] as String? ?? '');
  if (start == null || end == null) return null;

  final schedule = SemesterSchedule(
    startDate: DateTime(start.year, start.month, start.day),
    endDate: DateTime(end.year, end.month, end.day),
    language: raw['language'] as String? ?? 'en',
    weekStartsOn: (raw['weekStartsOn'] as num?)?.toInt() ?? 1,
    visibleWeekdays: (raw['visibleWeekdays'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toSet() ??
        {1, 2, 3, 4, 5, 6, 7},
    enableMeetingNumbers: raw['enableMeetingNumbers'] as bool? ?? true,
    noClassDateKeys: (raw['noClassDates'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toSet() ??
        <String>{},
    use24HourTime: raw['use24HourTime'] as bool? ?? false,
  );

  final courses = raw['courses'] as List<dynamic>? ?? [];
  for (final e in courses) {
    schedule.courses.add(_courseFromJson(Map<String, dynamic>.from(e as Map)));
  }
  return schedule;
}

Map<String, dynamic> _semesterSlotToJson(SemesterSlot slot) {
  return {
    'id': slot.id,
    'name': slot.name,
    ..._semesterPayloadToJson(slot.schedule),
  };
}

SemesterSlot? _semesterSlotFromJson(Map<String, dynamic> raw) {
  final id = raw['id'] as String? ?? '';
  if (id.isEmpty) return null;
  final name = raw['name'] as String? ?? 'Semester';
  final sch = _semesterScheduleFromPayloadMap(raw);
  if (sch == null) return null;
  return SemesterSlot(id: id, name: name, schedule: sch);
}

/// v2 root: multiple semesters + active id. Use for local file and Firestore.
Map<String, dynamic> scheduleRootToJson(
  ScheduleRootState root, {
  required int savedAtMillis,
}) {
  return {
    'v': kRootBundleVersion,
    'savedAt': savedAtMillis,
    'activeSemesterId': root.activeSemesterId,
    'semesters': root.slots.map(_semesterSlotToJson).toList(),
  };
}

/// Parses v2 root or migrates legacy v1 single-semester file.
ScheduleRootState? scheduleRootFromJson(Map<String, dynamic>? raw) {
  if (raw == null) return null;
  final v = (raw['v'] as num?)?.toInt() ?? 0;
  if (v == kRootBundleVersion) {
    final activeId = raw['activeSemesterId'] as String? ?? '';
    final list = raw['semesters'] as List<dynamic>? ?? [];
    final slots = <SemesterSlot>[];
    for (final e in list) {
      final slot = _semesterSlotFromJson(Map<String, dynamic>.from(e as Map));
      if (slot != null) slots.add(slot);
    }
    if (slots.isEmpty) return null;
    var active = activeId;
    if (!slots.any((s) => s.id == active)) {
      active = slots.first.id;
    }
    return ScheduleRootState(slots: slots, activeSemesterId: active);
  }
  if (v == kScheduleBundleVersion) {
    final sch = _semesterScheduleFromPayloadMap(raw);
    if (sch == null) return null;
    const id = 'semester_1';
    return ScheduleRootState(
      slots: [SemesterSlot(id: id, name: 'Semester', schedule: sch)],
      activeSemesterId: id,
    );
  }
  return null;
}

/// Writes a single semester as a v2 root (one slot). Prefer [scheduleRootToJson] when possible.
Map<String, dynamic> scheduleBundleToJson(
  SemesterSchedule schedule, {
  required int savedAtMillis,
}) {
  return scheduleRootToJson(
    ScheduleRootState(
      slots: [
        SemesterSlot(
          id: 'semester_1',
          name: 'Semester',
          schedule: schedule,
        ),
      ],
      activeSemesterId: 'semester_1',
    ),
    savedAtMillis: savedAtMillis,
  );
}

/// Active semester only; use [scheduleRootFromJson] when you need all slots.
SemesterSchedule? scheduleBundleFromJson(Map<String, dynamic>? raw) {
  return scheduleRootFromJson(raw)?.activeSchedule;
}

int? scheduleBundleSavedAt(Map<String, dynamic>? raw) {
  if (raw == null) return null;
  return (raw['savedAt'] as num?)?.toInt();
}
