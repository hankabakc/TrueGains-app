import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/training/models/exercise.dart';

enum ExerciseLibraryStatus { initial, loading, success, failure }

class ExerciseLibraryState extends Equatable {
  final ExerciseLibraryStatus status;
  final List<Exercise> exercises;
  final List<Exercise> filteredExercises;
  final Set<Exercise> selectedExercises;
  final String searchQuery;
  final MuscleGroup? selectedGroup;
  final String? error;

  const ExerciseLibraryState({
    this.status = ExerciseLibraryStatus.initial,
    this.exercises = const [],
    this.filteredExercises = const [],
    this.selectedExercises = const {},
    this.searchQuery = '',
    this.selectedGroup,
    this.error,
  });

  ExerciseLibraryState copyWith({
    ExerciseLibraryStatus? status,
    List<Exercise>? exercises,
    List<Exercise>? filteredExercises,
    Set<Exercise>? selectedExercises,
    String? searchQuery,
    MuscleGroup? selectedGroup,
    bool clearGroup = false,
    String? error,
  }) {
    return ExerciseLibraryState(
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
      filteredExercises: filteredExercises ?? this.filteredExercises,
      selectedExercises: selectedExercises ?? this.selectedExercises,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedGroup: clearGroup ? null : (selectedGroup ?? this.selectedGroup),
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        exercises,
        filteredExercises,
        selectedExercises,
        searchQuery,
        selectedGroup,
        error,
      ];
}
