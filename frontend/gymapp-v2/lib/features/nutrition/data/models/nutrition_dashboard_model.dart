import 'package:equatable/equatable.dart';

class NutritionDashboardModel extends Equatable {
  final DailySummaryModel dailySummary;
  final WeeklySummaryModel weeklySummary;
  final List<FoodFrequencyModel> frequentFoods;
  final List<NutrientAnalysisModel> nutrientAnalysis;
  final bool hasActiveProgram;

  const NutritionDashboardModel({
    required this.dailySummary,
    required this.weeklySummary,
    required this.frequentFoods,
    required this.nutrientAnalysis,
    required this.hasActiveProgram,
  });

  factory NutritionDashboardModel.fromJson(Map<String, dynamic> json) {
    return NutritionDashboardModel(
      dailySummary: DailySummaryModel.fromJson(json['dailySummary'] as Map<String, dynamic>),
      weeklySummary: WeeklySummaryModel.fromJson(json['weeklySummary'] as Map<String, dynamic>),
      frequentFoods: (json['frequentFoods'] as List? ?? [])
          .map((e) => FoodFrequencyModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      nutrientAnalysis: (json['nutrientAnalysis'] as List? ?? [])
          .map((e) => NutrientAnalysisModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasActiveProgram: (json['hasActiveProgram'] as bool?) ?? false,
    );
  }

  @override
  List<Object?> get props => [dailySummary, weeklySummary, frequentFoods, nutrientAnalysis, hasActiveProgram];
}

class DailySummaryModel extends Equatable {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double fiber;
  final double sodium;
  final double cholesterol;
  final double potassium;
  final List<MealTypeBreakdownModel> mealBreakdown;
  final List<FoodFrequencyModel> dailyFoods;

  const DailySummaryModel({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sugar,
    required this.fiber,
    required this.sodium,
    required this.cholesterol,
    required this.potassium,
    required this.mealBreakdown,
    required this.dailyFoods,
  });

  factory DailySummaryModel.fromJson(Map<String, dynamic> json) {
    return DailySummaryModel(
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      sugar: (json['sugar'] as num).toDouble(),
      fiber: (json['fiber'] as num).toDouble(),
      sodium: (json['sodium'] as num).toDouble(),
      cholesterol: (json['cholesterol'] as num).toDouble(),
      potassium: (json['potassium'] as num).toDouble(),
      mealBreakdown: (json['mealBreakdown'] as List? ?? [])
          .map((e) => MealTypeBreakdownModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      dailyFoods: (json['dailyFoods'] as List? ?? [])
          .map((e) => FoodFrequencyModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [calories, protein, carbs, fat, sugar, fiber, sodium, cholesterol, potassium, mealBreakdown, dailyFoods];
}

class MealTypeBreakdownModel extends Equatable {
  final String mealLabel;
  final double calories;
  final double percentage;

  const MealTypeBreakdownModel({
    required this.mealLabel,
    required this.calories,
    required this.percentage,
  });

  factory MealTypeBreakdownModel.fromJson(Map<String, dynamic> json) {
    return MealTypeBreakdownModel(
      mealLabel: json['mealLabel'] as String,
      calories: (json['calories'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [mealLabel, calories, percentage];
}

class WeeklySummaryModel extends Equatable {
  final List<DailySummaryModel> dailyLogs;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final double targetSugar;
  final double targetFiber;
  final double targetSodium;
  final double targetCholesterol;
  final double targetPotassium;

  const WeeklySummaryModel({
    required this.dailyLogs,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    required this.targetSugar,
    required this.targetFiber,
    required this.targetSodium,
    required this.targetCholesterol,
    required this.targetPotassium,
  });

  factory WeeklySummaryModel.fromJson(Map<String, dynamic> json) {
    return WeeklySummaryModel(
      dailyLogs: (json['dailyLogs'] as List)
          .map((e) => DailySummaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCalories: (json['totalCalories'] as num).toDouble(),
      totalProtein: (json['totalProtein'] as num).toDouble(),
      totalCarbs: (json['totalCarbs'] as num).toDouble(),
      totalFat: (json['totalFat'] as num).toDouble(),
      targetCalories: (json['targetCalories'] as num).toDouble(),
      targetProtein: (json['targetProtein'] as num).toDouble(),
      targetCarbs: (json['targetCarbs'] as num).toDouble(),
      targetFat: (json['targetFat'] as num).toDouble(),
      targetSugar: (json['targetSugar'] as num? ?? 0).toDouble(),
      targetFiber: (json['targetFiber'] as num? ?? 0).toDouble(),
      targetSodium: (json['targetSodium'] as num? ?? 0).toDouble(),
      targetCholesterol: (json['targetCholesterol'] as num? ?? 0).toDouble(),
      targetPotassium: (json['targetPotassium'] as num? ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        dailyLogs,
        totalCalories,
        totalProtein,
        totalCarbs,
        totalFat,
        targetCalories,
        targetProtein,
        targetCarbs,
        targetFat,
        targetSugar,
        targetFiber,
        targetSodium,
        targetCholesterol,
        targetPotassium,
      ];
}

class FoodFrequencyModel extends Equatable {
  final String foodName;
  final int count;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  const FoodFrequencyModel({
    required this.foodName,
    required this.count,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  factory FoodFrequencyModel.fromJson(Map<String, dynamic> json) {
    return FoodFrequencyModel(
      foodName: json['foodName'] as String,
      count: json['count'] as int,
      totalCalories: (json['totalCalories'] as num).toDouble(),
      totalProtein: (json['totalProtein'] as num).toDouble(),
      totalCarbs: (json['totalCarbs'] as num).toDouble(),
      totalFat: (json['totalFat'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [foodName, count, totalCalories, totalProtein, totalCarbs, totalFat];
}

class NutrientAnalysisModel extends Equatable {
  final String nutrientName;
  final double target;
  final double reached;
  final double difference;
  final String unit;

  const NutrientAnalysisModel({
    required this.nutrientName,
    required this.target,
    required this.reached,
    required this.difference,
    required this.unit,
  });

  factory NutrientAnalysisModel.fromJson(Map<String, dynamic> json) {
    return NutrientAnalysisModel(
      nutrientName: json['nutrientName'] as String,
      target: (json['target'] as num).toDouble(),
      reached: (json['reached'] as num).toDouble(),
      difference: (json['difference'] as num).toDouble(),
      unit: json['unit'] as String,
    );
  }

  @override
  List<Object?> get props => [nutrientName, target, reached, difference, unit];
}
