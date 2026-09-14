import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';

/// Ödeme Başarılı Geri Bildirim Ekranı
class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/main');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.success, AppColors.primary],
                    ),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 64),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Tebrikler! 🎉',
                  style: AppTextStyles.heroDisplay.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Ödemeniz başarıyla doğrulandı ve aboneliğiniz aktif edildi.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: AppSpacing.xxl),
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Artık Premium üyesiniz! Antrenörünüz ile hemen iletişime geçebilir, özel programlarınızı ve diyet planlarınızı takip edebilirsiniz.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                PremiumButton(
                  text: 'ABONELİKLERİME GİT',
                  onPressed: () {
                    context.go('/main');
                    context.push('/my-subscription');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ödeme Başarısız Geri Bildirim Ekranı
class PaymentFailurePage extends StatelessWidget {
  const PaymentFailurePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/main');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.error, AppColors.error.withValues(alpha: 0.7)],
                    ),
                  ),
                  child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 64),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Ödeme Başarısız',
                  style: AppTextStyles.heroDisplay.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Kart limitiniz, geçersiz kart bilgileri veya banka reddi nedeniyle işlem tamamlanamadı.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: AppSpacing.xxl),
                PremiumButton(
                  text: 'TEKRAR DENE',
                  onPressed: () {
                    context.go('/main');
                    context.push('/my-subscription');
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => context.go('/main'),
                  child: Text(
                    'ANA SAYFAYA DÖN',
                    style: AppTextStyles.buttonText.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
