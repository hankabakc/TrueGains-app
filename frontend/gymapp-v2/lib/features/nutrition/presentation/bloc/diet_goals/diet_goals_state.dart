import 'package:equatable/equatable.dart';

enum DietGoalsStatus { initial, saving, success, failure }

class DietGoalsState extends Equatable {
  final DietGoalsStatus status;
  final bool isGramMode;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double fiber;
  final double sodium;
  final double cholesterol;
  final double potassium;
  final String? error;

  const DietGoalsState({
    this.status = DietGoalsStatus.initial,
    this.isGramMode = false,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.sugar = 0,
    this.fiber = 0,
    this.sodium = 0,
    this.cholesterol = 0,
    this.potassium = 0,
    this.error,
  });

  DietGoalsState copyWith({
    DietGoalsStatus? status,
    bool? isGramMode,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? sugar,
    double? fiber,
    double? sodium,
    double? cholesterol,
    double? potassium,
    String? error,
  }) {
    return DietGoalsState(
      status: status ?? this.status,
      isGramMode: isGramMode ?? this.isGramMode,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      sugar: sugar ?? this.sugar,
      fiber: fiber ?? this.fiber,
      sodium: sodium ?? this.sodium,
      cholesterol: cholesterol ?? this.cholesterol,
      potassium: potassium ?? this.potassium,
      // Hata GEÇİCİDİR: her copyWith'te yeniden değerlendirilir (sticky olmaz). Aksi
      // halde bir kez hata oluşunca her state değişiminde tekrar gösterilir.
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        isGramMode,
        calories,
        protein,
        carbs,
        fat,
        sugar,
        fiber,
        sodium,
        cholesterol,
        potassium,
        error,
      ];
}
