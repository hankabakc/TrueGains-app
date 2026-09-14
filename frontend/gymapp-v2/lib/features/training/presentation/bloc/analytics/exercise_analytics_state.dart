import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/training/models/exercise_progress.dart';

enum ExerciseAnalyticsStatus { initial, loading, loaded, failure }

class ExerciseAnalyticsState extends Equatable {
  final ExerciseAnalyticsStatus status;
  final List<ExerciseProgress> progress;
  final String? error;

  const ExerciseAnalyticsState({
    this.status = ExerciseAnalyticsStatus.initial,
    this.progress = const [],
    this.error,
  });

  ExerciseAnalyticsState copyWith({
    ExerciseAnalyticsStatus? status,
    List<ExerciseProgress>? progress,
    String? error,
  }) {
    return ExerciseAnalyticsState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, progress, error];
}
