import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/training/repository/training_repository.dart';
import 'exercise_analytics_state.dart';

class ExerciseAnalyticsCubit extends Cubit<ExerciseAnalyticsState> {
  final TrainingRepository _repository;

  ExerciseAnalyticsCubit(this._repository) : super(const ExerciseAnalyticsState());

  Future<void> loadExerciseProgress(int exerciseId, {int? clientId}) async {
    if (isClosed) return;
    emit(state.copyWith(status: ExerciseAnalyticsStatus.loading));
    try {
      final response = await _repository.getExerciseProgress(exerciseId, clientId: clientId);
      // Async tamamlanmadan cubit kapanmış olabilir (sayfa dispose). Kapalıysa emit etme.
      if (isClosed) return;
      if (response.success && response.data != null) {
        emit(state.copyWith(
          status: ExerciseAnalyticsStatus.loaded,
          progress: response.data,
        ));
      } else {
        emit(state.copyWith(
          status: ExerciseAnalyticsStatus.failure,
          error: response.message,
        ));
      }
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: ExerciseAnalyticsStatus.failure,
        error: e.toString(),
      ));
    }
  }
}
