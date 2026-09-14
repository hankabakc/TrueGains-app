import 'package:flutter/material.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';

/// Açılış (splash) ekranı. Uygulama açılışında `AuthBloc.AppStarted` oturumu
/// sessizce geri yüklerken gösterilir; auth durumu çözülünce router otomatik
/// olarak /main veya /login'e yönlendirir.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/branding/logo_mark.png',
              width: 112,
              height: 112,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('TRUEGAINS', style: AppTextStyles.heroDisplay.copyWith(letterSpacing: 2)),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Formda kal, güçlü kal',
              style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
