import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/schedule/schedule_bloc.dart';
import '../bloc/settings/settings_cubit.dart';
import '../bloc/settings/settings_state.dart';
import '../models/course_event.dart';
import '../widgets/empty_state.dart';

class FilterCoursesScreen extends StatelessWidget {
  const FilterCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final events = context.read<ScheduleBloc>().state.events;

    final Map<String, List<CourseEvent>> bySubject = {};
    for (final event in events) {
      bySubject.putIfAbsent(event.subjectLabel, () => []).add(event);
    }
    final subjects = bySubject.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Filtrer les cours')),
      body: events.isEmpty
          ? const EmptyState(
              message: "Aucun cours chargé pour l'instant. Revenez après "
                  'une synchronisation.',
              icon: Icons.filter_alt_off_outlined,
            )
          : BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, settings) {
                final cubit = context.read<SettingsCubit>();
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    final courseNames = bySubject[subject]!
                        .map((e) => e.filterKey)
                        .toSet()
                        .toList()
                      ..sort();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        title: Text(subject, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${courseNames.length} cours'),
                        children: courseNames.map((courseName) {
                          final hidden = settings.hiddenCourses.contains(courseName);
                          return SwitchListTile(
                            title: Text(courseName),
                            value: !hidden,
                            onChanged: (visible) => cubit.toggleCourseHidden(courseName, !visible),
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
