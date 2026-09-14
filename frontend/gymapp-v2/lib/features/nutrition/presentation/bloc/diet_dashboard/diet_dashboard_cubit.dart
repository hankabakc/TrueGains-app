import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/config/app_config.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'package:gymapp_v2/features/nutrition/data/models/recipe_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';
import 'diet_dashboard_state.dart';

class DietDashboardCubit extends Cubit<DietDashboardState> {
  final NutritionRepository _repository;

  DietDashboardCubit({required NutritionRepository repository})
      : _repository = repository,
        super(const DietDashboardState());

  Future<void> loadData({int? programId, bool silent = false}) async {
    if (!silent) {
      if (isClosed) return;
      emit(state.copyWith(status: DietDashboardStatus.loading));
    }

    try {
      final resp = programId != null
          ? await _repository.getProgramById(programId)
          : await _repository.getMainProgram();

      if (isClosed) return;

      if (resp.success) {
        emit(state.copyWith(
          status: DietDashboardStatus.success,
          mainProgram: resp.data,
        ));
      } else {
        emit(state.copyWith(
          status: DietDashboardStatus.failure,
          error: resp.message,
        ));
      }
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: DietDashboardStatus.failure,
        error: friendlyError(e),
      ));
    }
  }

  void selectDay(int index) {
    if (isClosed) return;
    emit(state.copyWith(selectedDayIndex: index));
  }

  Future<void> toggleRecipeExpand(int recipeId) async {
    final newExpanded = Set<int>.from(state.expandedRecipeIds);

    if (newExpanded.contains(recipeId)) {
      newExpanded.remove(recipeId);
      if (isClosed) return;
      emit(state.copyWith(expandedRecipeIds: newExpanded));
    } else {
      newExpanded.add(recipeId);
      if (isClosed) return;
      emit(state.copyWith(expandedRecipeIds: newExpanded));

      // Load ingredients if not already loaded
      if (!state.loadedRecipeIngredients.containsKey(recipeId)) {
        final newLoading = Set<int>.from(state.loadingRecipeIds)..add(recipeId);
        if (isClosed) return;
        emit(state.copyWith(loadingRecipeIds: newLoading));

        try {
          final resp = await _repository.getRecipeById(recipeId);
          if (isClosed) return;
          if (resp.success && resp.data != null) {
            final newLoaded = Map<int, List<RecipeIngredientModel>>.from(state.loadedRecipeIngredients);
            newLoaded[recipeId] = resp.data!.ingredients;

            final updatedLoading = Set<int>.from(state.loadingRecipeIds)..remove(recipeId);
            emit(state.copyWith(
              loadedRecipeIngredients: newLoaded,
              loadingRecipeIds: updatedLoading,
            ));
          } else {
            final updatedLoading = Set<int>.from(state.loadingRecipeIds)..remove(recipeId);
            emit(state.copyWith(loadingRecipeIds: updatedLoading));
          }
        } catch (_) {
          if (isClosed) return;
          final updatedLoading = Set<int>.from(state.loadingRecipeIds)..remove(recipeId);
          emit(state.copyWith(loadingRecipeIds: updatedLoading));
        }
      }
    }
  }

  Future<void> deleteIngredient(int ingredientId) async {
    final resp = await _repository.deleteMealIngredient(ingredientId);
    if (isClosed) return;
    if (resp.success) {
      loadData(silent: true);
    }
  }

  Future<void> updateIngredientAmount(int ingredientId, double amount) async {
    final resp = await _repository.updateMealIngredientAmount(ingredientId, amount);
    if (isClosed) return;
    if (resp.success) {
      loadData(silent: true);
    }
  }

  Future<void> logMeal({required MealType mealType, required List<Map<String, dynamic>> items}) async {
    final resp = await _repository.logMeal(mealType: mealType, items: items);
    if (isClosed) return;
    if (resp.success) {
      loadData(silent: true);
    }
  }

  Future<void> renameProgram(int programId, String newName) async {
    final resp = await _repository.renameProgram(programId, newName);
    if (isClosed) return;
    if (resp.success) {
      loadData(silent: true);
    }
  }

  Future<void> subscribeToUpdates(int clientId) async {
    await _repository.subscribeToDietUpdates(
      clientId: clientId,
      wsUrl: AppConfig.wsUrl,
      onUpdateReceived: () {
        loadData(silent: true);
      },
    );
  }

  void unsubscribeFromUpdates() {
    _repository.unsubscribeFromDietUpdates();
  }

  @override
  Future<void> close() {
    unsubscribeFromUpdates();
    return super.close();
  }
}
