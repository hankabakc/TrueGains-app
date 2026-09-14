import 'package:equatable/equatable.dart';
import 'meal_template_model.dart';
import 'meal_entry_model.dart';

class DailyDietLogModel extends Equatable {
  final List<PlannedMealModel> plannedMeals;
  final List<MealEntryModel> extraEntries;

  const DailyDietLogModel({
    required this.plannedMeals,
    required this.extraEntries,
  });

  factory DailyDietLogModel.fromJson(Map<String, dynamic> json) {
    return DailyDietLogModel(
      plannedMeals: (json['plannedMeals'] as List)
          .map((e) => PlannedMealModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      extraEntries: (json['extraEntries'] as List)
          .map((e) => MealEntryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [plannedMeals, extraEntries];
}

class PlannedMealModel extends Equatable {
  final int mealId;
  final MealType mealType;
  final List<MealIngredientModel> plannedIngredients;
  final bool isConsumed;
  final int? mealEntryId;
  final List<int>? consumedIngredientIds;

  const PlannedMealModel({
    required this.mealId,
    required this.mealType,
    required this.plannedIngredients,
    required this.isConsumed,
    this.mealEntryId,
    this.consumedIngredientIds,
  });

  factory PlannedMealModel.fromJson(Map<String, dynamic> json) {
    return PlannedMealModel(
      mealId: json['mealId'] as int,
      mealType: MealTypeExtension.fromString(json['mealType'] as String),
      plannedIngredients: (json['plannedIngredients'] as List)
          .map((e) => MealIngredientModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isConsumed: json['isConsumed'] as bool,
      mealEntryId: json['mealEntryId'] as int?,
      consumedIngredientIds: (json['consumedIngredientIds'] as List?)?.cast<int>(),
    );
  }

  @override
  List<Object?> get props => [mealId, mealType, isConsumed, mealEntryId, consumedIngredientIds];
}
