import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'add_custom_food_state.dart';

class AddCustomFoodCubit extends Cubit<AddCustomFoodState> {
  final NutritionRepository _repository;

  AddCustomFoodCubit(this._repository) : super(const AddCustomFoodState());

  Future<void> submit(FoodModel food) async {
    emit(state.copyWith(status: AddFoodStatus.submitting, error: null));
    final res = await _repository.createFood(food);
    if (res.success) {
      emit(state.copyWith(status: AddFoodStatus.success, createdFood: res.data));
    } else {
      emit(state.copyWith(status: AddFoodStatus.failure, error: res.message));
    }
  }
}
