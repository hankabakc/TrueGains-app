import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/features/nutrition/data/models/recipe_model.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/recipe_details/recipe_details_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/recipe_details/recipe_details_state.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';

class RecipeDetailsPage extends StatelessWidget {
  final int recipeId;
  final bool isReadOnly;

  const RecipeDetailsPage({
    super.key,
    required this.recipeId,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<RecipeDetailsCubit>()..loadRecipe(recipeId),
      child: BlocBuilder<RecipeDetailsCubit, RecipeDetailsState>(
        builder: (context, state) {
          if (state.status == RecipeDetailsStatus.loading) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }

          final recipe = state.recipe;
          if (recipe == null) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
              body: Center(child: Text(state.error ?? 'Tarif bulunamadı.', style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary))),
            );
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context, recipe),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(recipe),
                        const SizedBox(height: AppSpacing.xl),
                        _buildNutrients(recipe),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSectionTitle('Malzemeler'),
                        const SizedBox(height: AppSpacing.md),
                        _buildIngredientsList(recipe),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSectionTitle('Hazırlanışı'),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                           recipe.instructions ?? 'Talimat eklenmemiş.',
                           style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary, fontSize: 15, height: 1.6),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            bottomSheet: _buildBottomBar(context, recipe),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, RecipeModel recipe) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (recipe.imageUrl != null)
              Image.network(
                recipe.imageUrl!,
                fit: BoxFit.fitWidth,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.glassWhite,
                  child: const Icon(Icons.restaurant, color: AppColors.textMuted, size: 100),
                ),
              )
            else
              Container(color: AppColors.glassWhite, child: const Icon(Icons.restaurant, color: AppColors.textMuted, size: 100)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeader(RecipeModel recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipe.category?.toUpperCase() ?? 'TARİF',
          style: AppTextStyles.sectionLabel.copyWith(
            color: AppColors.primary,
            fontSize: 12,
            letterSpacing: 1.5
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          recipe.name,
          style: AppTextStyles.heroDisplay.copyWith(color: AppColors.textPrimary, fontSize: 32),
        ),
        if (recipe.description != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            recipe.description!,
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary, fontSize: 15, height: 1.5),
          ),
        ],
      ],
    );
  }

  Widget _buildNutrients(RecipeModel recipe) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildNutrientItem('Kalori', '${recipe.totalCalories.toInt()}', 'kcal', AppColors.primary),
        const SizedBox(width: 24),
        _buildNutrientItem('Protein', '${recipe.totalProtein.toInt()}', 'g', AppColors.protein),
        const SizedBox(width: 24),
        _buildNutrientItem('Karb.', '${recipe.totalCarbs.toInt()}', 'g', AppColors.carbs),
        const SizedBox(width: 24),
        _buildNutrientItem('Yağ', '${recipe.totalFat.toInt()}', 'g', AppColors.fat),
      ],
    );
  }

  Widget _buildNutrientItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.cardLabel.copyWith(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: AppTextStyles.cardValue.copyWith(color: color, fontSize: 20)),
            const SizedBox(width: AppSpacing.xxs),
            Text(unit, style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.emptyTitle.copyWith(color: AppColors.textPrimary, fontSize: 18),
    );
  }

  Widget _buildIngredientsList(RecipeModel recipe) {
    return Column(
      children: recipe.ingredients.map((ingredient) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  ingredient.foodName,
                  style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${ingredient.amount.toInt()} ${ingredient.unit}',
                style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(BuildContext context, RecipeModel recipe) {
    if (isReadOnly) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PremiumButton(
            text: 'DİYETE EKLE',
            onPressed: () => Navigator.pop(context, [recipe.toIngredient()]),
            icon: Icons.add_shopping_cart_rounded,
          ),
        ],
      ),
    );
  }
}
