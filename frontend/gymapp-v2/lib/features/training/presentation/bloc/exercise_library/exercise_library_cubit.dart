import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/training/models/exercise.dart';
import 'package:gymapp_v2/features/training/repository/training_repository.dart';
import 'exercise_library_state.dart';

class ExerciseLibraryCubit extends Cubit<ExerciseLibraryState> {
  final TrainingRepository _trainingRepository;

  ExerciseLibraryCubit(this._trainingRepository) : super(const ExerciseLibraryState());

  Future<void> loadExercises({List<Exercise>? initialExercises}) async {
    if (initialExercises != null) {
      emit(state.copyWith(
        status: ExerciseLibraryStatus.success,
        exercises: initialExercises,
      ));
      _filter();
      return;
    }

    emit(state.copyWith(status: ExerciseLibraryStatus.loading));
    try {
      final result = await _trainingRepository.getAllExercises();
      final exercises = result.data ?? [];
      emit(state.copyWith(
        status: ExerciseLibraryStatus.success,
        exercises: exercises,
      ));
      _filter();
    } catch (e) {
      emit(state.copyWith(
        status: ExerciseLibraryStatus.failure,
        error: e.toString(),
      ));
    }
  }

  void updateSearch(String query) {
    emit(state.copyWith(searchQuery: query));
    _filter();
  }

  void selectGroup(MuscleGroup? group) {
    if (group == null || state.selectedGroup == group) {
      emit(state.copyWith(clearGroup: true));
    } else {
      emit(state.copyWith(selectedGroup: group));
    }
    _filter();
  }

  void toggleSelection(Exercise exercise) {
    final newSelection = Set<Exercise>.from(state.selectedExercises);
    if (newSelection.any((e) => e.id == exercise.id)) {
      newSelection.removeWhere((e) => e.id == exercise.id);
    } else {
      newSelection.add(exercise);
    }
    emit(state.copyWith(selectedExercises: newSelection));
  }

  void _filter() {
    var filtered = List<Exercise>.from(state.exercises);

    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((ex) {
        return ex.name.toLowerCase().contains(query) ||
            (ex.scientificName?.toLowerCase().contains(query) ?? false) ||
            ex.muscleGroup.turkishName.toLowerCase().contains(query);
      }).toList();
    }

    if (state.selectedGroup != null) {
      filtered = filtered.where((ex) => ex.muscleGroup == state.selectedGroup).toList();
    }



    emit(state.copyWith(filteredExercises: filtered));
  }
}
