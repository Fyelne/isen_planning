import 'package:equatable/equatable.dart';

/// Représente un cours/événement unique extrait du flux ICS.
class CourseEvent extends Equatable {
  final String uid;
  final String summary;
  final String? location;
  final DateTime start;
  final DateTime end;

  /// Champs extraits de la zone DESCRIPTION structurée du flux ADE.
  final String? subject; // "Matière"
  final String? courseName; // "Cours"
  final String? activityType; // "Activité"
  final List<String> teachers; // "Intervenant(s)"
  final String? details; // "Description"

  const CourseEvent({
    required this.uid,
    required this.summary,
    required this.start,
    required this.end,
    this.location,
    this.subject,
    this.courseName,
    this.activityType,
    this.teachers = const [],
    this.details,
  });

  Duration get duration => end.difference(start);

  bool isSameDay(DateTime day) =>
      start.year == day.year && start.month == day.month && start.day == day.day;

  /// Nom de cours à afficher : privilégie le champ "Cours" de la description
  /// structurée, puis retombe sur le SUMMARY brut.
  String get displayCourseName =>
      (courseName != null && courseName!.isNotEmpty) ? courseName! : summary;

  /// Clé utilisée pour le filtrage fin (masquer un cours précis).
  String get filterKey => displayCourseName;

  /// Clé utilisée pour le regroupement et la recherche par matière.
  String get subjectLabel =>
      (subject != null && subject!.isNotEmpty) ? subject! : displayCourseName;

  @override
  List<Object?> get props => [
        uid,
        summary,
        location,
        start,
        end,
        subject,
        courseName,
        activityType,
        teachers,
        details,
      ];
}
