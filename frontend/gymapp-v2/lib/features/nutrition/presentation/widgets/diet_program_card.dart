import 'package:flutter/material.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/pressable_scale.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';

class DietProgramCard extends StatelessWidget {
  final DietProgramModel program;
  final String subtitle;
  final bool isActive;
  final VoidCallback? onTap;
  final List<Widget> actions;
  final VoidCallback? onKeepOrphan;
  final VoidCallback? onDiscardOrphan;

  const DietProgramCard({
    super.key,
    required this.program,
    required this.subtitle,
    this.isActive = false,
    this.onTap,
    this.actions = const [],
    this.onKeepOrphan,
    this.onDiscardOrphan,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: program.isOrphaned ? null : onTap,
      child: GlassContainer(
        borderRadius: AppRadius.xl,
        padding: const EdgeInsets.all(AppSpacing.lg),
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.name,
                        style: AppTextStyles.listTitle.copyWith(fontSize: 18, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: AppTextStyles.cardCaption.copyWith(color: AppColors.textSecondary, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Text(
                      'AKTİF',
                      style: AppTextStyles.cardLabel.copyWith(color: AppColors.background, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(child: _buildMacroChip('Kalori', program.targetCalories, 'kcal', AppColors.primary)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: _buildMacroChip('Protein', program.targetProtein, 'g', AppColors.protein)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(child: _buildMacroChip('Karb', program.targetCarbs, 'g', AppColors.carbs)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: _buildMacroChip('Yağ', program.targetFat, 'g', AppColors.fat)),
              ],
            ),
            if (program.isOrphaned && onKeepOrphan != null && onDiscardOrphan != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'ANTRENÖR BAĞI KOPTU',
                          style: AppTextStyles.bodyText.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '"${program.name}" programının antrenörle bağı koptu. Kişisel programın olarak saklamak ister misin?',
                      style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onKeepOrphan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                            ),
                            child: Text(
                              'Sakla (Kişisel Yap)',
                              style: AppTextStyles.buttonText.copyWith(color: Colors.black, fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onDiscardOrphan,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.error),
                              foregroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                            ),
                            child: Text(
                              'Sil',
                              style: AppTextStyles.buttonText.copyWith(color: AppColors.error, fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (actions.isNotEmpty && !program.isOrphaned) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(color: AppColors.glassBorder, height: 1),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMacroChip(String label, double value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.cardLabel.copyWith(color: AppColors.textMuted, fontSize: 10),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Flexible(
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: AppTextStyles.listTitle.copyWith(fontSize: 13, color: AppColors.textPrimary),
                    children: [
                      TextSpan(text: value.toInt().toString()),
                      TextSpan(
                        text: ' $unit',
                        style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
