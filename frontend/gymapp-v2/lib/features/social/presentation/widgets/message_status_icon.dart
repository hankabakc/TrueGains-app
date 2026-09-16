import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';

import '../../data/models/message_model.dart';
import '../../data/models/message_status.dart';

const double _kStatusIconSize = 14.0;

/// Gönderenin kendi balonundaki durum işareti (chat_detail_page'den taşındı).
///
/// Kuyruktaki (id negatif) mesajın kaydını sunucu kalıcı olarak reddettiyse saat yerine kırmızı
/// "Gönderilemedi" görünür; dokununca aktarılamayan kayıtlar listesi açılır (KR14, G-80). Kayıt balona
/// `localId` ile bağlanır.
class MessageStatusIcon extends StatelessWidget {
  final MessageModel message;

  const MessageStatusIcon({super.key, required this.message});

  static const Widget _queued = Icon(Icons.schedule_rounded, size: _kStatusIconSize, color: AppColors.textMuted);

  @override
  Widget build(BuildContext context) {
    if (message.id >= 0) return _sentIcon(message.status);

    final String? localId = message.localId;
    final GetIt sl = GetIt.instance;
    if (localId == null || !sl.isRegistered<SyncManager>()) return _queued;

    final SyncManager syncManager = sl<SyncManager>();
    return ValueListenableBuilder<int>(
      valueListenable: syncManager.rejectedCount,
      child: _queued,
      builder: (BuildContext context, int count, Widget? child) {
        // ponytail: kuyruk yalnızca geçici balonda ve ret varken okunur; balon sayısı çok artarsa kimlik kümesi tek yerde tutulur.
        final bool rejected = count > 0 && syncManager.rejectedRecords().any((RejectedRecord r) => r.localId == localId);
        if (!rejected) return child!;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.push('/unsynced-records'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: _kStatusIconSize, color: AppColors.error),
              const SizedBox(width: AppSpacing.xxs),
              Text('Gönderilemedi', style: AppTextStyles.timestamp.copyWith(color: AppColors.error)),
            ],
          ),
        );
      },
    );
  }

  static Widget _sentIcon(MessageStatus status) => switch (status) {
        MessageStatus.read => const Icon(Icons.done_all_rounded, size: _kStatusIconSize, color: AppColors.info),
        MessageStatus.delivered => const Icon(Icons.done_all_rounded, size: _kStatusIconSize, color: AppColors.textMuted),
        MessageStatus.sent => const Icon(Icons.done_rounded, size: _kStatusIconSize, color: AppColors.textMuted),
      };
}
