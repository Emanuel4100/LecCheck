import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/models/schedule_models.dart';
import 'package:flutter_app/models/schedule_serialization.dart';

void main() {
  test('SemesterSchedule round-trip preserves language and NamedLink', () {
    final sch = SemesterSchedule(
      startDate: DateTime(2024, 9, 1),
      endDate: DateTime(2025, 1, 15),
      language: 'he',
    );
    sch.courses.add(
      Course(
        id: 'c1',
        name: 'Algebra',
        lecturer: 'Dr. A',
        color: const Color(0xFF2A7BCC),
        extraLinks: [
          NamedLink(title: 'Syllabus', url: 'https://example.com/s'),
        ],
      ),
    );
    sch.courses.first.meetings.add(
      Meeting(
        weekday: 1,
        start: '10:00',
        end: '11:30',
        room: '101',
        type: 'lecture',
        links: [NamedLink(title: 'Slides', url: 'https://example.com/z')],
      ),
    );

    final root = ScheduleRootState(
      slots: [
        SemesterSlot(id: 's1', name: 'Fall', schedule: sch),
      ],
      activeSemesterId: 's1',
    );

    final json = scheduleRootToJson(
      root,
      savedAtMillis: 1_700_000_000_000,
    );
    final back = scheduleRootFromJson(json)!;

    expect(back.activeSemesterId, 's1');
    final s = back.activeSchedule;
    expect(s.language, 'he');
    expect(s.courses, hasLength(1));
    expect(s.courses.single.extraLinks.single.title, 'Syllabus');
    expect(s.courses.single.meetings.single.links.single.url,
        'https://example.com/z');
  });
}
