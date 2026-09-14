import 'food_model.dart';

class MealHistoryModel {
  final String mealType;
  final List<FoodModel> foods;

  MealHistoryModel({
    required this.mealType,
    required this.foods,
  });

  factory MealHistoryModel.fromJson(Map<String, dynamic> json) {
    return MealHistoryModel(
      mealType: json['mealType'] as String? ?? 'DIĞER',
      foods: (json['foods'] as List<dynamic>?)
              ?.map((f) => FoodModel.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static String getDisplayName(String mealType) {
    switch (mealType.toUpperCase()) {
      case 'BREAKFAST':
      case 'KAHVALTI':
        return 'KAHVALTI';
      case 'LUNCH':
      case 'OGLE_YEMEGI':
        return 'ÖĞLE YEMEĞİ';
      case 'DINNER':
      case 'AKSAM_YEMEGI':
        return 'AKŞAM YEMEĞİ';
      case 'SPOR_ONCESI':
        return 'SPOR ÖNCESİ';
      case 'SPOR_SONRASI':
        return 'SPOR SONRASI';
      case 'GECE_OGUNU':
        return 'GECE ÖĞÜNÜ';
      case 'OTHER':
        return 'DİĞER';
      default:
        return mealType.toUpperCase().replaceAll('_', ' ');
    }
  }
}
