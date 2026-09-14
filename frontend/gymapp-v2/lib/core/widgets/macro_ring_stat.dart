import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import 'stat_ring.dart';

class MacroRingStat extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final bool isCalories;

  const MacroRingStat({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    this.isCalories = false,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatRing(
          progress: progress,
          color: color,
          size: 60.0,
          center: Text(
            '${(progress * 100).toInt()}%',
            style: AppTextStyles.cardCaption.copyWith(
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: AppTextStyles.cardLabel.copyWith(
            fontSize: 9.0,
            letterSpacing: 0.5,
            color: AppColors.textMuted,
          ),
        ),
        Text(
          '${current.toInt()}${isCalories ? " kcal" : "g"}',
          style: AppTextStyles.cardCaption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
