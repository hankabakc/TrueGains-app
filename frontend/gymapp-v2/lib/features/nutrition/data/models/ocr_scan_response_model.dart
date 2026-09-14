import 'package:equatable/equatable.dart';
import 'food_model.dart';

class OcrScanResponseModel extends Equatable {
  final FoodModel? foodData;
  final String assistantMessage;
  final int remainingScans;
  final bool limitReached;

  const OcrScanResponseModel({
    this.foodData,
    required this.assistantMessage,
    required this.remainingScans,
    required this.limitReached,
  });

  factory OcrScanResponseModel.fromJson(Map<String, dynamic> json) {
    return OcrScanResponseModel(
      foodData: json['foodData'] != null
          ? FoodModel.fromJson(json['foodData'] as Map<String, dynamic>)
          : null,
      assistantMessage: json['assistantMessage'] as String? ?? '',
      remainingScans: json['remainingScans'] as int? ?? 0,
      limitReached: json['limitReached'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [foodData, assistantMessage, remainingScans, limitReached];
}
