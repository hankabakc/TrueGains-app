import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/training/models/workout_session.dart';

enum WorkoutHistoryStatus { initial, loading, success, failure }

class WorkoutHistoryState extends Equatable {
  final WorkoutHistoryStatus status;
  final List<WorkoutSession> history;
  final String? error;

  const WorkoutHistoryState({
    this.status = WorkoutHistoryStatus.initial,
    this.history = const [],
    this.error,
  });

  WorkoutHistoryState copyWith({
    WorkoutHistoryStatus? status,
    List<WorkoutSession>? history,
    String? error,
  }) {
    return WorkoutHistoryState(
      status: status ?? this.status,
      history: history ?? this.history,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, history, error];
}
