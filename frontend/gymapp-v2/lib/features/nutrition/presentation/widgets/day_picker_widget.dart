import 'package:flutter/material.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_dashboard/diet_dashboard_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_dashboard/diet_dashboard_state.dart';

class DayPickerWidget extends StatelessWidget {
  final DietDashboardState state;
  final DietDashboardCubit cubit;

  const DayPickerWidget({super.key, required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    if (state.mainProgram == null || state.mainProgram!.dietDays.isEmpty) {
      return const SizedBox();
    }

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: state.mainProgram!.dietDays.length,
        itemBuilder: (context, index) {
          final isSelected = state.selectedDayIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => cubit.selectDay(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color:
                        isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : [],
                ),
                child: Center(
                  child: Text(
                    state.mainProgram!.dietDays[index].name.toUpperCase(),
                    style: AppTextStyles.buttonText.copyWith(
                      color: isSelected ? AppColors.background : AppColors.textSecondary,
                      fontSize: 13,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

