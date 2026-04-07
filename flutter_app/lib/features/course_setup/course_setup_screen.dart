import 'package:flutter/material.dart';

import '../../core/platform/adaptive.dart';
import '../../core/ui/app_icons.dart';
import '../../l10n/app_localizations.dart';
import '../../models/schedule_models.dart';
import 'course_editor_page.dart';

class CourseSetupScreen extends StatelessWidget {
  const CourseSetupScreen({
    super.key,
    required this.schedule,
    required this.onCreateCourse,
    required this.onContinue,
    required this.onBack,
  });

  final SemesterSchedule schedule;
  final void Function(CourseEditorPayload payload, List<Meeting> meetings)
      onCreateCourse;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  Future<void> _openEditor(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => CourseEditorPage(
          schedule: schedule,
          existing: null,
          onSaved: onCreateCourse,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final courses = schedule.courses;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(l10n.setupCoursesTitle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Adaptive.maxBodyWidth(context)),
          child: Padding(
            padding: EdgeInsets.all(Adaptive.horizontalPadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.addCoursesSubtitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: courses.isEmpty
                      ? Center(child: Text(l10n.noCoursesYet))
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
                                    if (c.code.isNotEmpty)
                                      '${l10n.courseCodePrefix}: ${c.code}',
                                    if (c.lecturer.isNotEmpty)
                                      '${l10n.lecturerPrefix}: ${c.lecturer}',
                                  ].join(' • '),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openEditor(context),
                      icon: const Icon(AppIcons.addCourse),
                      label: Text(l10n.addCourse),
                    ),
                    FilledButton(
                      onPressed: onContinue,
                      child: Text(l10n.continueCta),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
