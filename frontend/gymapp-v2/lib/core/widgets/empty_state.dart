import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_dimens.dart';
import 'premium_button.dart';

/// Uygulama geneli tutarlı boş-durum ekranı. Soğuk başlangıçta (henüz verisi
/// olmayan yeni kullanıcı) boş yüzeyleri davetkâr ve aksiyon-odaklı yapar:
/// neon-glow ikon + başlık + açıklama + opsiyonel CTA.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasAction = actionLabel != null && onAction != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                boxShadow: AppElevation.softGlow(AppColors.primary),
              ),
              child: Icon(icon, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, textAlign: TextAlign.center, style: AppTextStyles.emptyTitle),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, height: 1.4),
              ),
            ],
            if (hasAction) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: 260,
                child: PremiumButton(
                  text: actionLabel!,
                  onPressed: onAction!,
                  icon: actionIcon,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
