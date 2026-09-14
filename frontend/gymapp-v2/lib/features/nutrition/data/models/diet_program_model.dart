import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/social/data/models/coach_profile_model.dart';
import 'meal_template_model.dart'; // Import central MealType and MealIngredientModel
import 'diet_source.dart';

class MealModel extends Equatable {
  final int id;
  final MealType mealType;
  final String? customName;
  final int orderIndex;
  final List<MealIngredientModel> ingredients;

  const MealModel({
    required this.id,
    required this.mealType,
    this.customName,
    required this.orderIndex,
    required this.ingredients,
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id'] as int,
      mealType: MealType.values.firstWhere(
        (e) {
          final typeStr = json['mealType'].toString().toUpperCase();
          // Map English backend names for robustness
          if (typeStr == 'BREAKFAST') return e == MealType.kahvalti;
          if (typeStr == 'LUNCH') return e == MealType.ogleYemegi;
          if (typeStr == 'DINNER') return e == MealType.aksamYemegi;
          return e.name.toUpperCase() == typeStr;
        },
        orElse: () => MealType.other,
      ),
      customName: json['name'] as String?,
      orderIndex: json['orderIndex'] as int,
      ingredients:
          (json['ingredients'] as List)
              .map(
                (e) => MealIngredientModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  // Belirli bir makro türü için toplam değeri hesaplar (Backend'den hazır gelen mutlak değerleri toplar)
  double getTotalNutrient(double Function(MealIngredientModel) selector) {
    return ingredients.fold(0, (sum, item) => sum + selector(item));
  }

  String get name {
    if (customName != null && customName!.isNotEmpty) return customName!;
    switch (mealType) {
      case MealType.kahvalti:
        return 'Kahvaltı';
      case MealType.ogleYemegi:
        return 'Öğle Yemeği';
      case MealType.aksamYemegi:
        return 'Akşam Yemeği';
      default:
        return 'Diğer';
    }
  }

  String get type => mealType.name.toUpperCase();

  @override
  List<Object?> get props => [id, ingredients, mealType, customName];
}

class DietDayModel extends Equatable {
  final int id;
  final int dayOrder;
  final String name;
  final List<MealModel> meals;

  const DietDayModel({
    required this.id,
    required this.dayOrder,
    required this.name,
    required this.meals,
  });

  factory DietDayModel.fromJson(Map<String, dynamic> json) {
    final int order = json['dayOrder'] as int;
    final String originalName = json['name'] as String;

    // GÜN 1, GÜN 2 gibi isimleri haftalık gün isimlerine dönüştür
    String displayName = originalName;
    if (order >= 1 && order <= 7) {
      const dayNames = [
        'Pazartesi',
        'Salı',
        'Çarşamba',
        'Perşembe',
        'Cuma',
        'Cumartesi',
        'Pazar'
      ];
      displayName = dayNames[order - 1];
    }

    return DietDayModel(
      id: json['id'] as int,
      dayOrder: order,
      name: displayName,
      meals:
          (json['meals'] as List)
              .map((e) => MealModel.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  @override
  List<Object?> get props => [id, dayOrder, name, meals];
}

class DietProgramModel extends Equatable {
  final int id;
  final int? ownerId;
  final String name;
  final bool isMain;
  final bool isTemplate;
  final DietSource source;
  final CoachProfileModel? coach;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? version;
  final List<DietDayModel> dietDays;
  final String? description;
  final double targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final double targetSugar;
  final double targetFiber;
  final double targetSodium;
  final double targetCholesterol;
  final double targetPotassium;
  final bool isOrphaned;

  const DietProgramModel({
    required this.id,
    this.ownerId,
    required this.name,
    required this.isMain,
    required this.isTemplate,
    required this.source,
    this.coach,
    required this.createdAt,
    this.updatedAt,
    this.version,
    required this.dietDays,
    this.description,
    this.targetCalories = 0,
    this.targetProtein = 0,
    this.targetCarbs = 0,
    this.targetFat = 0,
    this.targetSugar = 0,
    this.targetFiber = 0,
    this.targetSodium = 0,
    this.targetCholesterol = 0,
    this.targetPotassium = 0,
    this.isOrphaned = false,
  });

  factory DietProgramModel.fromJson(Map<String, dynamic> json) {
    return DietProgramModel(
      id: json['id'] as int,
      ownerId: json['ownerId'] as int?,
      name: json['name'] as String,
      isMain: json['isMain'] as bool,
      isTemplate: json['isTemplate'] as bool? ?? false,
      source: DietSource.fromString(json['source'] as String?),
      coach:
          json['coach'] != null
              ? CoachProfileModel.fromJson(
                json['coach'] as Map<String, dynamic>,
              )
              : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : null,
      version: json['version'] as int?,
      dietDays:
          (json['dietDays'] as List? ?? [])
              .map((e) => DietDayModel.fromJson(e as Map<String, dynamic>))
              .toList(),
      description: json['description'] as String?,
      targetCalories: (json['targetCalories'] as num? ?? 0).toDouble(),
      targetProtein: (json['targetProtein'] as num? ?? 0).toDouble(),
      targetCarbs: (json['targetCarbs'] as num? ?? 0).toDouble(),
      targetFat: (json['targetFat'] as num? ?? 0).toDouble(),
      targetSugar: (json['targetSugar'] as num? ?? 0).toDouble(),
      targetFiber: (json['targetFiber'] as num? ?? 0).toDouble(),
      targetSodium: (json['targetSodium'] as num? ?? 0).toDouble(),
      targetCholesterol: (json['targetCholesterol'] as num? ?? 0).toDouble(),
      targetPotassium: (json['targetPotassium'] as num? ?? 0).toDouble(),
      isOrphaned: (json['isOrphaned'] ?? json['is_orphaned']) as bool? ?? false,
    );
  }

  Map<String, double> getTotalNutrientsForDay(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= dietDays.length) {
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    }

    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    double sugar = 0;
    double fiber = 0;
    double sodium = 0;
    double cholesterol = 0;
    double potassium = 0;

    for (var meal in dietDays[dayIndex].meals) {
      calories += meal.getTotalNutrient((f) => f.calories);
      protein += meal.getTotalNutrient((f) => f.protein);
      carbs += meal.getTotalNutrient((f) => f.carbs);
      fat += meal.getTotalNutrient((f) => f.fat);
      sugar += meal.getTotalNutrient((f) => f.sugar);
      fiber += meal.getTotalNutrient((f) => f.fiber);
      sodium += meal.getTotalNutrient((f) => f.sodium);
      cholesterol += meal.getTotalNutrient((f) => f.cholesterol);
      potassium += meal.getTotalNutrient((f) => f.potassium);
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'sugar': sugar,
      'fiber': fiber,
      'sodium': sodium,
      'cholesterol': cholesterol,
      'potassium': potassium,
    };
  }

  ({String text, int diff}) getCalorieStatus(int dayIndex) {
    if (targetCalories <= 0) {
      return (text: 'Hedef belirlenmedi', diff: 0);
    }

    final plannedCal = getTotalNutrientsForDay(dayIndex)['calories'] ?? 0;
    final calDiff = (targetCalories - plannedCal).toInt();

    if (calDiff.abs() <= 50) {
      return (text: 'Hedefe tam uyuyor!', diff: calDiff);
    } else if (calDiff > 0) {
      return (text: '$calDiff kcal eksik', diff: calDiff);
    } else {
      return (text: '${calDiff.abs()} kcal fazla', diff: calDiff);
    }
  }

  @override
  List<Object?> get props => [id, name, isMain, isTemplate, source, dietDays, version, updatedAt, isOrphaned];
}
