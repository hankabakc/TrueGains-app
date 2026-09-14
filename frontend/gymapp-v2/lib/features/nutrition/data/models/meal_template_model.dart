import 'package:equatable/equatable.dart';

enum MealType {
  kahvalti,
  ogleYemegi,
  aksamYemegi,
  other
}

extension MealTypeExtension on MealType {
  String get trName {
    switch (this) {
      case MealType.kahvalti: return 'Kahvaltı';
      case MealType.ogleYemegi: return 'Öğle Yemeği';
      case MealType.aksamYemegi: return 'Akşam Yemeği';
      case MealType.other: return 'Diğer';
    }
  }

  static MealType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'KAHVALTI': return MealType.kahvalti;
      case 'OGLE_YEMEGI': return MealType.ogleYemegi;
      case 'AKSAM_YEMEGI': return MealType.aksamYemegi;
      default: return MealType.other;
    }
  }

  String toBackendString() {
    switch (this) {
      case MealType.kahvalti: return 'KAHVALTI';
      case MealType.ogleYemegi: return 'OGLE_YEMEGI';
      case MealType.aksamYemegi: return 'AKSAM_YEMEGI';
      case MealType.other: return 'OTHER';
    }
  }
}

class MealTemplateModel extends Equatable {
  final int id;
  final String name;
  final List<MealType> applicableMealTypes;
  final List<MealIngredientModel> ingredients;

  const MealTemplateModel({
    required this.id,
    required this.name,
    required this.applicableMealTypes,
    required this.ingredients,
  });

