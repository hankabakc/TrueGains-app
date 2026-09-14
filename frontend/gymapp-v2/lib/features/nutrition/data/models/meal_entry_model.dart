import 'package:equatable/equatable.dart';
import 'meal_template_model.dart';

class MealItemModel extends Equatable {
  final int id;
  final int foodId;
  final String foodName;
  final String? brand;
  final double amount;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double fiber;
  final double sodium;
  final double cholesterol;
  final double potassium;

  const MealItemModel({
    required this.id,
    required this.foodId,
    required this.foodName,
    this.brand,
    required this.amount,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.sugar = 0,
    this.fiber = 0,
    this.sodium = 0,
    this.cholesterol = 0,
    this.potassium = 0,
  });

  factory MealItemModel.fromJson(Map<String, dynamic> json) {
    return MealItemModel(
      id: json['id'] as int? ?? 0,
      foodId: json['foodId'] as int? ?? 0,
      foodName: json['foodName'] as String? ?? 'Bilinmeyen',
      brand: json['brand'] as String?,
      amount: (json['amount'] as num? ?? 0).toDouble(),
      calories: (json['calories'] as num? ?? 0).toDouble(),
      protein: (json['protein'] as num? ?? 0).toDouble(),
      carbs: (json['carbs'] as num? ?? 0).toDouble(),
      fat: (json['fat'] as num? ?? 0).toDouble(),
      sugar: (json['sugar'] as num? ?? 0).toDouble(),
      fiber: (json['fiber'] as num? ?? 0).toDouble(),
      sodium: (json['sodium'] as num? ?? 0).toDouble(),
      cholesterol: (json['cholesterol'] as num? ?? 0).toDouble(),
      potassium: (json['potassium'] as num? ?? 0).toDouble(),
    );
  }

  MealItemModel copyWith({
    int? id,
    int? foodId,
    String? foodName,
    String? brand,
    double? amount,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? sugar,
    double? fiber,
    double? sodium,
    double? cholesterol,
    double? potassium,
  }) {
    return MealItemModel(
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      foodName: foodName ?? this.foodName,
      brand: brand ?? this.brand,
      amount: amount ?? this.amount,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      sugar: sugar ?? this.sugar,
      fiber: fiber ?? this.fiber,
      sodium: sodium ?? this.sodium,
      cholesterol: cholesterol ?? this.cholesterol,
      potassium: potassium ?? this.potassium,
    );
  }

  @override
  List<Object?> get props => [id, foodId, foodName, amount, calories];
}

class MealEntryModel extends Equatable {
  final int id;
  final int clientId;
  final DateTime takenDatetime;
  final MealType mealType;
  final List<MealItemModel> items;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double fiber;
  final double sodium;
  final double cholesterol;
  final double potassium;

  const MealEntryModel({
    required this.id,
    required this.clientId,
    required this.takenDatetime,
    required this.mealType,
    required this.items,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.sugar = 0,
    this.fiber = 0,
    this.sodium = 0,
    this.cholesterol = 0,
    this.potassium = 0,
  });

  factory MealEntryModel.fromJson(Map<String, dynamic> json) {
    return MealEntryModel(
      id: json['id'] as int? ?? 0,
      clientId: json['clientId'] as int? ?? 0,
      takenDatetime: DateTime.tryParse(json['takenDatetime']?.toString() ?? '') ?? DateTime.now(),
      mealType: MealType.values.firstWhere(
        (e) => e.name.toLowerCase() == json['mealType']?.toString().toLowerCase() ||
               e.toBackendString().toLowerCase() == json['mealType']?.toString().toLowerCase(),
        orElse: () => MealType.other,
      ),
      items: (json['items'] as List? ?? [])
          .map((e) => MealItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      calories: (json['calories'] as num? ?? 0).toDouble(),
      protein: (json['protein'] as num? ?? 0).toDouble(),
      carbs: (json['carbs'] as num? ?? 0).toDouble(),
      fat: (json['fat'] as num? ?? 0).toDouble(),
      sugar: (json['sugar'] as num? ?? 0).toDouble(),
      fiber: (json['fiber'] as num? ?? 0).toDouble(),
      sodium: (json['sodium'] as num? ?? 0).toDouble(),
      cholesterol: (json['cholesterol'] as num? ?? 0).toDouble(),
      potassium: (json['potassium'] as num? ?? 0).toDouble(),
    );
  }

  // Backwards compatibility with 기존 fold implementation or simplified access
  double get totalCalories => calories > 0 ? calories : items.fold(0, (sum, item) => sum + item.calories);
  double get totalProtein => protein > 0 ? protein : items.fold(0, (sum, item) => sum + item.protein);
  double get totalCarbs => carbs > 0 ? carbs : items.fold(0, (sum, item) => sum + item.carbs);
  double get totalFat => fat > 0 ? fat : items.fold(0, (sum, item) => sum + item.fat);
  double get totalSugar => sugar > 0 ? sugar : items.fold(0, (sum, item) => sum + item.sugar);
  double get totalFiber => fiber > 0 ? fiber : items.fold(0, (sum, item) => sum + item.fiber);
  double get totalSodium => sodium > 0 ? sodium : items.fold(0, (sum, item) => sum + item.sodium);
  double get totalCholesterol => cholesterol > 0 ? cholesterol : items.fold(0, (sum, item) => sum + item.cholesterol);
  double get totalPotassium => potassium > 0 ? potassium : items.fold(0, (sum, item) => sum + item.potassium);

  @override
  List<Object?> get props => [id, clientId, takenDatetime, mealType, items, calories];
}
