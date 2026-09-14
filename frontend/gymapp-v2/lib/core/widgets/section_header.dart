import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color accent;

  const SectionHeader({
    super.key,
    required this.label,
    this.icon,
    this.accent = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.sectionLabel.copyWith(color: AppColors.textPrimary),
        ),
        if (icon != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Icon(icon, color: accent, size: 16),
        ],
      ],
    );
  }
}
