import '../../models/course_event.dart';

/// Un cours positionné dans la grille : sa colonne parmi les cours qui se
/// chevauchent, et le nombre total de colonnes de son groupe.
class PositionedCourseEvent {
  final CourseEvent event;
  final int columnIndex;
  final int columnCount;

  const PositionedCourseEvent({
    required this.event,
    required this.columnIndex,
    required this.columnCount,
  });
}

/// Résout les chevauchements entre cours d'une même journée en assignant à
/// chaque événement une colonne, comme dans un calendrier classique : les
/// cours qui se chevauchent dans le temps se répartissent côte à côte.
List<PositionedCourseEvent> layoutEventsForDay(List<CourseEvent> dayEvents) {
  final events = [...dayEvents]..sort((a, b) => a.start.compareTo(b.start));
  final result = <PositionedCourseEvent>[];

  List<CourseEvent> cluster = [];
  DateTime? clusterEnd;

  void flushCluster() {
    if (cluster.isEmpty) return;

    // Coloration gloutonne d'intervalles : chaque événement rejoint la
    // première colonne déjà libre à son heure de début, sinon en ouvre une.
    final columnEndTimes = <DateTime>[];
    final columnByUid = <String, int>{};

    for (final event in cluster) {
      int? placedIndex;
      for (var i = 0; i < columnEndTimes.length; i++) {
        if (!event.start.isBefore(columnEndTimes[i])) {
          placedIndex = i;
          break;
        }
      }
      if (placedIndex == null) {
        columnEndTimes.add(event.end);
        placedIndex = columnEndTimes.length - 1;
      } else {
        columnEndTimes[placedIndex] = event.end;
      }
      columnByUid[event.uid] = placedIndex;
    }

    final totalColumns = columnEndTimes.length;
    for (final event in cluster) {
      result.add(PositionedCourseEvent(
        event: event,
        columnIndex: columnByUid[event.uid]!,
        columnCount: totalColumns,
      ));
    }

    cluster = [];
    clusterEnd = null;
  }

  for (final event in events) {
    if (cluster.isEmpty) {
      cluster.add(event);
      clusterEnd = event.end;
    } else if (event.start.isBefore(clusterEnd!)) {
      cluster.add(event);
      if (event.end.isAfter(clusterEnd!)) clusterEnd = event.end;
    } else {
      flushCluster();
      cluster.add(event);
      clusterEnd = event.end;
    }
  }
  flushCluster();

  return result;
}
