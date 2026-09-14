import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'gemini_analysis_state.dart';
import '../../../data/models/ai_recipe_suggestion_response_model.dart';

class GeminiAnalysisCubit extends Cubit<GeminiAnalysisState> {
  final NutritionRepository _repository;

  // Static cache for session persistence
  static AiRecipeSuggestionResponseModel? _cachedSuggestion;

  GeminiAnalysisCubit(this._repository) : super(const GeminiAnalysisState());

  Future<void> loadInitialData(int? programId) async {
    emit(state.copyWith(status: GeminiAnalysisStatus.loading));

    // Load main program
    final progResp = programId != null
      ? await _repository.getProgramById(programId)
      : await _repository.getMainProgram();
    if (isClosed) return;

    if (progResp.success) {
      emit(state.copyWith(mainProgram: progResp.data));
    }

    // Check cache
    if (_cachedSuggestion != null) {
      emit(state.copyWith(
        status: GeminiAnalysisStatus.success,
        suggestion: _cachedSuggestion,
        requestSent: true,
      ));
      return;
    }

    // Fetch last suggestion from API
    final suggestionResp = await _repository.getLastAiSuggestion();
    if (isClosed) return;
    if (suggestionResp.success && suggestionResp.data != null) {
      _cachedSuggestion = suggestionResp.data;
      emit(state.copyWith(
        status: GeminiAnalysisStatus.success,
        suggestion: suggestionResp.data,
        requestSent: true,
      ));
    } else {
      emit(state.copyWith(status: GeminiAnalysisStatus.initial));
    }
  }

  Future<void> getSuggestion(int? programId) async {
    emit(state.copyWith(status: GeminiAnalysisStatus.loading, requestSent: true, error: null));

    final response = await _repository.suggestRecipe(programId: programId);
    if (isClosed) return; // ponytail: kullanıcı AI isteği dönmeden ekrandan çıkabilir

    if (response.success && response.data != null) {
      _cachedSuggestion = response.data;
      emit(state.copyWith(status: GeminiAnalysisStatus.success, suggestion: response.data));
    } else {
      emit(state.copyWith(status: GeminiAnalysisStatus.failure, error: response.message));
    }
  }

  Future<void> saveRecipe(int mealId, int recipeId) async {
    emit(state.copyWith(status: GeminiAnalysisStatus.saving));

    final response = await _repository.saveRecipe(mealId, recipeId);
    if (isClosed) return;

    if (response.success) {
      emit(state.copyWith(status: GeminiAnalysisStatus.saved, savedSuccessfully: true));
      // Refresh program data
      final progResp = await _repository.getMainProgram();
      if (isClosed) return;
      if (progResp.success) {
        emit(state.copyWith(mainProgram: progResp.data));
      }
    } else {
      emit(state.copyWith(status: GeminiAnalysisStatus.failure, error: response.message));
    }
  }
}
