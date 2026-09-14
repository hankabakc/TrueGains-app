import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';

class ActivateProgramPrompt extends StatelessWidget {
  final String? message;

  const ActivateProgramPrompt({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_circle_outline_rounded,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Aktif antrenman programın yok',
              style: AppTextStyles.heroTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message ?? 'Antrenmana başlamak için lütfen bir antrenman programı aktif et.',
              style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            PremiumButton(
              text: 'PROGRAMLARA GİT',
              onPressed: () => context.push('/training'),
            ),
          ],
        ),
      ),
    );
  }
}
