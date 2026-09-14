import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'food_search_state.dart';

class FoodSearchCubit extends Cubit<FoodSearchState> {
  final NutritionRepository _repository;

  FoodSearchCubit(this._repository) : super(const FoodSearchState());

  Future<void> loadInitialData() async {
    emit(state.copyWith(status: FoodSearchStatus.loading));
    try {
      final results = await Future.wait([
        _repository.getRecentGroupedFoods(),
        _repository.getTemplates(),
        _repository.getOverriddenFoods(),
        _repository.getRecipes(),
        _repository.getMyCustomFoods(),
      ]);

      emit(state.copyWith(
        status: FoodSearchStatus.success,
        recentGroupedFoods: results[0].success ? (results[0].data as List).cast() : [],
        templates: results[1].success ? (results[1].data as List).cast() : [],
        overriddenFoods: results[2].success ? (results[2].data as List).cast() : [],
        recipes: results[3].success ? (results[3].data as List).cast() : [],
        customFoods: results[4].success ? (results[4].data as List).cast() : [],
      ));
    } catch (e) {
      emit(state.copyWith(status: FoodSearchStatus.failure, error: friendlyError(e)));
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    emit(state.copyWith(status: FoodSearchStatus.searching, searchResults: []));

    final response = await _repository.searchFood(query);
    if (response.success) {
      emit(state.copyWith(status: FoodSearchStatus.success, searchResults: response.data ?? []));
    } else {
      emit(state.copyWith(status: FoodSearchStatus.failure, error: response.message));
    }
  }

  void toggleFoodSelection(FoodModel food) {
    final List<MealIngredientModel> newBasket = List.from(state.basket);
    final index = newBasket.indexWhere((s) => s.foodId == food.id && s.ignoreOverride == !food.isOverridden);

    if (index >= 0) {
      newBasket.removeAt(index);
    } else {
      newBasket.add(food.toIngredient(food.defaultAmount, ignoreOverride: !food.isOverridden));
    }
    emit(state.copyWith(basket: newBasket, isBasketExpanded: false));
  }

  void updateIngredientAmount(int index, double amount) {
    final List<MealIngredientModel> newBasket = List.from(state.basket);
    if (index >= 0 && index < newBasket.length) {
      newBasket[index] = newBasket[index].copyWith(amount: amount);
      emit(state.copyWith(basket: newBasket));
    }
  }

  void removeFromBasket(int index) {
    final List<MealIngredientModel> newBasket = List.from(state.basket);
    if (index >= 0 && index < newBasket.length) {
      newBasket.removeAt(index);
      emit(state.copyWith(basket: newBasket));
    }
  }

  void toggleBasketExpanded() {
    emit(state.copyWith(isBasketExpanded: !state.isBasketExpanded));
  }

  bool isTemplateInBasket(MealTemplateModel template) {
    if (template.ingredients.isEmpty) return false;
    for (final ingredient in template.ingredients) {
      final exists = state.basket.any((s) =>
          s.foodId == ingredient.foodId &&
          s.ignoreOverride == ingredient.ignoreOverride &&
          s.amount == ingredient.amount);
      if (!exists) return false;
    }
    return true;
  }

  void toggleTemplateSelection(MealTemplateModel template) {
    final List<MealIngredientModel> newBasket = List.from(state.basket);
    if (isTemplateInBasket(template)) {
      for (final ingredient in template.ingredients) {
        newBasket.removeWhere((s) =>
            s.foodId == ingredient.foodId &&
            s.ignoreOverride == ingredient.ignoreOverride &&
            s.amount == ingredient.amount);
      }
      emit(state.copyWith(basket: newBasket));
    } else {
      for (final ingredient in template.ingredients) {
        final exists = newBasket.any((s) =>
            s.foodId == ingredient.foodId &&
            s.ignoreOverride == ingredient.ignoreOverride &&
            s.amount == ingredient.amount);
        if (!exists) {
          newBasket.add(ingredient);
        }
      }
      emit(state.copyWith(basket: newBasket, isBasketExpanded: true));
    }
  }

  Future<void> deleteTemplate(int templateId) async {
    final response = await _repository.deleteTemplate(templateId);
    if (response.success) {
      loadInitialData();
    } else {
      emit(state.copyWith(error: response.message));
    }
  }

  Future<void> saveAll({int? mealId, MealType? mealType, bool isTemplateMode = false}) async {
    if (state.basket.isEmpty) return;

    if (state.basket.any((item) => item.amount <= 0)) {
      emit(state.copyWith(error: 'Lütfen tüm besinler için geçerli bir miktar girin.'));
      return;
    }

    if (isTemplateMode) {
      emit(state.copyWith(status: FoodSearchStatus.saved));
      return;
    }

    emit(state.copyWith(status: FoodSearchStatus.saving));

    ApiResponse<dynamic> res;
    if (mealType != null) {
      final items = state.basket.map((item) => {
        'foodId': item.foodId,
        'recipeId': item.recipeId,
        'amount': item.amount,
        'note': item.note,
      }).toList();
      res = await _repository.logMeal(mealType: mealType, items: items, date: DateTime.now());
    } else if (mealId != null) {
      res = await _repository.addIngredientsBulk(mealId, state.basket);
    } else {
      emit(state.copyWith(status: FoodSearchStatus.failure, error: 'Kayıt hedefi bulunamadı.'));
      return;
    }

    if (res.success) {
      emit(state.copyWith(status: FoodSearchStatus.saved, basket: []));
    } else {
      emit(state.copyWith(status: FoodSearchStatus.failure, error: res.message));
    }
  }

  void addScannedFood(FoodModel food) {
    final List<MealIngredientModel> newBasket = List.from(state.basket);
    final bool alreadyExists = newBasket.any((s) => s.foodId == food.id && s.ignoreOverride == !food.isOverridden);

    if (!alreadyExists) {
      newBasket.add(food.toIngredient(food.defaultAmount, ignoreOverride: !food.isOverridden));
      emit(state.copyWith(basket: newBasket, isBasketExpanded: true));
    }
  }

  void addIngredientsToBasket(List<MealIngredientModel> ingredients) {
    final List<MealIngredientModel> newBasket = List.from(state.basket);
    newBasket.addAll(ingredients);
    emit(state.copyWith(basket: newBasket));
  }
}
