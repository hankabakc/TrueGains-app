import 'package:flutter/material.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/util/motion.dart';

class IntroQuestionScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  /// Sayfa görünür olduğunda giriş animasyonu oynar. Mount anına bağlanırsa
  /// animasyon PageView kaydırmasının altında akıp biter ve hiç görülmez.
  final bool isActive;

  const IntroQuestionScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.isActive,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: isActive ? 1.0 : 0.0),
        duration: motionDuration(context, const Duration(milliseconds: 340)),
        curve: Curves.easeOutQuint,
        builder: (context, value, animChild) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 32 * (1 - value)),
              child: animChild,
            ),
          );
        },
        child: Column(
          // stretch ZORUNLU: start ile içerik alanı yatayda daralıp kendi
          // içeriğine göre büzülüyor, dar içerikler (fotoğraf dairesi gibi)
          // ekranın soluna kayıyordu.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Text(title, style: AppTextStyles.heroTitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            // İçerik sığdığında yukarıdan başlar (başlıkla arasında yarım ekran
            // boşluk kalmasın), sığmadığında kaydırılır.
            Expanded(
              child: SingleChildScrollView(child: child),
            ),
            if (footer != null) ...[
              footer!,
              const SizedBox(height: AppSpacing.xl),
            ],
          ],
        ),
      ),
    );
  }
}
