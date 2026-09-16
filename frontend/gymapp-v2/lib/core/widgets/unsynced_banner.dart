import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';

/// Sunucunun kalıcı olarak reddettiği kayıt varsa uygulama kabuğunun üstünde görünen bant (G-69).
/// Dokununca aktarılamayan kayıtların listesi açılır.
class UnsyncedBanner extends StatelessWidget {
  const UnsyncedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final sl = GetIt.instance;
    if (!sl.isRegistered<SyncManager>()) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<int>(
      valueListenable: sl<SyncManager>().rejectedCount,
      builder: (context, count, child) {
        if (count <= 0) {
          return const SizedBox.shrink();
        }

        return Material(
          color: AppColors.error.withValues(alpha: 0.15),
          child: InkWell(
            onTap: () => context.push('/unsynced-records'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs, horizontal: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '$count kayıt sunucuya aktarılamadı · Göster',
                    style: AppTextStyles.cardCaption.copyWith(color: AppColors.error),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
