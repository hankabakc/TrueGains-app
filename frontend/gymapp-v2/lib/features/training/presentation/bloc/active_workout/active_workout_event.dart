part of 'active_workout_bloc.dart';

abstract class ActiveWorkoutEvent extends Equatable {
  const ActiveWorkoutEvent();

  @override
  List<Object?> get props => [];
}

class StartWorkout extends ActiveWorkoutEvent {
  final WorkoutDay workoutDay;
  final int? trainingBlockId;
  final int restSeconds;

  const StartWorkout(this.workoutDay, {this.trainingBlockId, this.restSeconds = 90});

  @override
  List<Object?> get props => [workoutDay, trainingBlockId, restSeconds];
}

class StartSet extends ActiveWorkoutEvent {}

class FinishSet extends ActiveWorkoutEvent {
  const FinishSet();

  @override
  List<Object?> get props => [];
}

class SkipRest extends ActiveWorkoutEvent {}

class Tick extends ActiveWorkoutEvent {}

class QuickFinishWorkout extends ActiveWorkoutEvent {}

class UpdateWorkoutInput extends ActiveWorkoutEvent {
  final double? weight;
  final int? reps;

  const UpdateWorkoutInput({this.weight, this.reps});

  @override
  List<Object?> get props => [weight, reps];
}

class SkipExercise extends ActiveWorkoutEvent {
  const SkipExercise();
}

class FinishExercise extends ActiveWorkoutEvent {
  const FinishExercise();
}

class GoToExercise extends ActiveWorkoutEvent {
  final int index;

  const GoToExercise(this.index);

  @override
  List<Object?> get props => [index];
}

class EditCompletedSet extends ActiveWorkoutEvent {
  final int index;
  final double weight;
  final int reps;

  const EditCompletedSet(this.index, this.weight, this.reps);

  @override
  List<Object?> get props => [index, weight, reps];
}

class DeleteCompletedSet extends ActiveWorkoutEvent {
  final int index;

  const DeleteCompletedSet(this.index);

  @override
  List<Object?> get props => [index];
}

class SubstituteExercise extends ActiveWorkoutEvent {
  final Exercise exercise;

  const SubstituteExercise(this.exercise);

  @override
  List<Object?> get props => [exercise];
}

class RestoreWorkout extends ActiveWorkoutEvent {
  const RestoreWorkout();
}
