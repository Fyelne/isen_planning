import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../bloc/settings/settings_state.dart';
import '../../models/course_event.dart';

/// Affiche le détail complet d'un cours. La date, l'heure et la salle sont
/// toujours affichées (informations structurantes) ; la matière, le type
/// d'activité, le(s) intervenant(s) et la description sont conditionnés à
/// `visibleFields`, réglable par l'utilisateur (Réglages → Informations
/// affichées → Fiche détaillée).
void showCourseDetailSheet(
  BuildContext context,
  CourseEvent event, {
  required Set<CourseField> visibleFields,
}) {
  final dateFormat = DateFormat('EEEE dd MMMM', 'fr_FR');
  final timeFormat = DateFormat.Hm('fr_FR');

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          24 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(event.displayCourseName, style: Theme.of(sheetContext).textTheme.titleLarge),
              if (visibleFields.contains(CourseField.subject) &&
                  event.subject != null &&
                  event.subject!.isNotEmpty &&
                  event.subject != event.displayCourseName) ...[
                const SizedBox(height: 4),
                Text(
                  event.subject!,
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              _DetailRow(icon: Icons.event_rounded, text: dateFormat.format(event.start)),
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.schedule_rounded,
                text: '${timeFormat.format(event.start)} - ${timeFormat.format(event.end)}',
              ),
              if (event.location != null && event.location!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _DetailRow(icon: Icons.place_outlined, text: event.location!),
              ],
              if (visibleFields.contains(CourseField.activityType) &&
                  event.activityType != null &&
                  event.activityType!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _DetailRow(icon: Icons.local_activity_outlined, text: event.activityType!),
              ],
              if (visibleFields.contains(CourseField.teachers) && event.teachers.isNotEmpty) ...[
                const SizedBox(height: 8),
                _DetailRow(icon: Icons.person_outline_rounded, text: event.teachers.join(', ')),
              ],
              if (visibleFields.contains(CourseField.details) &&
                  event.details != null &&
                  event.details!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _DetailRow(icon: CourseField.details.icon, text: event.details!),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
