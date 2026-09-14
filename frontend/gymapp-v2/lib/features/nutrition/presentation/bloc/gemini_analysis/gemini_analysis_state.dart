import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/nutrition/data/models/ai_recipe_suggestion_response_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';

enum GeminiAnalysisStatus { initial, loading, success, failure, saving, saved }

class GeminiAnalysisState extends Equatable {
  final GeminiAnalysisStatus status;
  final AiRecipeSuggestionResponseModel? suggestion;
  final DietProgramModel? mainProgram;
  final String? error;
  final bool requestSent;
  final bool savedSuccessfully;

  const GeminiAnalysisState({
    this.status = GeminiAnalysisStatus.initial,
    this.suggestion,
    this.mainProgram,
    this.error,
    this.requestSent = false,
    this.savedSuccessfully = false,
  });

  GeminiAnalysisState copyWith({
    GeminiAnalysisStatus? status,
    AiRecipeSuggestionResponseModel? suggestion,
    DietProgramModel? mainProgram,
    String? error,
    bool? requestSent,
    bool? savedSuccessfully,
  }) {
    return GeminiAnalysisState(
      status: status ?? this.status,
      suggestion: suggestion ?? this.suggestion,
      mainProgram: mainProgram ?? this.mainProgram,
      error: error ?? this.error,
      requestSent: requestSent ?? this.requestSent,
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
    );
  }

  @override
  List<Object?> get props => [status, suggestion, mainProgram, error, requestSent, savedSuccessfully];
}
