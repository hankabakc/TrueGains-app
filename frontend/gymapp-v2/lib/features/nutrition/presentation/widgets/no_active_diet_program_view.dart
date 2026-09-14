import 'package:flutter/material.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';

class NoActiveDietProgramView extends StatelessWidget {
  final bool isCoachView;
  final VoidCallback? onSelectProgram;

  const NoActiveDietProgramView({
    super.key,
    required this.isCoachView,
    this.onSelectProgram,
  });

  @override
  Widget build(BuildContext context) {
    final title = isCoachView ? 'Aktif Diyet Programı Yok' : 'Aktif Diyet Programın Yok';
    final description = isCoachView
        ? 'Bu sporcunun aktif bir diyet programı bulunmuyor. Program seçme/aktifleştirme yalnızca sporcunun kendisi tarafından yapılabilir.'
        : 'Beslenmeni takip etmek için bir diyet programı seç veya oluştur.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.emptyTitle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyText.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              if (!isCoachView && onSelectProgram != null) ...[
                const SizedBox(height: AppSpacing.xl),
                PremiumButton(
                  text: 'DİYET PROGRAMI SEÇ',
                  onPressed: onSelectProgram!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
