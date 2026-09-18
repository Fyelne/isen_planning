import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../bloc/settings/settings_state.dart';
import '../../models/course_event.dart';
import 'course_detail_sheet.dart';
import 'day_grid_column.dart';
import 'hour_gutter.dart';
import 'time_grid_metrics.dart';

/// Vue "semaine" : une colonne par jour avec quadrillage horaire partagé,
/// utilisée sur les écrans larges (PC, Mac, tablettes/téléphones en paysage).
class WeekCalendarView extends StatelessWidget {
  const WeekCalendarView({
    super.key,
    required this.days,
    required this.eventsForDay,
    required this.showTime,
    required this.showLocation,
    required this.visibleDetailFields,
  });

  final List<DateTime> days;
  final List<CourseEvent> Function(DateTime day) eventsForDay;
  final bool showTime;
  final bool showLocation;
  final Set<CourseField> visibleDetailFields;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final allEvents = [for (final day in days) ...eventsForDay(day)];
    final range = computeTimeRange(allEvents);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyWidth = (constraints.maxWidth - kGutterWidth).clamp(0.0, double.infinity);
        final columnWidth = days.isEmpty ? 0.0 : bodyWidth / days.length;

        return Column(
          children: [
            Row(
              children: [
                const SizedBox(width: kGutterWidth),
                for (final day in days)
                  SizedBox(
                    width: columnWidth,
                    child: _DayHeaderCell(day: day, isToday: _isSameDay(day, today)),
                  ),
              ],
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: HourGutter(range: range),
                    ),
                    for (final day in days)
                      SizedBox(
                        width: columnWidth,
                        child: DayGridColumn(
                          day: day,
                          range: range,
                          events: eventsForDay(day),
                          isToday: _isSameDay(day, today),
                          showTime: showTime,
                          showLocation: showLocation,
                          onEventTap: (event) => showCourseDetailSheet(
                            context,
                            event,
                            visibleFields: visibleDetailFields,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DayHeaderCell extends StatelessWidget {
  const _DayHeaderCell({required this.day, required this.isToday});

  final DateTime day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            DateFormat.E('fr_FR').format(day).toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isToday ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration:
                isToday ? BoxDecoration(color: scheme.primary, shape: BoxShape.circle) : null,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isToday ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
