import 'package:flutter/material.dart';

import '../../models/course_event.dart';
import 'calendar_event_tile.dart';
import 'event_layout.dart';
import 'time_grid_metrics.dart';

class DayGridColumn extends StatelessWidget {
  const DayGridColumn({
    super.key,
    required this.day,
    required this.range,
    required this.events,
    required this.onEventTap,
    required this.showTime,
    required this.showLocation,
    this.isToday = false,
  });

  final DateTime day;
  final TimeRange range;
  final List<CourseEvent> events;
  final ValueChanged<CourseEvent> onEventTap;
  final bool showTime;
  final bool showLocation;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hourCount = range.endHour - range.startHour;
    final totalHeight = hourCount * kHourHeight;
    final positioned = layoutEventsForDay(events);

    final now = DateTime.now();
    final nowInRange = isToday && now.hour >= range.startHour && now.hour < range.endHour;
    final nowTop = nowInRange ? minutesFromRangeStart(range, now) * (kHourHeight / 60) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = constraints.maxWidth;
        return Container(
          width: columnWidth,
          height: totalHeight,
          decoration: BoxDecoration(
            color: isToday ? scheme.primary.withOpacity(0.04) : null,
            border: Border(left: BorderSide(color: scheme.outlineVariant.withOpacity(0.4))),
          ),
          child: Stack(
            children: [
              for (var i = 0; i <= hourCount; i++)
                Positioned(
                  top: i * kHourHeight,
                  left: 0,
                  right: 0,
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outlineVariant.withOpacity(0.3),
                  ),
                ),
              for (final p in positioned) _buildEventTile(context, p, columnWidth),
              if (nowInRange)
                Positioned(
                  top: nowTop,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(left: 1),
                        decoration: BoxDecoration(color: scheme.error, shape: BoxShape.circle),
                      ),
                      Expanded(child: Container(height: 2, color: scheme.error)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Une même hauteur -calculée une seule fois puis clampée- est utilisée à
  /// la fois pour la taille réelle du bloc et pour la logique interne de
  /// `CalendarEventTile` (affichage de l'heure/salle selon la place
  /// disponible). Le minimum (28px) est volontairement un peu généreux :
  /// avec une valeur trop juste, un cours très court (15 min) peut déborder
  /// d'une fraction de pixel et déclencher le bandeau de debug Flutter.
  Widget _buildEventTile(BuildContext context, PositionedCourseEvent p, double columnWidth) {
    final rawHeight = p.event.duration.inMinutes * (kHourHeight / 60);
    final height = rawHeight.clamp(28.0, double.infinity);

    return Positioned(
      top: minutesFromRangeStart(range, p.event.start) * (kHourHeight / 60),
      height: height,
      left: (columnWidth / p.columnCount) * p.columnIndex,
      width: columnWidth / p.columnCount,
      child: CalendarEventTile(
        event: p.event,
        onTap: () => onEventTap(p.event),
        heightPx: height,
        showTime: showTime,
        showLocation: showLocation,
      ),
    );
  }
}
