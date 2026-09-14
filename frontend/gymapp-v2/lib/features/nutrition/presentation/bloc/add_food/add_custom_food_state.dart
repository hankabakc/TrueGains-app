import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';

enum AddFoodStatus { idle, submitting, success, failure }

class AddCustomFoodState extends Equatable {
  final AddFoodStatus status;
  final FoodModel? createdFood;
  final String? error;

  const AddCustomFoodState({
    this.status = AddFoodStatus.idle,
    this.createdFood,
    this.error,
  });

  AddCustomFoodState copyWith({
    AddFoodStatus? status,
    FoodModel? createdFood,
    String? error,
  }) {
    return AddCustomFoodState(
      status: status ?? this.status,
      createdFood: createdFood ?? this.createdFood,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, createdFood, error];
}
