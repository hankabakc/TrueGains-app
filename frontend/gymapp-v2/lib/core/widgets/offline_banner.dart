import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/network/cache_status.dart';

/// Veri önbellekten geliyorsa uygulama kabuğunun üstünde görünen ince bant.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final sl = GetIt.instance;
    if (!sl.isRegistered<CacheStatusNotifier>()) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<DateTime?>(
      valueListenable: sl<CacheStatusNotifier>(),
      builder: (context, value, child) {
        if (value == null) {
          return const SizedBox.shrink();
        }

        final String timeStr = DateFormat('HH:mm').format(value);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          color: AppColors.warning.withValues(alpha: 0.15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 14, color: AppColors.warning),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Çevrimdışı · son güncelleme $timeStr',
                style: AppTextStyles.cardCaption.copyWith(color: AppColors.warning),
              ),
            ],
          ),
        );
      },
    );
  }
}
