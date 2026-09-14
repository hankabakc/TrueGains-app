import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';

enum MealTemplateEditorStatus { initial, loading, success, saving, saved, failure }

class MealTemplateEditorState extends Equatable {
  final MealTemplateEditorStatus status;
  final String name;
  final List<MealType> selectedMealTypes;
  final List<MealIngredientModel> ingredients;
  final int currentPage;
  final String? error;

  /// Yeni şablon için sunucuda açılan kayıt. Kaydetme iki adımlıdır (önce kayıt
  /// açılır, sonra içeriği yazılır); ikinci adım başarısız olursa kullanıcı tekrar
  /// dener. Bu kimlik hatırlanmazsa her denemede yeni bir boş şablon oluşur.
  final int? createdTemplateId;

  const MealTemplateEditorState({
    this.status = MealTemplateEditorStatus.initial,
    this.name = '',
    this.selectedMealTypes = const [],
    this.ingredients = const [],
    this.currentPage = 0,
    this.error,
    this.createdTemplateId,
  });

  MealTemplateEditorState copyWith({
    MealTemplateEditorStatus? status,
    String? name,
    List<MealType>? selectedMealTypes,
    List<MealIngredientModel>? ingredients,
    int? currentPage,
    String? error,
    int? createdTemplateId,
  }) {
    return MealTemplateEditorState(
      status: status ?? this.status,
      name: name ?? this.name,
      selectedMealTypes: selectedMealTypes ?? this.selectedMealTypes,
      ingredients: ingredients ?? this.ingredients,
      currentPage: currentPage ?? this.currentPage,
      error: error ?? this.error,
      createdTemplateId: createdTemplateId ?? this.createdTemplateId,
    );
  }

  @override
  List<Object?> get props =>
      [status, name, selectedMealTypes, ingredients, currentPage, error, createdTemplateId];
}
