import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/util/motion.dart';

class IntroOptionCard extends StatelessWidget {
  final String label;
  final String? description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  /// Sayfa görünür olduğunda kademeli giriş oynar.
  final bool isActive;

  const IntroOptionCard({
    super.key,
    required this.label,
    this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.index,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: isActive ? 1.0 : 0.0),
      duration: motionDuration(
        context,
        Duration(milliseconds: 340 + (index * 70)),
      ),
      curve: Curves.easeOutQuint,
      builder: (context, value, animChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: animChild,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: motionDuration(context, AppDurations.fast),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: isSelected
                ? Border.all(color: AppColors.primary, width: 2)
                : Border.all(color: AppColors.glassBorder, width: 1),
            // Glow bilinçli olarak yok: accent bütçesi ekran başına iki kullanım.
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: isSelected
                          ? AppTextStyles.listTitle.copyWith(color: AppColors.primary)
                          : AppTextStyles.listTitle,
                    ),
                    if (description != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        description!,
                        style: AppTextStyles.cardCaption,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