  factory MealTemplateModel.fromJson(Map<String, dynamic> json) {
    return MealTemplateModel(
      id: json['id'] as int,
      name: json['name'] as String,
      applicableMealTypes: (json['applicableMealTypes'] as List?)
              ?.map((e) => MealTypeExtension.fromString(e.toString()))
              .toList() ??
          [],
      ingredients: (json['ingredients'] as List?)
              ?.map((e) => MealIngredientModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [id, name, applicableMealTypes];
}

class MealTemplateDetailModel extends Equatable {
  final int id;
  final String name;
  final List<MealType> applicableMealTypes;
  final List<MealIngredientModel> ingredients;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalSugar;
  final double totalFiber;
  final double totalSodium;
  final double totalPotassium;
  final double totalCholesterol;

  const MealTemplateDetailModel({
    required this.id,
    required this.name,
    required this.applicableMealTypes,
    required this.ingredients,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalSugar,
    required this.totalFiber,
    required this.totalSodium,
    required this.totalPotassium,
    required this.totalCholesterol,
  });

  factory MealTemplateDetailModel.fromJson(Map<String, dynamic> json) {
    return MealTemplateDetailModel(
      id: json['id'] as int,
      name: json['name'] as String,
      applicableMealTypes: (json['applicableMealTypes'] as List?)
              ?.map((e) => MealTypeExtension.fromString(e.toString()))
              .toList() ??
          [],
      ingredients: (json['ingredients'] as List?)
              ?.map((e) => MealIngredientModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCalories: (json['totalCalories'] as num?)?.toDouble() ?? 0.0,
      totalProtein: (json['totalProtein'] as num?)?.toDouble() ?? 0.0,
      totalCarbs: (json['totalCarbs'] as num?)?.toDouble() ?? 0.0,
      totalFat: (json['totalFat'] as num?)?.toDouble() ?? 0.0,
      totalSugar: (json['totalSugar'] as num?)?.toDouble() ?? 0.0,
      totalFiber: (json['totalFiber'] as num?)?.toDouble() ?? 0.0,
      totalSodium: (json['totalSodium'] as num?)?.toDouble() ?? 0.0,
      totalPotassium: (json['totalPotassium'] as num?)?.toDouble() ?? 0.0,
      totalCholesterol: (json['totalCholesterol'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [id, name, totalCalories];
}

// ignore: must_be_immutable
class MealIngredientModel extends Equatable {
  final int? id;
  final int? foodId;
  final String foodName;
  final String? brand;
  final String? note;
  double amount; // Mutable for basket logic
  final double defaultAmount; // Base amount (100 for foods, 1 for recipes)
  final double protein;
  final double carbs;
  final double fat;
  final double calories;
  final bool isBrandVerified;
  final bool ignoreOverride;
  final bool isOverridden;
  final bool isCustom;
  final double sugar;
  final double fiber;
  final double sodium;
  final double potassium;
  final double cholesterol;
  final int? recipeId;

  MealIngredientModel({
    this.id,
    this.foodId,
    required this.foodName,
    this.brand,
    this.note,
    required this.amount,
    required this.defaultAmount,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calories,
    required this.isBrandVerified,
    required this.ignoreOverride,
    required this.isOverridden,
    this.isCustom = false,
    required this.sugar,
    required this.fiber,
    required this.sodium,
    required this.potassium,
    required this.cholesterol,
    this.recipeId,
  });

  factory MealIngredientModel.fromJson(Map<String, dynamic> json) {
    return MealIngredientModel(
      id: json['id'] as int?,
      foodId: json['foodId'] as int?,
      foodName: json['foodName'] as String,
      brand: json['brand'] as String?,
      note: json['note'] as String?,
      amount: (json['amount'] as num).toDouble(),
      defaultAmount: (json['defaultAmount'] as num?)?.toDouble() ?? 100.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      isBrandVerified: json['isBrandVerified'] as bool? ?? false,
      ignoreOverride: json['ignoreOverride'] as bool? ?? false,
      isOverridden: json['isOverridden'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? json['custom'] as bool? ?? false,
      sugar: (json['sugar'] as num?)?.toDouble() ?? 0.0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
      sodium: (json['sodium'] as num?)?.toDouble() ?? 0.0,
      potassium: (json['potassium'] as num?)?.toDouble() ?? 0.0,
      cholesterol: (json['cholesterol'] as num?)?.toDouble() ?? 0.0,
      recipeId: json['recipeId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'amount': amount,
      'ignoreOverride': ignoreOverride,
      'isOverridden': isOverridden,
      'isCustom': isCustom,
      'note': note,
      if (recipeId != null) 'recipeId': recipeId,
    };
  }

  MealIngredientModel copyWith({
    int? id,
    int? foodId,
    String? foodName,
    String? brand,
    String? note,
    double? amount,
    double? defaultAmount,
    double? protein,
    double? carbs,
    double? fat,
    double? calories,
    bool? isBrandVerified,
    bool? ignoreOverride,
    bool? isOverridden,
    bool? isCustom,
    double? sugar,
    double? fiber,
    double? sodium,
    double? potassium,
    double? cholesterol,
    int? recipeId,
  }) {
    return MealIngredientModel(
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      foodName: foodName ?? this.foodName,
      brand: brand ?? this.brand,
      note: note ?? this.note,
      amount: amount ?? this.amount,
      defaultAmount: defaultAmount ?? this.defaultAmount,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      calories: calories ?? this.calories,
      isBrandVerified: isBrandVerified ?? this.isBrandVerified,
      ignoreOverride: ignoreOverride ?? this.ignoreOverride,
      isOverridden: isOverridden ?? this.isOverridden,
      isCustom: isCustom ?? this.isCustom,
      sugar: sugar ?? this.sugar,
      fiber: fiber ?? this.fiber,
      sodium: sodium ?? this.sodium,
      potassium: potassium ?? this.potassium,
      cholesterol: cholesterol ?? this.cholesterol,
      recipeId: recipeId ?? this.recipeId,
    );
  }

  /// Eşitlik **görünen tüm değerleri** kapsar.
  ///
  /// Önceden yalnızca kimlik ve miktar alanları vardı; besin adı, marka ve makro
  /// değerleri dışarıdaydı. Bunun asıl tehlikesi `==` çağıran kod değil, **BLoC state
  /// karşılaştırmasıydı**: state içindeki liste eskisiyle eşit sayılırsa `emit` atlanır ve
  /// ekran güncellenmez. Ezme (override) uygulandığında miktar aynı kalıp makrolar
  /// değişebildiği için bu, sessizce eski değerleri gösteren bir ekran demekti.
  ///
  /// Yön güvenli: eksik eşitlik **atlanan** yeniden çizim üretir, tam eşitlik en fazla
  /// **fazladan** çizim üretir.
  @override
  List<Object?> get props => [
        id,
        foodId,
        foodName,
        brand,
        note,
        amount,
        defaultAmount,
        protein,
        carbs,
        fat,
        calories,
        isBrandVerified,
        ignoreOverride,
        isOverridden,
        isCustom,
        sugar,
        fiber,
        sodium,
        potassium,
        cholesterol,
        recipeId,
      ];
}
