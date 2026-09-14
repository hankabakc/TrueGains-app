import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/exercise.dart';
import 'exercise_selector_state.dart';

class ExerciseSelectorCubit extends Cubit<ExerciseSelectorState> {
  ExerciseSelectorCubit(List<Exercise> exercises)
      : super(ExerciseSelectorState(
          allExercises: exercises,
          filteredExercises: exercises,
        ));

  void selectGroup(MuscleGroup? group) {
    if (group == null) {
      emit(state.copyWith(
        clearGroup: true,
        filteredExercises: state.allExercises,
      ));
    } else {
      final filtered = state.allExercises
          .where((ex) => ex.muscleGroup == group)
          .toList();
      emit(state.copyWith(
        selectedGroup: group,
        filteredExercises: filtered,
      ));
    }
  }
}
