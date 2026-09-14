import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/nutrition/data/models/recipe_model.dart';

enum RecipeDetailsStatus { initial, loading, success, failure }

class RecipeDetailsState extends Equatable {
  final RecipeDetailsStatus status;
  final RecipeModel? recipe;
  final String? error;

  const RecipeDetailsState({
    this.status = RecipeDetailsStatus.initial,
    this.recipe,
    this.error,
  });

  RecipeDetailsState copyWith({
    RecipeDetailsStatus? status,
    RecipeModel? recipe,
    String? error,
  }) {
    return RecipeDetailsState(
      status: status ?? this.status,
      recipe: recipe ?? this.recipe,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, recipe, error];
}
