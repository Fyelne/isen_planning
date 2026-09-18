import 'package:flutter/material.dart';

import '../../bloc/settings/settings_state.dart';
import '../../models/course_event.dart';
import 'course_detail_sheet.dart';
import 'day_grid_column.dart';
import 'hour_gutter.dart';
import 'time_grid_metrics.dart';

/// Vue "jour" : une seule colonne avec quadrillage horaire, utilisée sur les
/// écrans étroits (téléphones en portrait).
class DayCalendarView extends StatelessWidget {
  const DayCalendarView({
    super.key,
    required this.day,
    required this.events,
    required this.showTime,
    required this.showLocation,
    required this.visibleDetailFields,
  });

  final DateTime day;
  final List<CourseEvent> events;
  final bool showTime;
  final bool showLocation;
  final Set<CourseField> visibleDetailFields;

  bool get _isToday {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final range = computeTimeRange(events);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 4), child: HourGutter(range: range)),
          Expanded(
            child: DayGridColumn(
              day: day,
              range: range,
              events: events,
              isToday: _isToday,
              showTime: showTime,
              showLocation: showLocation,
              onEventTap: (event) =>
                  showCourseDetailSheet(context, event, visibleFields: visibleDetailFields),
            ),
          ),
        ],
      ),
    );
  }
}
