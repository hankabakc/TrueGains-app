import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';

enum FoodPickerStatus { initial, loading, searching, success, failure, adding, added }

class FoodPickerState extends Equatable {
  final FoodPickerStatus status;
  final List<FoodModel> searchResults;
  final List<FoodModel> recentFoods;
  final List<MealTemplateModel> templates;
  final FoodModel? selectedFood;
  final double amount;
  final String? error;

  const FoodPickerState({
    this.status = FoodPickerStatus.initial,
    this.searchResults = const [],
    this.recentFoods = const [],
    this.templates = const [],
    this.selectedFood,
    this.amount = 100.0,
    this.error,
  });

  FoodPickerState copyWith({
    FoodPickerStatus? status,
    List<FoodModel>? searchResults,
    List<FoodModel>? recentFoods,
    List<MealTemplateModel>? templates,
    FoodModel? selectedFood,
    double? amount,
    String? error,
  }) {
    return FoodPickerState(
      status: status ?? this.status,
      searchResults: searchResults ?? this.searchResults,
      recentFoods: recentFoods ?? this.recentFoods,
      templates: templates ?? this.templates,
      selectedFood: selectedFood ?? this.selectedFood,
      amount: amount ?? this.amount,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, searchResults, recentFoods, templates, selectedFood, amount, error];
}
