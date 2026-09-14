import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_source.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/recipe_model.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_dashboard/diet_dashboard_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_dashboard/diet_dashboard_state.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/food_details_page.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';

class MealCardWidget extends StatelessWidget {
  final DietDashboardState state;
  final DietDashboardCubit cubit;
  final MealModel meal;
  final VoidCallback onAddFood;
  final void Function(MealIngredientModel) onDeleteIngredient;

  const MealCardWidget({
    super.key,
    required this.state,
    required this.cubit,
    required this.meal,
    required this.onAddFood,
    required this.onDeleteIngredient,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final isCoach = authState is AuthAuthenticated && authState.auth.user.role == UserRole.COACH;
    final canEdit = isCoach || state.mainProgram?.source != DietSource.coach;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.zero,
      child: Theme(
        data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: _getMealIcon(meal.mealType),
          title: Text(
            meal.name,
            style: AppTextStyles.listTitle,
          ),
          subtitle: Text(
            '${meal.ingredients.length} besin eklendi',
            style: AppTextStyles.cardCaption.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          children: [
            ...meal.ingredients.map(
              (ing) => _buildIngredientTile(context, ing, canEdit),
            ),
            if (canEdit)
              const SizedBox(height: AppSpacing.sm),
            if (canEdit)
              Row(
                children: [
                  Expanded(
                    child: PremiumButton(
                      text: 'Besin Ekle',
                      icon: Icons.add_rounded,
                      onPressed: onAddFood,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientTile(BuildContext context, MealIngredientModel ing, bool canEdit) {
    final isRecipe = ing.recipeId != null;
    if (isRecipe) {
      return _RecipeExpansionTile(
        ingredient: ing,
        isExpanded: state.expandedRecipeIds.contains(ing.recipeId),
        isLoading: state.loadingRecipeIds.contains(ing.recipeId),
        ingredients: state.loadedRecipeIngredients[ing.recipeId],
        onToggleExpand: () => cubit.toggleRecipeExpand(ing.recipeId!),
        onDelete:
            canEdit
                ? () => onDeleteIngredient(ing)
                : null,
        onInfo: () async {
          await context.pushNamed(
            'recipe-details',
            pathParameters: {'id': ing.recipeId!.toString()},
            extra: {'isReadOnly': true, 'ingredientId': ing.id},
          );
          if (context.mounted) {
            cubit.loadData(silent: true);
          }
        },
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Expanded(
            child: Text(
              ing.foodName,
              style: AppTextStyles.bodyText.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (ing.isCustom) _buildManualTag() else if (ing.isOverridden) _buildSpecialTag(),
        ],
      ),
      subtitle: Text(
        '${ing.amount.toInt()}g • ${ing.calories.toInt()} kcal',
        style: AppTextStyles.cardCaption.copyWith(
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canEdit)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppColors.error,
              ),
              onPressed: () => onDeleteIngredient(ing),
            ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 12,
            color: AppColors.textMuted,
          ),
        ],
      ),
      onTap: () async {
        final result = await Navigator.push<dynamic>(
          context,
          MaterialPageRoute<void>(
            builder:
                (context) => FoodDetailsPage(
                  foodId: ing.foodId,
                  initialAmount: ing.amount,
                  isDashboardEdit: true,
                  // Özelleştirilmiş besinde kullanıcının kendi sürümünü göster;
                  // sadece özelleştirilmemişse orijinali göster.
                  ignoreOverride: !ing.isOverridden,
                ),
          ),
        );

        if (result is FoodModel && context.mounted && ing.id != null) {
          cubit.updateIngredientAmount(ing.id!, result.defaultAmount);
        } else if (result == true && context.mounted) {
          cubit.loadData(silent: true);
        }
      },
    );
  }

  Widget _buildManualTag() {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'MANUEL',
        style: AppTextStyles.tagText.copyWith(
          color: AppColors.textSecondary,
          fontSize: 8,
        ),
      ),
    );
  }

  Widget _buildSpecialTag() {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        'ÖZEL',
        style: AppTextStyles.tagText.copyWith(
          color: AppColors.primary,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _getMealIcon(MealType type) {
    IconData icon;
    switch (type) {
      case MealType.kahvalti:
        icon = Icons.wb_twilight_rounded;
        break;
      case MealType.ogleYemegi:
        icon = Icons.wb_sunny_rounded;
        break;
      case MealType.aksamYemegi:
        icon = Icons.nights_stay_rounded;
        break;
      default:
        icon = Icons.restaurant_rounded;
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}

class _RecipeExpansionTile extends StatelessWidget {
  final MealIngredientModel ingredient;
  final bool isExpanded;
  final bool isLoading;
  final List<RecipeIngredientModel>? ingredients;
  final VoidCallback onToggleExpand;
  final VoidCallback? onDelete;
  final VoidCallback onInfo;

  const _RecipeExpansionTile({
    required this.ingredient,
    required this.isExpanded,
    required this.isLoading,
    this.ingredients,
    required this.onToggleExpand,
    this.onDelete,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: AppColors.primary.withValues(alpha: 0.05),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: onInfo,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xxs,
            ),
            leading: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            title: Text(
              ingredient.foodName,
              style: AppTextStyles.listTitle.copyWith(
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${ingredient.amount.toStringAsFixed(1).replaceFirst(".0", "")} Porsiyon • ${ingredient.calories.toInt()} kcal',
              style: AppTextStyles.cardCaption.copyWith(
                color: AppColors.primary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: AppColors.error,
                    ),
                    onPressed: onDelete,
                  ),
                IconButton(
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: onToggleExpand,
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const Divider(
              color: AppColors.glassBorder,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              )
            else if (ingredients != null)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                itemCount: ingredients!.length,
                itemBuilder: (context, index) {
                  final item = ingredients![index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xxs,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 4,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            item.foodName,
                            style: AppTextStyles.bodyText.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${item.amount.toInt()}g',
                          style: AppTextStyles.cardCaption.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

