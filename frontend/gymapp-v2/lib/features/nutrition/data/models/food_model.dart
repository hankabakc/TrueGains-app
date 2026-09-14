import 'package:equatable/equatable.dart';
import 'meal_template_model.dart';

class FoodModel extends Equatable {
  final int? id; // ID null olabilir (Kaydedilmemiş global ürünler için)
  final String name;
  final String? brand;
  final String? category;
  final String defaultUnit;
  final double defaultAmount;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? sugar;
  final double? fiber;
  final double? sodium;
  final double? cholesterol;
  final double? potassium;
  final double? satFat;
  final double? transFat;
  final double? monoFat;
  final double? polyFat;
  final bool isOverridden;
  final bool isBrandVerified;
  final bool isCustom;
  final String? barcode;
  final DateTime? createdAt;

  const FoodModel({
    this.id,
    required this.name,
    this.brand,
    this.category,
    required this.defaultUnit,
    required this.defaultAmount,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.sugar,
    this.fiber,
    this.sodium,
    this.cholesterol,
    this.potassium,
    this.satFat,
    this.transFat,
    this.monoFat,
    this.polyFat,
    this.isOverridden = false,
    this.isBrandVerified = false,
    this.isCustom = false,
    this.barcode,
    this.createdAt,
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? 'Bilinmeyen Ürün',
      brand: json['brand'] as String?,
      category: json['category'] as String?,
      defaultUnit: json['defaultUnit'] as String? ?? 'g',
      defaultAmount: (json['defaultAmount'] as num? ?? 100).toDouble(),
      calories: (json['calories'] as num? ?? 0).toDouble(),
      protein: (json['protein'] as num? ?? 0).toDouble(),
      carbs: (json['carbs'] as num? ?? 0).toDouble(),
      fat: (json['fat'] as num? ?? 0).toDouble(),
      sugar: (json['sugar'] as num?)?.toDouble(),
      fiber: (json['fiber'] as num?)?.toDouble(),
      sodium: (json['sodium'] as num?)?.toDouble(),
      cholesterol: (json['cholesterol'] as num?)?.toDouble(),
      potassium: (json['potassium'] as num?)?.toDouble(),
      satFat: (json['satFat'] as num?)?.toDouble(),
      transFat: (json['transFat'] as num?)?.toDouble(),
      monoFat: (json['monoFat'] as num?)?.toDouble(),
      polyFat: (json['polyFat'] as num?)?.toDouble(),
      isOverridden: json['isOverridden'] as bool? ?? false,
      isBrandVerified: json['isBrandVerified'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? json['custom'] as bool? ?? false,
      barcode: json['barcode'] as String?,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
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
      'satFat': satFat,
      'transFat': transFat,
      'monoFat': monoFat,
      'polyFat': polyFat,
      'barcode': barcode,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'brand': brand,
      'category': category,
      'defaultUnit': defaultUnit,
      'defaultAmount': defaultAmount,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'sugar': sugar,
      'fiber': fiber,
      'sodium': sodium,
      'cholesterol': cholesterol,
      'potassium': potassium,
      'satFat': satFat,
      'transFat': transFat,
      'monoFat': monoFat,
      'polyFat': polyFat,
    };
  }

  @override
  List<Object?> get props => [id, name, isOverridden, barcode, isBrandVerified];

  FoodModel copyWith({
    int? id,
    String? name,
    String? brand,
    String? category,
    String? defaultUnit,
    double? defaultAmount,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? sugar,
    double? fiber,
    double? sodium,
    double? cholesterol,
    double? potassium,
    double? satFat,
    double? transFat,
    double? monoFat,
    double? polyFat,
    bool? isOverridden,
    bool? isBrandVerified,
    String? barcode,
    DateTime? createdAt,
  }) {
    return FoodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      defaultUnit: defaultUnit ?? this.defaultUnit,
      defaultAmount: defaultAmount ?? this.defaultAmount,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      sugar: sugar ?? this.sugar,
      fiber: fiber ?? this.fiber,
      sodium: sodium ?? this.sodium,
      cholesterol: cholesterol ?? this.cholesterol,
      potassium: potassium ?? this.potassium,
      satFat: satFat ?? this.satFat,
      transFat: transFat ?? this.transFat,
      monoFat: monoFat ?? this.monoFat,
      polyFat: polyFat ?? this.polyFat,
      isOverridden: isOverridden ?? this.isOverridden,
      isBrandVerified: isBrandVerified ?? this.isBrandVerified,
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  MealIngredientModel toIngredient(double amount, {bool ignoreOverride = false}) {
    return MealIngredientModel(
      foodId: id!,
      foodName: name,
      brand: brand,
      amount: amount,
      defaultAmount: defaultAmount,
      protein: protein,
      carbs: carbs,
      fat: fat,
      calories: calories,
      isBrandVerified: isBrandVerified,
      ignoreOverride: ignoreOverride,
      isOverridden: isOverridden,
      isCustom: isCustom,
      sugar: sugar ?? 0.0,
      fiber: fiber ?? 0.0,
      sodium: sodium ?? 0.0,
      potassium: potassium ?? 0.0,
      cholesterol: cholesterol ?? 0.0,
    );
  }
}
