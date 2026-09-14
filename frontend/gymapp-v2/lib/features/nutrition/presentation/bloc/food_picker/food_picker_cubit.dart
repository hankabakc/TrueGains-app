import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'food_picker_state.dart';
import '../../../data/models/food_model.dart';

class FoodPickerCubit extends Cubit<FoodPickerState> {
  final NutritionRepository _repository;

  FoodPickerCubit(this._repository) : super(const FoodPickerState());

  Future<void> loadInitialData() async {
    emit(state.copyWith(status: FoodPickerStatus.loading));
    final results = await Future.wait([
      _repository.getRecentFoods(),
      _repository.getTemplates(),
    ]);

    emit(state.copyWith(
      status: FoodPickerStatus.success,
      recentFoods: results[0].success ? (results[0].data as List).cast<FoodModel>() : [],
      templates: results[1].success ? (results[1].data as List).cast() : [],
    ));
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    emit(state.copyWith(status: FoodPickerStatus.searching, searchResults: []));

    final response = await _repository.searchFood(query);
    if (response.success) {
      emit(state.copyWith(status: FoodPickerStatus.success, searchResults: response.data ?? []));
    } else {
      emit(state.copyWith(status: FoodPickerStatus.failure, error: response.message));
    }
  }

  void selectFood(FoodModel food) {
    emit(state.copyWith(selectedFood: food, amount: 100.0));
  }

  void updateAmount(double amount) {
    emit(state.copyWith(amount: amount));
  }

  Future<void> addIngredient(int mealId) async {
    if (state.selectedFood?.id == null) return;
    emit(state.copyWith(status: FoodPickerStatus.adding));

    final response = await _repository.addIngredient(
      mealId,
      state.amount,
      foodId: state.selectedFood!.id,
    );

    if (response.success) {
      emit(state.copyWith(status: FoodPickerStatus.added));
    } else {
      emit(state.copyWith(status: FoodPickerStatus.failure, error: response.message));
    }
  }

  void clearSearch() {
    emit(state.copyWith(searchResults: []));
  }
}
