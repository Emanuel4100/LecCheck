import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/schedule_models.dart';

class CourseSetupScreen extends StatefulWidget {
  const CourseSetupScreen({
    super.key,
    required this.schedule,
    required this.onAddCourse,
    required this.onAddMeeting,
    required this.onContinue,
    required this.onBack,
  });

  final SemesterSchedule schedule;
  final Course? Function(String, String, String, String, Color) onAddCourse;
  final void Function(Course, Meeting) onAddMeeting;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  State<CourseSetupScreen> createState() => _CourseSetupScreenState();
}

class _CourseSetupScreenState extends State<CourseSetupScreen> {
  Future<void> _openAddDialog() async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final lecturerCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    bool hasLecturer = false;
    bool hasLink = false;
    final meetings = <Meeting>[];
    const meetingTypes = ['Lecture', 'Practice', 'Lab', 'Other'];
    String sessionType = meetingTypes.first;
    int weekday = 1;
    final startTimes = _timeOptions();
    String start = startTimes[4];
    int durationMinutes = 60;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Add Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Course name'),
                ),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Course code'),
                ),
                CheckboxListTile(
                  value: hasLecturer,
                  onChanged: (v) => setLocal(() => hasLecturer = v ?? false),
                  title: const Text('Add lecturer'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (hasLecturer)
                  TextField(
                    controller: lecturerCtrl,
                    decoration: const InputDecoration(labelText: 'Lecturer'),
                  ),
                CheckboxListTile(
                  value: hasLink,
                  onChanged: (v) => setLocal(() => hasLink = v ?? false),
                  title: const Text('Add course link'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (hasLink)
                  TextField(
                    controller: linkCtrl,
                    decoration: const InputDecoration(labelText: 'Link'),
                  ),
                const Divider(height: 24),
                Text(
                  'Add weekly sessions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                DropdownButtonFormField<String>(
                  initialValue: sessionType,
                  decoration: const InputDecoration(labelText: 'Session type'),
                  items: meetingTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) =>
                      setLocal(() => sessionType = v ?? meetingTypes.first),
                ),
                DropdownButtonFormField<int>(
                  initialValue: weekday,
                  decoration: const InputDecoration(labelText: 'Weekday'),
                  items: List.generate(
                    7,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(
                        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
                      ),
                    ),
                  ),
                  onChanged: (v) => setLocal(() => weekday = v ?? 1),
                ),
                DropdownButtonFormField<String>(
                  initialValue: start,
                  decoration: const InputDecoration(labelText: 'Start time'),
                  items: startTimes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setLocal(() => start = v ?? start),
                ),
                DropdownButtonFormField<int>(
                  initialValue: durationMinutes,
                  decoration: const InputDecoration(labelText: 'Length'),
                  items: const [
                    DropdownMenuItem(value: 30, child: Text('30 min')),
                    DropdownMenuItem(value: 60, child: Text('60 min')),
                    DropdownMenuItem(value: 90, child: Text('90 min')),
                    DropdownMenuItem(value: 120, child: Text('120 min')),
                    DropdownMenuItem(value: 150, child: Text('150 min')),
                    DropdownMenuItem(value: 180, child: Text('180 min')),
                  ],
                  onChanged: (v) => setLocal(() => durationMinutes = v ?? 60),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      meetings.add(
                        Meeting(
                          weekday: weekday,
                          start: start,
                          end: _endFromStartAndDuration(start, durationMinutes),
                          room: '',
                          type: sessionType,
                        ),
                      );
                      setLocal(() {});
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add session'),
                  ),
                ),
                if (meetings.isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('No sessions added yet.'),
                  ),
                ...meetings.asMap().entries.map((entry) {
                  final index = entry.key;
                  final meeting = entry.value;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${meeting.type} - ${_weekdayLabel(meeting.weekday)}',
                    ),
                    subtitle: Text(
                      '${meeting.start} - ${meeting.end} (${_durationText(meeting.start, meeting.end)})',
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        meetings.removeAt(index);
                        setLocal(() {});
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || meetings.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Add course name and at least one session.',
                      ),
                    ),
                  );
                  return;
                }
                final color =
                    Colors.primaries[Random().nextInt(Colors.primaries.length)];
                final course = widget.onAddCourse(
                  nameCtrl.text.trim(),
                  hasLecturer ? lecturerCtrl.text.trim() : '',
                  codeCtrl.text.trim(),
                  hasLink ? linkCtrl.text.trim() : '',
                  color,
                );
                if (course != null) {
                  for (final meeting in meetings) {
                    widget.onAddMeeting(course, meeting);
                  }
                }
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courses = widget.schedule.courses;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Setup Courses'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add your courses for this semester',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: courses.isEmpty
                  ? const Center(
                      child: Text('No courses yet. Add your first course.'),
                    )
                  : ListView.builder(
                      itemCount: courses.length,
                      itemBuilder: (_, i) {
                        final c = courses[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: c.color),
                            title: Text(c.name),
                            subtitle: Text(
                              [
                                if (c.code.isNotEmpty) 'Code: ${c.code}',
                                if (c.lecturer.isNotEmpty)
                                  'Lecturer: ${c.lecturer}',
                              ].join(' • '),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _openAddDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add course'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: widget.onContinue,
                  child: const Text('Continue'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static List<String> _timeOptions() {
    final options = <String>[];
    for (var h = 8; h <= 23; h++) {
      options.add('${h.toString().padLeft(2, '0')}:00');
      if (h < 23) {
        options.add('${h.toString().padLeft(2, '0')}:30');
      }
    }
    return options;
  }

  static int _toMinutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String _endFromStartAndDuration(String start, int durationMinutes) {
    final total = (_toMinutes(start) + durationMinutes).clamp(0, 23 * 60 + 59);
    final hour = total ~/ 60;
    final minute = total % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static String _durationText(String start, String end) {
    final diff = _toMinutes(end) - _toMinutes(start);
    if (diff <= 0) return '0m';
    final h = diff ~/ 60;
    final m = diff % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  static String _weekdayLabel(int day) {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];
  }
}
