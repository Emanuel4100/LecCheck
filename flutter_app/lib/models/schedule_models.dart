import 'package:flutter/material.dart';

enum LectureStatus { pending, attended, missed, canceled }

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
}

class Meeting {
  Meeting({
    required this.weekday,
    required this.start,
    required this.end,
    required this.room,
    required this.type,
  });
  final int weekday;
  final String start;
  final String end;
  final String room;
  final String type;
}

class Course {
  Course({
    required this.id,
    required this.name,
    required this.lecturer,
    this.code = '',
    this.link = '',
    required this.color,
  });
  final String id;
  final String name;
  final String lecturer;
  final String code;
  final String link;
  final Color color;
  final List<Meeting> meetings = [];
  final List<Lecture> lectures = [];
}

class SemesterSchedule {
  SemesterSchedule({
    required this.startDate,
    required this.endDate,
    required this.language,
    this.weekStartsOn = 1,
    this.showWeekend = true,
    this.enableMeetingNumbers = false,
  });
  DateTime startDate;
  DateTime endDate;
  String language;
  int weekStartsOn;
  bool showWeekend;
  bool enableMeetingNumbers;
  final List<Course> courses = [];
}

List<int> orderedWeekdaysForSchedule(SemesterSchedule schedule) {
  final all = schedule.weekStartsOn == 7
      ? <int>[7, 1, 2, 3, 4, 5, 6]
      : <int>[1, 2, 3, 4, 5, 6, 7];
  if (schedule.showWeekend) return all;
  return all.where((d) => d >= 1 && d <= 5).toList();
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
