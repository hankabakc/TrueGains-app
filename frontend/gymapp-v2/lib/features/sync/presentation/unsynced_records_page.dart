import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/empty_state.dart';
import 'package:gymapp_v2/features/sync/presentation/unsynced_records_cubit.dart';
import 'package:gymapp_v2/features/training/data/services/training_api_service.dart';

/// Kuyruk kaydının uç adresinden kullanıcıya görünen adı. Yeni çevrimdışı dilim buraya satır ekler.
String unsyncedRecordLabel(String endpoint) {
  if (endpoint == TrainingApiService.sessionsPath) return 'Antrenman kaydı';
  if (endpoint == '/social/chat/send') return 'Mesaj';
  return 'Kayıt';
}

/// Sunucunun kabul etmediği çevrimdışı kayıtlar (G-69): tekrar dene ya da onayla sil.
class UnsyncedRecordsPage extends StatelessWidget {
  const UnsyncedRecordsPage({super.key});

  Future<void> _confirmDiscard(BuildContext context, RejectedRecord record) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Kaydı sil'),
        content: const Text('Bu kayıt sunucuya hiç ulaşmadı. Silersen geri getirilemez.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    await context.read<UnsyncedRecordsCubit>().discard(record.key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Aktarılamayan kayıtlar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<UnsyncedRecordsCubit, UnsyncedRecordsState>(
        builder: (context, state) {
          if (state.records.isEmpty) {
            return const EmptyState(
              icon: Icons.cloud_done_rounded,
              title: 'Aktarılamayan kayıt yok',
              message: 'Bütün kayıtların sunucuya ulaştı.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: state.records.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final RejectedRecord record = state.records[index];
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(unsyncedRecordLabel(record.endpoint), style: AppTextStyles.listTitle),
                    if (record.createdAt != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        DateFormat('dd.MM.yyyy HH:mm').format(record.createdAt!),
                        style: AppTextStyles.listSubtitle,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(record.reason, style: AppTextStyles.bodyText.copyWith(color: AppColors.error)),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: state.busy ? null : () => _confirmDiscard(context, record),
                          style: TextButton.styleFrom(foregroundColor: AppColors.error),
                          child: const Text('Sil'),
                        ),
                        TextButton(
                          onPressed: state.busy ? null : () => context.read<UnsyncedRecordsCubit>().retry(record.key),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                          child: const Text('Tekrar dene'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
