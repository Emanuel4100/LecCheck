import 'package:flutter/material.dart';

enum LectureStatus {
  pending,
  attended,
  missed,
  skipped,
  watchedRecording,
  canceled,
}

class NamedLink {
  NamedLink({required this.title, required this.url});
  String title;
  String url;
}

class Lecture {
  Lecture({
    required this.courseId,
    required this.courseName,
    required this.date,
    required this.start,
    required this.end,
    required this.room,
    required this.type,
    required this.color,
    this.status = LectureStatus.pending,
    this.recordingLink,
    this.meetingId,
    this.notes = '',
  });
  final String courseId;
  final String courseName;
  final DateTime date;
  final String start;
  final String end;
  final String room;
  final String type;
  final Color color;
  LectureStatus status;
  String? recordingLink;
  final String? meetingId;
  /// Per-occurrence note (this calendar instance).
  String notes;
}

class Meeting {
  Meeting({
    String? id,
    required this.weekday,
    required this.start,
    required this.end,
    required this.room,
    required this.type,
    List<NamedLink>? links,
  })  : id = id ?? _newMeetingId(),
        links = links ?? [];

  static int _idSeq = 0;
  static String _newMeetingId() =>
      'm_${DateTime.now().microsecondsSinceEpoch}_${++_idSeq}';

  final String id;
  int weekday;
  String start;
  String end;
  String room;
  String type;
  final List<NamedLink> links;
}

class Course {
  Course({
    required this.id,
    required this.name,
    required this.lecturer,
    this.code = '',
    this.link = '',
    this.notes = '',
    List<NamedLink>? extraLinks,
    required this.color,
  }) : extraLinks = extraLinks ?? [];

  final String id;
  String name;
  String lecturer;
  String code;
  String link;
  String notes;
  final List<NamedLink> extraLinks;
  Color color;
  final List<Meeting> meetings = [];
  final List<Lecture> lectures = [];
}

/// Immutable snapshot for creating/updating a course from the editor.
class CourseEditorPayload {
  CourseEditorPayload({
    required this.name,
    this.lecturer = '',
    this.code = '',
    this.link = '',
    this.notes = '',
    List<NamedLink>? extraLinks,
    required this.color,
  }) : extraLinks = extraLinks != null
            ? List<NamedLink>.from(
                extraLinks.map(
                  (e) => NamedLink(title: e.title, url: e.url),
                ),
              )
            : [];

  factory CourseEditorPayload.fromCourse(Course c) {
    return CourseEditorPayload(
      name: c.name,
      lecturer: c.lecturer,
      code: c.code,
      link: c.link,
      notes: c.notes,
      extraLinks: c.extraLinks
          .map((e) => NamedLink(title: e.title, url: e.url))
          .toList(),
      color: c.color,
    );
  }

  final String name;
  final String lecturer;
  final String code;
  final String link;
  final String notes;
  final List<NamedLink> extraLinks;
  final Color color;
}

class SemesterSchedule {
  SemesterSchedule({
    required this.startDate,
    required this.endDate,
    required this.language,
    this.weekStartsOn = 1,
    Set<int>? visibleWeekdays,
    this.enableMeetingNumbers = true,
    Set<String>? noClassDateKeys,
    this.use24HourTime = false,
  })  : visibleWeekdays = visibleWeekdays ?? {1, 2, 3, 4, 5, 6, 7},
        noClassDateKeys = noClassDateKeys ?? <String>{};
  DateTime startDate;
  DateTime endDate;
  String language;
  int weekStartsOn;
  Set<int> visibleWeekdays;
  bool enableMeetingNumbers;
  /// Local calendar dates `yyyy-MM-dd` with no class (all meetings canceled).
  Set<String> noClassDateKeys;
  /// When true, show times as 24h; when false, use locale AM/PM (`jm`).
  bool use24HourTime;
  final List<Course> courses = [];
}

/// Stable local date key for [SemesterSchedule.noClassDateKeys].
String scheduleDateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

List<int> orderedWeekdaysForSchedule(SemesterSchedule schedule) {
  final all = orderedWeekdaysFromStart(schedule.weekStartsOn);
  return all.where((d) => schedule.visibleWeekdays.contains(d)).toList();
}

List<int> orderedWeekdaysFromStart(int weekStartsOn) {
  const days = <int>[1, 2, 3, 4, 5, 6, 7];
  final start = days.contains(weekStartsOn) ? weekStartsOn : 1;
  final startIndex = days.indexOf(start);
  return [...days.sublist(startIndex), ...days.sublist(0, startIndex)];
}

String weekdayLabel(int weekday) {
  switch (weekday) {
    case 1:
      return 'Mon';
    case 2:
      return 'Tue';
    case 3:
      return 'Wed';
    case 4:
      return 'Thu';
    case 5:
      return 'Fri';
    case 6:
      return 'Sat';
    case 7:
      return 'Sun';
    default:
      return 'Day';
  }
}
