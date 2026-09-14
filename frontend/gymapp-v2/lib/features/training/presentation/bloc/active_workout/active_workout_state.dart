part of 'active_workout_bloc.dart';

enum ActiveWorkoutStatus { ready, active, resting, preparing, finished }

class ActiveWorkoutState extends Equatable {
  final ActiveWorkoutStatus status;
  final WorkoutDay? workoutDay;
  final int? trainingBlockId;
  final int currentExerciseIndex;
  final int currentSetIndex;
  final int totalWorkoutSeconds;
  final int setStopwatchSeconds;
  final int restTimerSeconds;
  final int preparationSeconds;
  final List<CompletedSetData> completedSets;
  final double currentWeight;
  final int currentReps;
  final bool isOfflineSaved;
  final String? error;
  final Set<int> skippedExerciseIds;
  final Set<int> finishedExerciseIds;
  final Map<int, Exercise> substitutions;
  final int sessionRestSeconds;

  const ActiveWorkoutState({
    this.status = ActiveWorkoutStatus.ready,
    this.workoutDay,
    this.trainingBlockId,
    this.currentExerciseIndex = 0,
    this.currentSetIndex = 1,
    this.totalWorkoutSeconds = 0,
    this.setStopwatchSeconds = 0,
    this.restTimerSeconds = 0,
    this.preparationSeconds = 3,
    this.completedSets = const [],
    this.currentWeight = 0.0,
    this.currentReps = 0,
    this.isOfflineSaved = false,
    this.error,
    this.skippedExerciseIds = const {},
    this.finishedExerciseIds = const {},
    this.substitutions = const {},
    this.sessionRestSeconds = 90,
  });

  ActiveWorkoutState copyWith({
    ActiveWorkoutStatus? status,
    WorkoutDay? workoutDay,
    int? trainingBlockId,
    int? currentExerciseIndex,
    int? currentSetIndex,
    int? totalWorkoutSeconds,
    int? setStopwatchSeconds,
    int? restTimerSeconds,
    int? preparationSeconds,
    List<CompletedSetData>? completedSets,
    double? currentWeight,
    int? currentReps,
    bool? isOfflineSaved,
    String? error,
    Set<int>? skippedExerciseIds,
    Set<int>? finishedExerciseIds,
    Map<int, Exercise>? substitutions,
    int? sessionRestSeconds,
  }) {
    return ActiveWorkoutState(
      status: status ?? this.status,
      workoutDay: workoutDay ?? this.workoutDay,
      trainingBlockId: trainingBlockId ?? this.trainingBlockId,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      totalWorkoutSeconds: totalWorkoutSeconds ?? this.totalWorkoutSeconds,
      setStopwatchSeconds: setStopwatchSeconds ?? this.setStopwatchSeconds,
      restTimerSeconds: restTimerSeconds ?? this.restTimerSeconds,
      preparationSeconds: preparationSeconds ?? this.preparationSeconds,
      completedSets: completedSets ?? this.completedSets,
      currentWeight: currentWeight ?? this.currentWeight,
      currentReps: currentReps ?? this.currentReps,
      isOfflineSaved: isOfflineSaved ?? this.isOfflineSaved,
      error: error ?? this.error,
      skippedExerciseIds: skippedExerciseIds ?? this.skippedExerciseIds,
      finishedExerciseIds: finishedExerciseIds ?? this.finishedExerciseIds,
      substitutions: substitutions ?? this.substitutions,
      sessionRestSeconds: sessionRestSeconds ?? this.sessionRestSeconds,
    );
  }

  @override
  List<Object?> get props => [
    status,
    workoutDay,
    trainingBlockId,
    currentExerciseIndex,
    currentSetIndex,
    totalWorkoutSeconds,
    setStopwatchSeconds,
    restTimerSeconds,
    preparationSeconds,
    completedSets,
    currentWeight,
    currentReps,
    isOfflineSaved,
    error,
    skippedExerciseIds,
    finishedExerciseIds,
    substitutions,
    sessionRestSeconds,
  ];
}
