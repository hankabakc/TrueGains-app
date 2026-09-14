import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/analytics/exercise_analytics_cubit.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/analytics/exercise_analytics_state.dart';

class LastPerformanceBanner extends StatelessWidget {
  final int exerciseId;

  const LastPerformanceBanner({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ExerciseAnalyticsCubit>()..loadExerciseProgress(exerciseId),
      child: BlocBuilder<ExerciseAnalyticsCubit, ExerciseAnalyticsState>(
        builder: (context, state) {
          if (state.status == ExerciseAnalyticsStatus.loaded && state.progress.isNotEmpty) {
            final last = state.progress.last;
            final weight = last.maxWeight.toStringAsFixed(0);
            final sets = last.totalSets;

            return Container(
              margin: const EdgeInsets.only(top: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Text(
                'Son seans: $weight kg · $sets set',
                style: AppTextStyles.cardCaption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
