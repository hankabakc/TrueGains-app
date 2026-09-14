import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:gymapp_v2/features/training/bloc/weekly_progress_cubit.dart';
import 'package:gymapp_v2/features/training/models/completed_set_data.dart';

class WorkoutSummaryPage extends StatelessWidget {
  final List<CompletedSetData> completedSets;
  final bool isOfflineSaved;

  const WorkoutSummaryPage({
    super.key,
    required this.completedSets,
    this.isOfflineSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = completedSets.isEmpty;
    final int totalSets = completedSets.length;
    final int exerciseCount = completedSets.map((s) => s.workoutExerciseId).toSet().length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _VictoryGlow(isEmpty: isEmpty),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    if (isOfflineSaved) const _OfflineBanner(),
                    const SizedBox(height: AppSpacing.xxl),
                    _Header(isEmpty: isEmpty),
                    const SizedBox(height: AppSpacing.xl),
                    if (!isEmpty) ...[
                      _StatsRow(
                        totalSets: totalSets,
                        exerciseCount: exerciseCount,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const SectionHeader(
                        label: 'SET DETAYLARI',
                        icon: Icons.assignment_turned_in_rounded,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: _SetsList(completedSets: completedSets),
                      ),
                    ] else ...[
                      const Spacer(),
                      const _EmptyStateWarning(),
                      const Spacer(),
                    ],
                    const _ActionSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _VictoryGlow extends StatelessWidget {
  final bool isEmpty;
  const _VictoryGlow({required this.isEmpty});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -100,
      left: 0,
      right: 0,
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              (isEmpty ? AppColors.warning : AppColors.primary).withValues(alpha: 0.15),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'İnternet bağlantınız olmadığından veriniz cihazınıza kaydedildi. Bağlantı sağlandığında eşitlenecektir.',
              style: AppTextStyles.tagText.copyWith(
                color: AppColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isEmpty;
  const _Header({required this.isEmpty});

  @override
  Widget build(BuildContext context) {
    final accentColor = isEmpty ? AppColors.warning : AppColors.primary;
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          duration: AppDurations.base,
          tween: Tween(begin: 0.5, end: 1.0),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 40,
                ),
              ],
            ),
            child: Icon(
              isEmpty ? Icons.history_rounded : Icons.emoji_events_rounded,
              color: accentColor,
              size: 64,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          isEmpty ? 'ANTRENMAN SONLANDI' : 'MUHTEŞEM İŞ!',
          style: AppTextStyles.heroDisplay,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isEmpty ? 'Bugünkü oturumunu bitirdin.' : 'Bugünkü hedeflerine bir adım daha yaklaştın.',
          style: AppTextStyles.bodyText.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int totalSets;
  final int exerciseCount;

  const _StatsRow({
    required this.totalSets,
    required this.exerciseCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Toplam Set',
              value: '$totalSets',
              icon: Icons.repeat_rounded,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _StatCard(
              title: 'Egzersiz',
              value: '$exerciseCount',
              icon: Icons.playlist_add_check_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      borderRadius: AppRadius.lg,
      shadow: AppElevation.softGlow(color),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.cardValue.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            title,
            style: AppTextStyles.cardCaption.copyWith(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetsList extends StatelessWidget {
  final List<CompletedSetData> completedSets;
  const _SetsList({required this.completedSets});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: completedSets.length,
      itemBuilder: (context, index) {
        final set = completedSets[index];
        return _SetCard(set: set);
      },
    );
  }
}

class _SetCard extends StatelessWidget {
  final CompletedSetData set;
  const _SetCard({required this.set});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.primary;
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadius.lg,
      shadow: AppElevation.softGlow(color),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Text(
                '${set.setIndex}',
                style: AppTextStyles.tagText.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  set.exerciseName,
                  style: AppTextStyles.listTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${set.setIndex}. Set',
                  style: AppTextStyles.listSubtitle.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${set.weight} kg',
                style: AppTextStyles.cardValue.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${set.reps} Tekrar',
                style: AppTextStyles.tagText.copyWith(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyStateWarning extends StatelessWidget {
  const _EmptyStateWarning();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.xl),
        borderRadius: AppRadius.lg,
        child: Column(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'SET KAYDI BULUNAMADI',
              textAlign: TextAlign.center,
              style: AppTextStyles.emptyTitle.copyWith(
                color: AppColors.warning,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Bugün hiç set tamamlanmadı. Antrenman performansınızı kaydetmek için setlerinizi tamamlamayı unutmayın!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withValues(alpha: 0),
            AppColors.background,
          ],
        ),
      ),
      child: PremiumButton(
        text: 'ANAPANELE DÖN',
        onPressed: () {
          context.read<WeeklyProgressCubit>().loadMyProgress();
          context.go('/main');
        },
      ),
    );
  }
}
