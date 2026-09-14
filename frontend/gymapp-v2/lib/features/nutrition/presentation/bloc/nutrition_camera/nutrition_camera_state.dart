import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/core/constants/app_strings.dart';

enum NutritionCameraStatus { initial, analyzing, success, failure }

class NutritionCameraState extends Equatable {
  final NutritionCameraStatus status;
  final String loadingMessage;
  final dynamic scanResult;
  final String? error;

  const NutritionCameraState({
    this.status = NutritionCameraStatus.initial,
    this.loadingMessage = AppStrings.analyzingImage,
    this.scanResult,
    this.error,
  });

  NutritionCameraState copyWith({
    NutritionCameraStatus? status,
    String? loadingMessage,
    dynamic scanResult,
    String? error,
  }) {
    return NutritionCameraState(
      status: status ?? this.status,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      scanResult: scanResult ?? this.scanResult,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, loadingMessage, scanResult, error];
}
