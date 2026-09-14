import 'package:equatable/equatable.dart';
import 'meal_template_model.dart';

class RecipeModel extends Equatable {
  final int id;
  final String name;
  final String? description;
  final String? instructions;
  final String? category;
  final String? imageUrl;
  final DateTime createdAt;
  final List<RecipeIngredientModel> ingredients;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  const RecipeModel({
    required this.id,
    required this.name,
    this.description,
    this.instructions,
    this.category,
    this.imageUrl,
    required this.createdAt,
    required this.ingredients,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  MealIngredientModel toIngredient() {
    return MealIngredientModel(
      foodName: name,
      amount: 1, // Represents 1 portion/whole recipe
      defaultAmount: 1,
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      isBrandVerified: false,
      ignoreOverride: false,
      isOverridden: false,
      sugar: 0,
      fiber: 0,
      sodium: 0,
      potassium: 0,
      cholesterol: 0,
      recipeId: id,
    );
  }

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final List<RecipeIngredientModel> ingredients = (json['ingredients'] as List?)
              ?.map((e) => RecipeIngredientModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

    double totalCalories = (json['totalCalories'] as num?)?.toDouble() ?? 0.0;
    double totalProtein = (json['totalProtein'] as num?)?.toDouble() ?? 0.0;
    double totalCarbs = (json['totalCarbs'] as num?)?.toDouble() ?? 0.0;
    double totalFat = (json['totalFat'] as num?)?.toDouble() ?? 0.0;

    // 🛡️ SAVUNMA HATTI: Eğer sunucudan 0 geldiyse ama malzemeler varsa, yerel olarak hesapla
    if (totalCalories == 0 && ingredients.isNotEmpty) {
      for (var ing in ingredients) {
        totalCalories += ing.calories;
        totalProtein += ing.protein;
        totalCarbs += ing.carbs;
        totalFat += ing.fat;
      }
    }

    return RecipeModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      instructions: json['instructions'] as String?,
      category: json['category'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      ingredients: ingredients,
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'instructions': instructions,
      'category': category,
      'imageUrl': imageUrl,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        totalCalories,
        ingredients,
      ];

  RecipeModel copyWith({
    String? name,
    String? description,
    String? instructions,
    String? category,
    String? imageUrl,
    List<RecipeIngredientModel>? ingredients,
  }) {
    final newIngredients = ingredients ?? this.ingredients;

    double totalKcal = 0;
    double totalP = 0;
    double totalC = 0;
    double totalF = 0;

    for (var ing in newIngredients) {
      totalKcal += ing.calories;
      totalP += ing.protein;
      totalC += ing.carbs;
      totalF += ing.fat;
    }

    return RecipeModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      ingredients: newIngredients,
      totalCalories: totalKcal,
      totalProtein: totalP,
      totalCarbs: totalC,
      totalFat: totalF,
    );
  }
}

class RecipeIngredientModel extends Equatable {
  final int id;
  final int foodId;
  final String foodName;
  final String? brand;
  final double amount;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String unit;
  final bool isModified;

  const RecipeIngredientModel({
    required this.id,
    required this.foodId,
    required this.foodName,
    this.brand,
    required this.amount,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.unit,
    this.isModified = false,
  });

  factory RecipeIngredientModel.fromJson(Map<String, dynamic> json) {
    return RecipeIngredientModel(
      id: json['id'] as int,
      foodId: json['foodId'] as int,
      foodName: json['foodName'] as String,
      brand: json['brand'] as String?,
      amount: (json['amount'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'g',
      isModified: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'amount': amount,
    };
  }

  @override
  List<Object?> get props => [id, foodId, amount, isModified];

  RecipeIngredientModel copyWith({
    double? amount,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    bool? isModified,
  }) {
    return RecipeIngredientModel(
      id: id,
      foodId: foodId,
      foodName: foodName,
      brand: brand,
      amount: amount ?? this.amount,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      unit: unit,
      isModified: isModified ?? this.isModified,
    );
  }
}
