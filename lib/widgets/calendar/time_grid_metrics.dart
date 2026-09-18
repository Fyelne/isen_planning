import '../../models/course_event.dart';

/// Plage horaire affichée par la grille (ex : 08h-19h).
class TimeRange {
  final int startHour;
  final int endHour;
  const TimeRange({required this.startHour, required this.endHour});
}

const double kHourHeight = 64.0;
const double kGutterWidth = 52.0;
const int kDefaultStartHour = 8;
const int kDefaultEndHour = 19;

/// Calcule la plage horaire à afficher : par défaut 08h-19h, étendue
/// automatiquement si des cours débordent de cet intervalle par défaut.
TimeRange computeTimeRange(List<CourseEvent> events) {
  int startHour = kDefaultStartHour;
  int endHour = kDefaultEndHour;
  for (final event in events) {
    if (event.start.hour < startHour) startHour = event.start.hour;
    final endCandidate = event.end.minute > 0 ? event.end.hour + 1 : event.end.hour;
    if (endCandidate > endHour) endHour = endCandidate;
  }
  startHour = startHour.clamp(0, 22);
  endHour = endHour.clamp(startHour + 1, 24);
  return TimeRange(startHour: startHour, endHour: endHour);
}

/// Nombre de minutes écoulées depuis le début de la plage horaire.
double minutesFromRangeStart(TimeRange range, DateTime time) {
  return (time.hour - range.startHour) * 60 + time.minute.toDouble();
}
