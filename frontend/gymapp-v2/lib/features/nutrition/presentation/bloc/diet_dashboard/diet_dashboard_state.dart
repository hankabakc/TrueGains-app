import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/recipe_model.dart';

const Object _kUnset = Object();

enum DietDashboardStatus { initial, loading, success, failure }

class DietDashboardState extends Equatable {
  final DietDashboardStatus status;
  final DietProgramModel? mainProgram;
  final int selectedDayIndex;
  final String? error;

  // Recipe expansion management
  final Set<int> expandedRecipeIds;
  final Map<int, List<RecipeIngredientModel>> loadedRecipeIngredients;
  final Set<int> loadingRecipeIds;

  const DietDashboardState({
    this.status = DietDashboardStatus.initial,
    this.mainProgram,
    this.selectedDayIndex = 0,
    this.error,
    this.expandedRecipeIds = const {},
    this.loadedRecipeIngredients = const {},
    this.loadingRecipeIds = const {},
  });

  DietDashboardState copyWith({
    DietDashboardStatus? status,
    Object? mainProgram = _kUnset,
    int? selectedDayIndex,
    String? error,
    Set<int>? expandedRecipeIds,
    Map<int, List<RecipeIngredientModel>>? loadedRecipeIngredients,
    Set<int>? loadingRecipeIds,
  }) {
    return DietDashboardState(
      status: status ?? this.status,
      mainProgram: identical(mainProgram, _kUnset)
          ? this.mainProgram
          : mainProgram as DietProgramModel?,
      selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
      error: error ?? this.error,
      expandedRecipeIds: expandedRecipeIds ?? this.expandedRecipeIds,
      loadedRecipeIngredients: loadedRecipeIngredients ?? this.loadedRecipeIngredients,
      loadingRecipeIds: loadingRecipeIds ?? this.loadingRecipeIds,
    );
  }

  @override
  List<Object?> get props => [
    status,
    mainProgram,
    selectedDayIndex,
    error,
    expandedRecipeIds,
    loadedRecipeIngredients,
    loadingRecipeIds,
  ];
}
