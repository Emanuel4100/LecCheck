import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/schedule_models.dart';

/// Lists all courses; FAB and tiles open the editor via [onCreate] / [onEdit].
class CourseListPage extends StatelessWidget {
  const CourseListPage({
    super.key,
    required this.schedule,
    required this.onCreate,
    required this.onEdit,
  });

  final SemesterSchedule schedule;
  final void Function(BuildContext context) onCreate;
  final void Function(BuildContext context, Course course) onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final courses = schedule.courses;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageCourses),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => onCreate(context),
        child: const Icon(Icons.add),
      ),
      body: courses.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.noCoursesYet,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courses.length,
              itemBuilder: (_, i) {
                final c = courses[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: c.color),
                    title: Text(c.name),
                    subtitle: Text(
                      [
                        if (c.code.isNotEmpty)
                          '${l10n.courseCodePrefix}: ${c.code}',
                        if (c.lecturer.isNotEmpty)
                          '${l10n.lecturerPrefix}: ${c.lecturer}',
                      ].join(' • '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onEdit(context, c),
                  ),
                );
              },
            ),
    );
  }
}
