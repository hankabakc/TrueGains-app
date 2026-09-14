import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'food_details_state.dart';

class FoodDetailsCubit extends Cubit<FoodDetailsState> {
  final NutritionRepository _repository;

  FoodDetailsCubit(this._repository) : super(const FoodDetailsState());

  void initialize({
    int? foodId,
    String? barcode,
    FoodModel? extraFood,
    double? initialAmount,
    bool ignoreOverride = false,
  }) async {
    emit(state.copyWith(
      status: FoodDetailsStatus.loading,
      ignoreOverride: ignoreOverride,
      consumedAmount: initialAmount ?? extraFood?.defaultAmount ?? 100.0,
    ));

    try {
      FoodModel? food;
      if (extraFood != null) {
        food = extraFood;
      } else if (barcode != null) {
        final res = await _repository.getFoodByBarcode(barcode);
        food = res.data;
      } else if (foodId != null) {
        final res = await _repository.getFoodDetails(foodId, ignoreOverride: ignoreOverride);
        food = res.data;
      }

      if (food != null) {
        emit(state.copyWith(
          status: FoodDetailsStatus.success,
          food: food,
          protein: food.protein,
          carbs: food.carbs,
          fat: food.fat,
          sugar: food.sugar ?? 0,
          fiber: food.fiber ?? 0,
          sodium: food.sodium ?? 0,
          cholesterol: food.cholesterol ?? 0,
          potassium: food.potassium ?? 0,
          satFat: food.satFat ?? 0,
          transFat: food.transFat ?? 0,
          monoFat: food.monoFat ?? 0,
          polyFat: food.polyFat ?? 0,
        ));
      } else {
        emit(state.copyWith(status: FoodDetailsStatus.failure, error: 'Besin bulunamadı.'));
      }
    } catch (e) {
      emit(state.copyWith(status: FoodDetailsStatus.failure, error: friendlyError(e)));
    }
  }

  void updateConsumedAmount(double amount) {
    emit(state.copyWith(consumedAmount: amount));
  }

  void toggleEditing() {
    emit(state.copyWith(isEditing: !state.isEditing));
  }

  void updateEditingValue(String type, double value) {
    switch (type) {
      case 'protein': emit(state.copyWith(protein: value)); break;
      case 'carbs': emit(state.copyWith(carbs: value)); break;
      case 'fat': emit(state.copyWith(fat: value)); break;
      case 'sugar': emit(state.copyWith(sugar: value)); break;
      case 'fiber': emit(state.copyWith(fiber: value)); break;
      case 'sodium': emit(state.copyWith(sodium: value)); break;
      case 'cholesterol': emit(state.copyWith(cholesterol: value)); break;
      case 'potassium': emit(state.copyWith(potassium: value)); break;
      case 'satFat': emit(state.copyWith(satFat: value)); break;
      case 'transFat': emit(state.copyWith(transFat: value)); break;
      case 'monoFat': emit(state.copyWith(monoFat: value)); break;
      case 'polyFat': emit(state.copyWith(polyFat: value)); break;
    }
  }

  Future<void> saveOverride() async {
    if (state.food == null) return;
    emit(state.copyWith(status: FoodDetailsStatus.saving));

    final calculatedCalories = (state.protein * 4) + (state.carbs * 4) + (state.fat * 9);

    final updatedFood = FoodModel(
      id: state.food!.id,
      name: state.food!.name,
      defaultUnit: state.food!.defaultUnit,
      defaultAmount: state.food!.defaultAmount,
      calories: calculatedCalories,
      protein: state.protein,
      carbs: state.carbs,
      fat: state.fat,
      sugar: state.sugar,
      fiber: state.fiber,
      sodium: state.sodium,
      cholesterol: state.cholesterol,
      potassium: state.potassium,
      satFat: state.satFat,
      transFat: state.transFat,
      monoFat: state.monoFat,
      polyFat: state.polyFat,
      isOverridden: true,
      isBrandVerified: state.food!.isBrandVerified,
      barcode: state.food!.barcode,
    );

    try {
      if (state.food!.id != null) {
        await _repository.overrideFood(state.food!.id!, updatedFood);
        emit(state.copyWith(status: FoodDetailsStatus.saved, food: updatedFood, isEditing: false, ignoreOverride: false));
      } else {
        emit(state.copyWith(status: FoodDetailsStatus.saved, food: updatedFood));
      }
    } catch (e) {
      emit(state.copyWith(status: FoodDetailsStatus.failure, error: friendlyError(e)));
    }
  }

  Future<void> deleteOverride() async {
    if (state.food?.id == null) return;
    emit(state.copyWith(status: FoodDetailsStatus.loading));

    final res = await _repository.deleteOverride(state.food!.id!);
    if (res.success) {
      initialize(foodId: state.food!.id, ignoreOverride: true);
    } else {
      emit(state.copyWith(status: FoodDetailsStatus.failure, error: res.message));
    }
  }
}
