import 'package:equatable/equatable.dart';

import '../../models/course_event.dart';

enum ScheduleStatus { initial, loading, refreshing, success, failure }

class ScheduleState extends Equatable {
  final ScheduleStatus status;
  final List<CourseEvent> events;
  final DateTime? lastUpdated;
  final bool isOffline;
  final String? errorMessage;

  const ScheduleState({
    this.status = ScheduleStatus.initial,
    this.events = const [],
    this.lastUpdated,
    this.isOffline = false,
    this.errorMessage,
  });

  bool get hasData => events.isNotEmpty;

  ScheduleState copyWith({
    ScheduleStatus? status,
    List<CourseEvent>? events,
    DateTime? lastUpdated,
    bool? isOffline,
    String? errorMessage,
  }) {
    return ScheduleState(
      status: status ?? this.status,
      events: events ?? this.events,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, events, lastUpdated, isOffline, errorMessage];
}
