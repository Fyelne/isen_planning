import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/schedule_repository.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  ScheduleBloc({required ScheduleRepository repository})
      : _repository = repository,
        super(const ScheduleState()) {
    on<ScheduleStarted>(_onStarted);
    on<ScheduleRefreshed>(_onRefreshed);
    on<ScheduleStudentNumberChanged>(_onStudentNumberChanged);
  }

  final ScheduleRepository _repository;
  String? _studentNumber;

  Future<void> _onStarted(ScheduleStarted event, Emitter<ScheduleState> emit) async {
    _studentNumber = event.studentNumber;
    emit(state.copyWith(status: ScheduleStatus.loading));
    await _load(emit);
  }

  Future<void> _onRefreshed(ScheduleRefreshed event, Emitter<ScheduleState> emit) async {
    if (_studentNumber == null) return;
    emit(state.copyWith(
      status: ScheduleStatus.refreshing,
      events: state.events,
    ));
    await _load(emit);
  }

  Future<void> _onStudentNumberChanged(
    ScheduleStudentNumberChanged event,
    Emitter<ScheduleState> emit,
  ) async {
    _studentNumber = event.studentNumber;
    emit(state.copyWith(status: ScheduleStatus.loading, events: []));
    await _load(emit);
  }

  Future<void> _load(Emitter<ScheduleState> emit) async {
    final studentNumber = _studentNumber;
    if (studentNumber == null) return;
    try {
      final result = await _repository.fetchSchedule(studentNumber);
      emit(state.copyWith(
        status: ScheduleStatus.success,
        events: result.events,
        lastUpdated: result.lastUpdated,
        isOffline: result.fromCache,
        errorMessage: null,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: ScheduleStatus.failure,
        errorMessage: error.toString().replaceFirst('ScheduleRepositoryException: ', ''),
      ));
    }
  }
}
