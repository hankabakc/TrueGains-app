import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_entry_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_entry_model.dart';

enum DietEntryStatus { initial, loading, success, failure }

class DietEntryState extends Equatable {
  final DietEntryStatus status;
  final DateTime selectedDate;
  final DietProgramModel? mainProgram;
  final DailyDietLogModel? log;
  final Map<int, Set<int>> localSelections; // mealId -> Set<ingredientId>
  final String? error;

  const DietEntryState({
    required this.selectedDate,
    this.status = DietEntryStatus.initial,
    this.mainProgram,
    this.log,
    this.localSelections = const {},
    this.error,
  });

  DietEntryState copyWith({
    DietEntryStatus? status,
    DateTime? selectedDate,
    DietProgramModel? mainProgram,
    DailyDietLogModel? log,
    Map<int, Set<int>>? localSelections,
    String? error,
  }) {
    return DietEntryState(
      status: status ?? this.status,
      selectedDate: selectedDate ?? this.selectedDate,
      mainProgram: mainProgram ?? this.mainProgram,
      log: log ?? this.log,
      localSelections: localSelections ?? this.localSelections,
      error: error ?? this.error,
    );
  }

  // Helper getters for UI totals
  double get totalCalories => _calculateTotal((ing) => ing.calories, (e) => e.totalCalories);
  double get totalProtein => _calculateTotal((ing) => ing.protein, (e) => e.totalProtein);
  double get totalCarbs => _calculateTotal((ing) => ing.carbs, (e) => e.totalCarbs);
  double get totalFat => _calculateTotal((ing) => ing.fat, (e) => e.totalFat);
  double get totalSugar => _calculateTotal((ing) => ing.sugar, (e) => e.totalSugar);
  double get totalFiber => _calculateTotal((ing) => ing.fiber, (e) => e.totalFiber);
  double get totalSodium => _calculateTotal((ing) => ing.sodium, (e) => e.totalSodium);
  double get totalCholesterol => _calculateTotal((ing) => ing.cholesterol, (e) => e.totalCholesterol);
  double get totalPotassium => _calculateTotal((ing) => ing.potassium, (e) => e.totalPotassium);

  /// Hedef kalori. Program hedefi yoksa (0) o günün **planlanan** toplamı hedef sayılır.
  /// Panel ile günlük aynı sayıyı göstersin diye tek yerde hesaplanır.
  double get targetCalories {
    final programTarget = mainProgram?.targetCalories ?? 0;
    if (programTarget > 0) return programTarget;
    double planned = 0;
    for (final meal in log?.plannedMeals ?? const <PlannedMealModel>[]) {
      for (final ing in meal.plannedIngredients) {
        planned += ing.calories;
      }
    }
    return planned;
  }

  double _calculateTotal(double Function(MealIngredientModel) ingSelector, double Function(MealEntryModel) entrySelector) {
    if (log == null) return 0;
    double total = 0;

    // Planned meals
    for (final meal in log!.plannedMeals) {
      final selected = localSelections[meal.mealId] ?? {};
      for (final ing in meal.plannedIngredients) {
        if (ing.id != null && selected.contains(ing.id)) {
          total += ingSelector(ing);
        }
      }
    }

    // Extra entries
    for (final entry in log!.extraEntries) {
      total += entrySelector(entry);
    }

    return total;
  }

  @override
  List<Object?> get props => [status, selectedDate, mainProgram, log, localSelections, error];
}
