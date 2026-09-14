import 'package:flutter_bloc/flutter_bloc.dart';
import 'save_recipe_modal_state.dart';

class SaveRecipeModalCubit extends Cubit<SaveRecipeModalState> {
  SaveRecipeModalCubit() : super(const SaveRecipeModalState());

  void setDay(int index) => emit(state.copyWith(selectedDayIndex: index));
}
