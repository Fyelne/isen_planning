import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/schedule/schedule_bloc.dart';
import '../models/course_event.dart';
import '../widgets/empty_state.dart';

/// Recherche par matière et affiche la prochaine occurrence à venir.
/// En tapant sur "Aller à ce jour", `onGoToDay` est appelé : c'est le shell
/// principal qui se charge de basculer sur l'onglet Planning à cette date,
/// puisque cet écran est désormais un onglet permanent (et non plus poussé).
class SearchCourseScreen extends StatefulWidget {
  const SearchCourseScreen({super.key, required this.onGoToDay});

  final ValueChanged<DateTime> onGoToDay;

  @override
  State<SearchCourseScreen> createState() => _SearchCourseScreenState();
}

class _SearchCourseScreenState extends State<SearchCourseScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `watch` et non `read` : cet écran reste monté en permanence (onglet),
    // il doit donc se mettre à jour si le planning est rafraîchi pendant
    // qu'on est sur un autre onglet ou sur celui-ci.
    final events = context.watch<ScheduleBloc>().state.events;
    final subjects = events.map((e) => e.subjectLabel).toSet().toList()..sort();
    final filtered = _query.isEmpty
        ? subjects
        : subjects.where((s) => s.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Recherche')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Rechercher une matière',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: events.isEmpty
                ? const EmptyState(
                    message: "Aucun cours chargé pour l'instant.",
                    icon: Icons.search_off_rounded,
                  )
                : filtered.isEmpty
                    ? const EmptyState(
                        message: 'Aucune matière ne correspond à votre recherche.',
                        icon: Icons.search_off_rounded,
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final subject = filtered[index];
                          return ListTile(
                            leading: const Icon(Icons.menu_book_outlined),
                            title: Text(subject),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _showNextOccurrence(context, events, subject),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showNextOccurrence(BuildContext context, List<CourseEvent> events, String subject) {
    final now = DateTime.now();
    final upcoming = events.where((e) => e.subjectLabel == subject && e.end.isAfter(now)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    if (upcoming.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aucun cours à venir pour "$subject".')),
      );
      return;
    }

    final next = upcoming.first;
    final dateFormat = DateFormat('EEEE dd MMMM', 'fr_FR');
    final timeFormat = DateFormat.Hm('fr_FR');

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject, style: Theme.of(context).textTheme.titleLarge),
              if (next.displayCourseName != subject) ...[
                const SizedBox(height: 4),
                Text(next.displayCourseName, style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
              _DetailRow(icon: Icons.event_rounded, text: dateFormat.format(next.start)),
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.schedule_rounded,
                text: '${timeFormat.format(next.start)} - ${timeFormat.format(next.end)}',
              ),
              if (next.location != null && next.location!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _DetailRow(icon: Icons.place_outlined, text: next.location!),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  widget.onGoToDay(
                    DateTime(next.start.year, next.start.month, next.start.day),
                  );
                },
                icon: const Icon(Icons.calendar_today_rounded),
                label: const Text('Aller à ce jour'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
