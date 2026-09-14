import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'package:gymapp_v2/core/util/tdee_calculator.dart';
import 'diet_goals_state.dart';

class DietGoalsCubit extends Cubit<DietGoalsState> {
  final NutritionRepository _repository;

  DietGoalsCubit(this._repository) : super(const DietGoalsState());

  void initialize(DietProgramModel program) {
    double targetCal = program.targetCalories > 0 ? program.targetCalories : 2000;

    // Default to percentages if not in gram mode
    double p, c, f;
    if (program.targetProtein > 0 || program.targetCarbs > 0 || program.targetFat > 0) {
      p = ((program.targetProtein * 4 / targetCal) * 100);
      c = ((program.targetCarbs * 4 / targetCal) * 100);
      f = ((program.targetFat * 9 / targetCal) * 100);
    } else {
      p = 20; c = 50; f = 30;
    }

    emit(state.copyWith(
      calories: targetCal,
      protein: p,
      carbs: c,
      fat: f,
      sugar: program.targetSugar,
      fiber: program.targetFiber,
      sodium: program.targetSodium,
      cholesterol: program.targetCholesterol,
      potassium: program.targetPotassium,
    ));
  }

  void toggleMode() {
    final bool newMode = !state.isGramMode;
    double p = state.protein;
    double c = state.carbs;
    double f = state.fat;
    double cals = state.calories;

    if (newMode) { // To Gram Mode
      p = (cals * (p / 100)) / 4;
      c = (cals * (c / 100)) / 4;
      f = (cals * (f / 100)) / 9;
    } else { // To Percent Mode
      if (cals > 0) {
        p = (p * 4 / cals) * 100;
        c = (c * 4 / cals) * 100;
        f = (f * 9 / cals) * 100;
      }
    }

    emit(state.copyWith(
      isGramMode: newMode,
      protein: p,
      carbs: c,
      fat: f,
    ));
  }

  void updateNutrient(String type, double value) {
    switch (type) {
      case 'calories':
        emit(state.copyWith(calories: value));
        break;
      case 'protein':
        emit(state.copyWith(protein: value));
        _recalculateCaloriesIfGramMode();
        break;
      case 'carbs':
        emit(state.copyWith(carbs: value));
        _recalculateCaloriesIfGramMode();
        break;
      case 'fat':
        emit(state.copyWith(fat: value));
        _recalculateCaloriesIfGramMode();
        break;
      case 'sugar': emit(state.copyWith(sugar: value)); break;
      case 'fiber': emit(state.copyWith(fiber: value)); break;
      case 'sodium': emit(state.copyWith(sodium: value)); break;
      case 'cholesterol': emit(state.copyWith(cholesterol: value)); break;
      case 'potassium': emit(state.copyWith(potassium: value)); break;
    }
  }

  void _recalculateCaloriesIfGramMode() {
    if (state.isGramMode) {
      double newCal = (state.protein * 4) + (state.carbs * 4) + (state.fat * 9);
      emit(state.copyWith(calories: newCal));
    }
  }

  void applySmartGoal(double tdee) {
    if (state.isGramMode) {
      final macros = macrosFromCalories(tdee);
      emit(state.copyWith(
        calories: tdee,
        protein: macros.protein,
        carbs: macros.carbs,
        fat: macros.fat,
      ));
    } else {
      emit(state.copyWith(
        calories: tdee,
        protein: 20,
        carbs: 50,
        fat: 30,
      ));
    }
  }

  Future<void> save(int programId) async {
    double pG, cG, fG;
    if (state.isGramMode) {
      pG = state.protein;
      cG = state.carbs;
      fG = state.fat;
    } else {
      double total = state.protein + state.carbs + state.fat;
      // Yuvarlama payı için küçük tolerans (gramlardan türeyen yüzdeler tam 100 olmayabilir).
      if (total > 0 && (total - 100).abs() > 1.5) {
        emit(state.copyWith(error: 'Toplam makro yüzdesi 100 olmalıdır!'));
        return;
      }
      pG = (state.calories * (state.protein / 100)) / 4;
      cG = (state.calories * (state.carbs / 100)) / 4;
      fG = (state.calories * (state.fat / 100)) / 9;
    }

    if (state.calories <= 0) {
      emit(state.copyWith(error: "Kalori hedefi 0'dan büyük olmalıdır."));
      return;
    }

    emit(state.copyWith(status: DietGoalsStatus.saving, error: null));

    final res = await _repository.updateProgramGoals(
      programId,
      targetCalories: state.calories,
      targetProtein: pG,
      targetCarbs: cG,
      targetFat: fG,
      targetSugar: state.sugar,
      targetFiber: state.fiber,
      targetSodium: state.sodium,
      targetCholesterol: state.cholesterol,
      targetPotassium: state.potassium,
    );

    if (res.success) {
      emit(state.copyWith(status: DietGoalsStatus.success));
    } else {
      emit(state.copyWith(status: DietGoalsStatus.failure, error: res.message));
    }
  }
}
