import 'package:flutter/material.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/macro_ring_stat.dart';
import 'package:gymapp_v2/core/widgets/nutrient_chip.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_dashboard/diet_dashboard_state.dart';

class MacroBoardWidget extends StatelessWidget {
  final DietDashboardState state;

  const MacroBoardWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.mainProgram == null) return const SizedBox();

    final dayNutrients = state.mainProgram!.getTotalNutrientsForDay(
      state.selectedDayIndex,
    );
    final plannedCal = dayNutrients['calories'] ?? 0;
    final plannedPro = dayNutrients['protein'] ?? 0;
    final plannedCarb = dayNutrients['carbs'] ?? 0;
    final plannedFat = dayNutrients['fat'] ?? 0;
    final plannedSugar = dayNutrients['sugar'] ?? 0;
    final plannedFiber = dayNutrients['fiber'] ?? 0;
    final plannedSod = dayNutrients['sodium'] ?? 0;
    final plannedChol = dayNutrients['cholesterol'] ?? 0;
    final plannedPot = dayNutrients['potassium'] ?? 0;

    final status = state.mainProgram!.getCalorieStatus(state.selectedDayIndex);

    Color statusColor;
    if (state.mainProgram!.targetCalories <= 0) {
      statusColor = AppColors.textMuted;
    } else if (status.diff.abs() <= 50) {
      statusColor = AppColors.success;
    } else if (status.diff > 0) {
      statusColor = AppColors.textSecondary;
    } else {
      statusColor = AppColors.error;
    }

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROGRAM ANALİZİ',
                    style: AppTextStyles.sectionLabel.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${plannedCal.toInt()}',
                        style: AppTextStyles.heroDisplay.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 42,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        ' / ${state.mainProgram!.targetCalories.toInt()} kcal',
                        style: AppTextStyles.bodyText.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    status.text,
                    style: AppTextStyles.bodyText.copyWith(
                      color: statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MacroRingStat(
                label: 'KALORİ',
                current: plannedCal,
                target: state.mainProgram!.targetCalories,
                color: status.diff < -50 ? AppColors.error : AppColors.primary,
                isCalories: true,
              ),
              MacroRingStat(
                label: 'PROTEİN',
                current: plannedPro,
                target: state.mainProgram!.targetProtein,
                color: AppColors.protein,
              ),
              MacroRingStat(
                label: 'KARB.',
                current: plannedCarb,
                target: state.mainProgram!.targetCarbs,
                color: AppColors.carbs,
              ),
              MacroRingStat(
                label: 'YAĞ',
                current: plannedFat,
                target: state.mainProgram!.targetFat,
                color: AppColors.fat,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildNutrientChips(
            context: context,
            state: state,
            sugar: plannedSugar,
            fiber: plannedFiber,
            sodium: plannedSod,
            chol: plannedChol,
            pot: plannedPot,
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientChips({
    required BuildContext context,
    required DietDashboardState state,
    required double sugar,
    required double fiber,
    required double sodium,
    required double chol,
    required double pot,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          NutrientChip(
            label: 'Şeker',
            current: sugar,
            target: state.mainProgram!.targetSugar,
            unit: 'g',
            color: AppColors.sugar,
            highlightExceed: true,
          ),
          NutrientChip(
            label: 'Lif',
            current: fiber,
            target: state.mainProgram!.targetFiber,
            unit: 'g',
            color: AppColors.fiber,
            highlightExceed: false,
          ),
          NutrientChip(
            label: 'Sodyum',
            current: sodium,
            target: state.mainProgram!.targetSodium,
            unit: 'mg',
            color: AppColors.sodium,
            highlightExceed: true,
          ),
          NutrientChip(
            label: 'Kolesterol',
            current: chol,
            target: state.mainProgram!.targetCholesterol,
            unit: 'mg',
            color: AppColors.cholesterol,
            highlightExceed: true,
          ),
          NutrientChip(
            label: 'Potasyum',
            current: pot,
            target: state.mainProgram!.targetPotassium,
            unit: 'mg',
            color: AppColors.potassium,
            highlightExceed: false,
          ),
        ],
      ),
    );
  }
}

