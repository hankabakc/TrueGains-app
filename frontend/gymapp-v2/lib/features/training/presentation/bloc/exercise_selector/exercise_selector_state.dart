import 'package:equatable/equatable.dart';
import '../../../models/exercise.dart';

class ExerciseSelectorState extends Equatable {
  final MuscleGroup? selectedGroup;
  final List<Exercise> allExercises;
  final List<Exercise> filteredExercises;

  const ExerciseSelectorState({
    this.selectedGroup,
    this.allExercises = const [],
    this.filteredExercises = const [],
  });

  ExerciseSelectorState copyWith({
    MuscleGroup? selectedGroup,
    bool clearGroup = false,
    List<Exercise>? allExercises,
    List<Exercise>? filteredExercises,
  }) {
    return ExerciseSelectorState(
      selectedGroup: clearGroup ? null : (selectedGroup ?? this.selectedGroup),
      allExercises: allExercises ?? this.allExercises,
      filteredExercises: filteredExercises ?? this.filteredExercises,
    );
  }

  @override
  List<Object?> get props => [selectedGroup, allExercises, filteredExercises];
}
