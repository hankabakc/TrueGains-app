import 'package:equatable/equatable.dart';

class AiRecipeSuggestionResponseModel extends Equatable {
  final int recipeId;
  final String recipeName;
  final String assistantMessage;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final List<IngredientDto> ingredients;

  const AiRecipeSuggestionResponseModel({
    required this.recipeId,
    required this.recipeName,
    required this.assistantMessage,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.ingredients,
  });

  factory AiRecipeSuggestionResponseModel.fromJson(Map<String, dynamic> json) {
    return AiRecipeSuggestionResponseModel(
      recipeId: json['recipeId'] as int,
      recipeName: json['recipeName'] as String,
      assistantMessage: json['assistantMessage'] as String,
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => IngredientDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipeId': recipeId,
      'recipeName': recipeName,
      'assistantMessage': assistantMessage,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        recipeId,
        recipeName,
        assistantMessage,
        calories,
        protein,
        carbs,
        fat,
        ingredients,
      ];
}

class IngredientDto extends Equatable {
  final String foodName;
  final double amount;
  final String unit;

  const IngredientDto({
    required this.foodName,
    required this.amount,
    required this.unit,
  });

  factory IngredientDto.fromJson(Map<String, dynamic> json) {
    return IngredientDto(
      foodName: json['foodName'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodName': foodName,
      'amount': amount,
      'unit': unit,
    };
  }

  @override
  List<Object?> get props => [foodName, amount, unit];
}
