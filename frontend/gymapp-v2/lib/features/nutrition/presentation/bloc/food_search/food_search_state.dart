import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_history_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/recipe_model.dart';

enum FoodSearchStatus { initial, loading, searching, success, failure, saving, saved }

class FoodSearchState extends Equatable {
  final FoodSearchStatus status;
  final List<FoodModel> searchResults;
  final List<MealHistoryModel> recentGroupedFoods;
  final List<FoodModel> overriddenFoods;
  final List<FoodModel> customFoods;
  final List<MealTemplateModel> templates;
  final List<RecipeModel> recipes;
  final List<MealIngredientModel> basket;
  final bool isBasketExpanded;
  final String? error;

  const FoodSearchState({
    this.status = FoodSearchStatus.initial,
    this.searchResults = const [],
    this.recentGroupedFoods = const [],
    this.overriddenFoods = const [],
    this.customFoods = const [],
    this.templates = const [],
    this.recipes = const [],
    this.basket = const [],
    this.isBasketExpanded = false,
    this.error,
  });

  FoodSearchState copyWith({
    FoodSearchStatus? status,
    List<FoodModel>? searchResults,
    List<MealHistoryModel>? recentGroupedFoods,
    List<FoodModel>? overriddenFoods,
    List<FoodModel>? customFoods,
    List<MealTemplateModel>? templates,
    List<RecipeModel>? recipes,
    List<MealIngredientModel>? basket,
    bool? isBasketExpanded,
    String? error,
  }) {
    return FoodSearchState(
      status: status ?? this.status,
      searchResults: searchResults ?? this.searchResults,
      recentGroupedFoods: recentGroupedFoods ?? this.recentGroupedFoods,
      overriddenFoods: overriddenFoods ?? this.overriddenFoods,
      customFoods: customFoods ?? this.customFoods,
      templates: templates ?? this.templates,
      recipes: recipes ?? this.recipes,
      basket: basket ?? this.basket,
      isBasketExpanded: isBasketExpanded ?? this.isBasketExpanded,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        searchResults,
        recentGroupedFoods,
        overriddenFoods,
        customFoods,
        templates,
        recipes,
        basket,
        isBasketExpanded,
        error,
      ];
}
