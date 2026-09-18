import 'package:equatable/equatable.dart';

abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();

  @override
  List<Object?> get props => [];
}

/// Émis une fois, quand l'écran de planning est affiché pour la première fois.
class ScheduleStarted extends ScheduleEvent {
  final String studentNumber;
  const ScheduleStarted(this.studentNumber);

  @override
  List<Object?> get props => [studentNumber];
}

/// Émis lors d'un pull-to-refresh, de la touche F5, ou du bouton refresh.
class ScheduleRefreshed extends ScheduleEvent {
  const ScheduleRefreshed();
}

/// Émis quand l'utilisateur change son numéro étudiant dans les réglages.
class ScheduleStudentNumberChanged extends ScheduleEvent {
  final String studentNumber;
  const ScheduleStudentNumberChanged(this.studentNumber);

  @override
  List<Object?> get props => [studentNumber];
}
