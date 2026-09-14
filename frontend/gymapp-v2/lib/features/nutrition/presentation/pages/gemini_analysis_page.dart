import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/constants/app_strings.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/features/nutrition/data/models/ai_recipe_suggestion_response_model.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/gemini_analysis/gemini_analysis_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/gemini_analysis/gemini_analysis_state.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import '../widgets/save_recipe_modal.dart';
import 'package:gymapp_v2/features/nutrition/data/models/ocr_scan_response_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';

class GeminiAnalysisPage extends StatelessWidget {
  final Object? responseData;
  final int? programId;

  const GeminiAnalysisPage({super.key, this.responseData, this.programId});

  @override
  Widget build(BuildContext context) {
    OcrScanResponseModel? ocrData;
    if (responseData is OcrScanResponseModel) {
      ocrData = responseData as OcrScanResponseModel;
    }

    return BlocProvider(
      create: (context) => sl<GeminiAnalysisCubit>()..loadInitialData(programId),
      child: BlocConsumer<GeminiAnalysisCubit, GeminiAnalysisState>(
        listener: (context, state) {
          if (state.status == GeminiAnalysisStatus.saved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.successAdded), backgroundColor: Colors.green),
            );
          } else if (state.status == GeminiAnalysisStatus.failure && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<GeminiAnalysisCubit>();

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) {
                context.pop(state.savedSuccessfully);
              }
            },
            child: Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: AppColors.background,
                elevation: 0,
                title: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      ocrData != null ? AppStrings.productAnalysis : AppStrings.aiChef, 
                      style: AppTextStyles.listTitle,
                    ),
                  ],
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                  onPressed: () => context.pop(state.savedSuccessfully),
                ),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        if (ocrData != null) ...[
                          _buildUserOcrBubble(),
                          const SizedBox(height: 16),
                          if (ocrData.foodData == null)
                            _buildErrorBubble(context, ocrData.assistantMessage)
                          else
                            _buildOcrResponseBubble(context, ocrData),
                        ] else if (!state.requestSent)
                          _buildInitialMessage()
                        else ...[
                          _buildUserBubble(),
                          const SizedBox(height: 16),
                          if (state.status == GeminiAnalysisStatus.loading)
                            _buildLoadingBubble()
                          else if (state.error != null)
                            _buildErrorBubble(context, state.error!)
                          else if (state.suggestion != null)
                            _buildAiResponseBubble(context, cubit, state),
                        ]
                      ],
                    ),
                  ),
                  if (ocrData == null) _buildChatInputArea(cubit, state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInitialMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.primary, size: 48),
          ),
          const SizedBox(height: 24),
          Text(AppStrings.aiChefReady, style: AppTextStyles.heroTitle.copyWith(color: AppColors.textPrimary, fontSize: 22)),
          const SizedBox(height: 12),
          Text(AppStrings.aiChefDesc, textAlign: TextAlign.center, style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildUserBubble() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(4))),
        child: Text(AppStrings.suggestRecipePrompt, style: AppTextStyles.bodyText.copyWith(color: Colors.black87, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildUserOcrBubble() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.primary, 
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), 
            topRight: Radius.circular(20), 
            bottomLeft: Radius.circular(20), 
            bottomRight: Radius.circular(4)
          )
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_rounded, color: Colors.black87, size: 16),
            const SizedBox(width: 8),
            Text(AppStrings.analyzeImagePrompt, 
              style: AppTextStyles.bodyText.copyWith(color: Colors.black87, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(20))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: Text(AppStrings.calculatingMacros, style: AppTextStyles.listSubtitle.copyWith(color: AppColors.textSecondary))),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBubble(BuildContext context, String error) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1), 
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), 
                topRight: Radius.circular(20), 
                bottomLeft: Radius.circular(4), 
                bottomRight: Radius.circular(20)
              ), 
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Text(AppStrings.analysisFailed, 
                      style: AppTextStyles.listTitle.copyWith(color: AppColors.error)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(error, style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(AppStrings.tryAgain),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.glassBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/nutrition/search'),
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text(AppStrings.manualAdd),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOcrResponseBubble(BuildContext context, OcrScanResponseModel ocr) {
    final food = ocr.foodData!;
    return Align(
      alignment: Alignment.centerLeft,
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(food.name, 
                    style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary, fontSize: 18))
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(food.brand ?? AppStrings.general, 
              style: AppTextStyles.listSubtitle.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            Text(ocr.assistantMessage, 
              style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary, height: 1.5)),
            const SizedBox(height: 24),
            const Divider(color: AppColors.glassBorder),
            const SizedBox(height: 16),
            _buildFoodMacrosRow(food),
            const SizedBox(height: 24),
            PremiumButton(
              text: AppStrings.addToDiary,
              icon: Icons.add_task_rounded,
              onPressed: () => context.push('/nutrition/food-details/0', extra: food),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodMacrosRow(FoodModel food) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMacroItem('Kcal', food.calories.toStringAsFixed(0), Colors.orange),
        _buildMacroItem('Pro', '${food.protein.toStringAsFixed(1)}g', AppColors.primary),
        _buildMacroItem('Karb', '${food.carbs.toStringAsFixed(1)}g', Colors.blue),
        _buildMacroItem('Yağ', '${food.fat.toStringAsFixed(1)}g', AppColors.error),
      ],
    );
  }

  Widget _buildAiResponseBubble(BuildContext context, GeminiAnalysisCubit cubit, GeminiAnalysisState state) {
    final suggestion = state.suggestion!;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(20))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(suggestion.recipeName, style: AppTextStyles.listTitle.copyWith(color: AppColors.primary, fontSize: 18))),
              ],
            ),
            const SizedBox(height: 16),
            Text(suggestion.assistantMessage, style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary, height: 1.5)),
            const SizedBox(height: 24),
            const Divider(color: AppColors.glassBorder),
            const SizedBox(height: 16),
            _buildMacrosRow(suggestion),
            const SizedBox(height: 24),
            _buildIngredientsList(suggestion),
            const SizedBox(height: 24),
            PremiumButton(
              text: state.status == GeminiAnalysisStatus.saving ? AppStrings.saving : AppStrings.saveRecipeToProgram,
              icon: state.status == GeminiAnalysisStatus.saving ? Icons.hourglass_empty : Icons.bookmark_add_rounded,
              onPressed: state.status == GeminiAnalysisStatus.saving ? null : () => _showSaveModal(context, cubit, state, suggestion),
            ),
          ],
        ),
      ),
    );
  }

  void _showSaveModal(BuildContext context, GeminiAnalysisCubit cubit, GeminiAnalysisState state, AiRecipeSuggestionResponseModel recipe) {
    if (state.mainProgram == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.noDietProgramFound), backgroundColor: AppColors.error),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollController) => SaveRecipeModal(
          program: state.mainProgram!,
          recipeId: recipe.recipeId,
          recipeName: recipe.recipeName,
          onSave: (mealId) => cubit.saveRecipe(mealId, recipe.recipeId),
        ),
      ),
    );
  }

  Widget _buildMacrosRow(AiRecipeSuggestionResponseModel suggestion) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMacroItem('Kcal', suggestion.calories.toStringAsFixed(1), Colors.orange),
        _buildMacroItem('Pro', '${suggestion.protein.toStringAsFixed(1)}g', AppColors.primary),
        _buildMacroItem('Karb', '${suggestion.carbs.toStringAsFixed(1)}g', Colors.blue),
        _buildMacroItem('Yağ', '${suggestion.fat.toStringAsFixed(1)}g', AppColors.error),
      ],
    );
  }

  Widget _buildMacroItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.listTitle.copyWith(color: color)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildIngredientsList(AiRecipeSuggestionResponseModel suggestion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.ingredients, style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ...suggestion.ingredients.map((ingredient) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: AppColors.textMuted, size: 6),
                  const SizedBox(width: 8),
                  Expanded(child: Text(ingredient.foodName, style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary))),
                  Text('${ingredient.amount} ${ingredient.unit}', style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildChatInputArea(GeminiAnalysisCubit cubit, GeminiAnalysisState state) {
    bool hasSuggestion = state.suggestion != null;
    bool isLoading = state.status == GeminiAnalysisStatus.loading;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: AppColors.background, border: Border(top: BorderSide(color: AppColors.glassBorder))),
      child: SafeArea(
        child: IgnorePointer(
          ignoring: isLoading,
          child: GestureDetector(
            onTap: () => cubit.getSuggestion(programId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(color: isLoading ? AppColors.surface : AppColors.surface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: isLoading ? Colors.transparent : AppColors.glassBorder)),
              child: Row(
                children: [
                  Expanded(child: Text(hasSuggestion ? AppStrings.suggestAnotherRecipe : AppStrings.suggestRecipePrompt, style: AppTextStyles.bodyText.copyWith(color: isLoading ? AppColors.textMuted : AppColors.textSecondary))),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: isLoading ? AppColors.primary.withValues(alpha: 0.3) : AppColors.primary, shape: BoxShape.circle),
                    child: Icon(hasSuggestion ? Icons.refresh_rounded : Icons.send_rounded, color: isLoading ? AppColors.textMuted : Colors.black87, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
