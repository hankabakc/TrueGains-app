import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/pressable_scale.dart';
import 'package:gymapp_v2/core/widgets/stat_ring.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_entry/diet_entry_bloc.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_entry/diet_entry_state.dart';

/// Paneldeki BESLENME kartı. Gösterdiği sayı planlanan değil, Beslenme Günlüğü'nde
/// **işaretlenen** besinlerin (+ ekstra girişlerin) toplamıdır; kaynağı `DietEntryBloc`.
class NutritionBento extends StatelessWidget {
  const NutritionBento({super.key});

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primary;
    return BlocBuilder<DietEntryBloc, DietEntryState>(
      builder: (context, state) {
        final hasProgram = state.mainProgram != null;
        final currentCal = state.totalCalories.toInt();
        final targetCal = state.targetCalories.toInt();
        final protein = state.totalProtein.toInt();
        final progress = targetCal > 0 ? (currentCal / targetCal).clamp(0.0, 1.0) : 0.0;
        // Günlükteki kalori halkasıyla aynı kural (diet_entry_page.dart:325): hedef
        // aşıldığında halka kırmızı. Kart kenarlığı/gölgesi primary kalır.
        final isExceeded = targetCal > 0 && currentCal > targetCal;

        return PressableScale(
          onTap: () => context.push(hasProgram ? '/nutrition/entry' : '/nutrition/list/client'),
          child: SizedBox(
            height: 180,
            child: GlassContainer(
              elevated: true,
              border: Border.all(color: color.withValues(alpha: 0.15)),
              shadow: AppElevation.softGlow(color),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'BESLENME',
                        style: AppTextStyles.cardLabel.copyWith(color: color),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push(hasProgram ? '/nutrition/entry' : '/nutrition/list/client'),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xxs),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded, color: color, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (!hasProgram)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppColors.warning.withValues(alpha: 0.8), size: 24),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Diyet programı aktif et',
                            style: AppTextStyles.cardCaption.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$currentCal',
                                style: AppTextStyles.cardValue.copyWith(fontSize: 22),
                              ),
                              Text('kcal', style: AppTextStyles.cardCaption),
                              const SizedBox(height: 4),
                              Text(
                                'Protein $protein g • Hedef $targetCal kcal',
                                style: AppTextStyles.cardCaption.copyWith(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        StatRing(
                          progress: progress,
                          color: isExceeded ? AppColors.error : color,
                          size: 60,
                          center: Text(
                            '%${(progress * 100).toInt()}',
                            style: AppTextStyles.cardCaption.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Bugün Tüketilen',
                      style: AppTextStyles.cardCaption,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
