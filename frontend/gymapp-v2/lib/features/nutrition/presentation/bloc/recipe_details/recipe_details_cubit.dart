import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'recipe_details_state.dart';

class RecipeDetailsCubit extends Cubit<RecipeDetailsState> {
  final NutritionRepository _repository;

  RecipeDetailsCubit(this._repository) : super(const RecipeDetailsState());

  Future<void> loadRecipe(int recipeId) async {
    emit(state.copyWith(status: RecipeDetailsStatus.loading));
    final resp = await _repository.getRecipeById(recipeId);

    if (resp.success && resp.data != null) {
      emit(state.copyWith(status: RecipeDetailsStatus.success, recipe: resp.data));
    } else {
      emit(state.copyWith(status: RecipeDetailsStatus.failure, error: resp.message));
    }
  }
}
