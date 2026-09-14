import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/training/repository/training_repository.dart';
import 'package:gymapp_v2/features/training/models/workout_session.dart';
import 'workout_history_state.dart';

class WorkoutHistoryCubit extends Cubit<WorkoutHistoryState> {
  final TrainingRepository _trainingRepository;

  WorkoutHistoryCubit(this._trainingRepository) : super(const WorkoutHistoryState());

  Future<void> loadHistory([int? clientId]) async {
    emit(state.copyWith(status: WorkoutHistoryStatus.loading));
    try {
      final result = await _trainingRepository.getWorkoutHistory(clientId);
      final List<WorkoutSession> sessions = (result.data ?? [])
          .map((e) => WorkoutSession.fromJson(e))
          .toList();
      emit(state.copyWith(
        status: WorkoutHistoryStatus.success,
        history: sessions,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: WorkoutHistoryStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> deleteSession(int id) async {
    try {
      final result = await _trainingRepository.deleteWorkoutSession(id);
      if (result.success) {
        final newHistory = List<WorkoutSession>.from(state.history)
          ..removeWhere((s) => s.id == id);
        emit(state.copyWith(history: newHistory));
      } else {
        emit(state.copyWith(
          status: WorkoutHistoryStatus.failure,
          error: result.message,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: WorkoutHistoryStatus.failure,
        error: e.toString(),
      ));
    }
  }
}
