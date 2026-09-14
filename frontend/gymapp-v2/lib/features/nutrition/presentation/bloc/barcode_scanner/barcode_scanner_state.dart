import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';

abstract class BarcodeScannerState extends Equatable {
  const BarcodeScannerState();
  @override
  List<Object?> get props => [];
}

class BarcodeScannerInitial extends BarcodeScannerState {}
class BarcodeScannerLoading extends BarcodeScannerState {}
class BarcodeScannerSuccess extends BarcodeScannerState {
  final FoodModel food;
  const BarcodeScannerSuccess(this.food);
  @override
  List<Object?> get props => [food];
}
class BarcodeScannerError extends BarcodeScannerState {
  final String message;
  const BarcodeScannerError(this.message);
  @override
  List<Object?> get props => [message];
}
