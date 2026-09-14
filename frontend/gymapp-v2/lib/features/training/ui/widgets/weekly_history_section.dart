import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:gymapp_v2/features/training/models/weekly_progress.dart';

class WeeklyHistorySection extends StatelessWidget {
  final List<WeeklyHistoryItem> history;

  const WeeklyHistorySection({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionHeader(
          label: 'HAFTALIK BAŞARI GEÇMİŞİ',
          icon: Icons.calendar_month_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        if (history.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 48,
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Henüz haftalık başarı kaydı yok.',
                    style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final weekEnd = item.weekStartDate.add(const Duration(days: 6));
              
              // Tarih formatlama (Örn: 15 Haz - 21 Haz)
              final DateFormat formatter = DateFormat('d MMM', 'tr_TR');
              final String dateRange = '${formatter.format(item.weekStartDate)} - ${formatter.format(weekEnd)}';

              final double progressValue = (item.successPercentage / 100).clamp(0.0, 1.0);

              return GlassContainer(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                borderRadius: AppRadius.lg,
                shadow: AppElevation.cardShadow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateRange,
                          style: AppTextStyles.listTitle.copyWith(fontSize: 14),
                        ),
                        Text(
                          '%${item.successPercentage.round()}',
                          style: AppTextStyles.tagText.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 6,
                        backgroundColor: AppColors.glassWhite,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${item.completedDays} / ${item.targetDays} antrenman günü tamamlandı',
                      style: AppTextStyles.cardCaption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
