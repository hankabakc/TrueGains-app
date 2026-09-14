import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';

enum FoodDetailsStatus { initial, loading, success, saving, saved, failure }

class FoodDetailsState extends Equatable {
  final FoodDetailsStatus status;
  final FoodModel? food;
  final double consumedAmount;
  final bool isEditing;
  final bool ignoreOverride;
  final String? error;

  // Editing values
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double fiber;
  final double sodium;
  final double cholesterol;
  final double potassium;
  final double satFat;
  final double transFat;
  final double monoFat;
  final double polyFat;

  const FoodDetailsState({
    this.status = FoodDetailsStatus.initial,
    this.food,
    this.consumedAmount = 100.0,
    this.isEditing = false,
    this.ignoreOverride = false,
    this.error,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.sugar = 0,
    this.fiber = 0,
    this.sodium = 0,
    this.cholesterol = 0,
    this.potassium = 0,
    this.satFat = 0,
    this.transFat = 0,
    this.monoFat = 0,
    this.polyFat = 0,
  });

  FoodDetailsState copyWith({
    FoodDetailsStatus? status,
    FoodModel? food,
    double? consumedAmount,
    bool? isEditing,
    bool? ignoreOverride,
    String? error,
    double? protein,
    double? carbs,
    double? fat,
    double? sugar,
    double? fiber,
    double? sodium,
    double? cholesterol,
    double? potassium,
    double? satFat,
    double? transFat,
    double? monoFat,
    double? polyFat,
  }) {
    return FoodDetailsState(
      status: status ?? this.status,
      food: food ?? this.food,
      consumedAmount: consumedAmount ?? this.consumedAmount,
      isEditing: isEditing ?? this.isEditing,
      ignoreOverride: ignoreOverride ?? this.ignoreOverride,
      error: error ?? this.error,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      sugar: sugar ?? this.sugar,
      fiber: fiber ?? this.fiber,
      sodium: sodium ?? this.sodium,
      cholesterol: cholesterol ?? this.cholesterol,
      potassium: potassium ?? this.potassium,
      satFat: satFat ?? this.satFat,
      transFat: transFat ?? this.transFat,
      monoFat: monoFat ?? this.monoFat,
      polyFat: polyFat ?? this.polyFat,
    );
  }

  double calculateValue(double? baseValue) {
    if (baseValue == null) return 0.0;
    final defaultAmount = food?.defaultAmount ?? 100.0;
    final divisor = (defaultAmount > 0) ? defaultAmount : 100.0;
    return (baseValue / divisor) * consumedAmount;
  }

  @override
  List<Object?> get props => [
        status,
        food,
        consumedAmount,
        isEditing,
        ignoreOverride,
        error,
        protein,
        carbs,
        fat,
        sugar,
        fiber,
        sodium,
        cholesterol,
        potassium,
        satFat,
        transFat,
        monoFat,
        polyFat,
      ];
}
