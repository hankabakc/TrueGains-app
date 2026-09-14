import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/pressable_scale.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:gymapp_v2/core/widgets/list_skeleton.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/workout_history/workout_history_cubit.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/workout_history/workout_history_state.dart';
import 'package:gymapp_v2/features/training/models/workout_session.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:intl/intl.dart';

import 'package:gymapp_v2/features/training/bloc/weekly_progress_cubit.dart';
import 'package:gymapp_v2/features/training/ui/widgets/weekly_history_section.dart';

class WorkoutHistoryPage extends StatelessWidget {
  final int? targetClientId;
  const WorkoutHistoryPage({super.key, this.targetClientId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<WorkoutHistoryCubit>()..loadHistory(targetClientId),
        ),
        BlocProvider(
          create: (context) {
            final cubit = sl<WeeklyProgressCubit>();
            if (targetClientId != null) {
              cubit.loadClientHistory(targetClientId!);
            } else {
              cubit.loadMyHistory();
            }
            return cubit;
          },
        ),
      ],
      child: WorkoutHistoryView(targetClientId: targetClientId),
    );
  }
}

class WorkoutHistoryView extends StatelessWidget {
  final int? targetClientId;
  const WorkoutHistoryView({super.key, this.targetClientId});

  void _confirmDelete(BuildContext context, WorkoutSession session) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'İdmanı Sil',
          style: AppTextStyles.heroTitle.copyWith(fontSize: 20),
        ),
        content: Text(
          '"${session.workoutDayName}" kaydı kalıcı olarak silinecek.',
          style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'İPTAL',
              style: AppTextStyles.buttonText.copyWith(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<WorkoutHistoryCubit>().deleteSession(session.id);
            },
            child: Text(
              'SİL',
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'İDMAN GEÇMİŞİ',
          style: AppTextStyles.pageTitle,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<WorkoutHistoryCubit>().loadHistory(targetClientId);
          if (targetClientId != null) {
            context.read<WeeklyProgressCubit>().loadClientHistory(targetClientId!);
          } else {
            context.read<WeeklyProgressCubit>().loadMyHistory();
          }
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İstatistik Özet Bento Şeridi
                  const _SummaryStrip(),

                  // Haftalık Başarı Geçmişi Bölümü
                  BlocBuilder<WeeklyProgressCubit, WeeklyProgressState>(
                    builder: (context, progressState) {
                      if (progressState is WeeklyProgressLoading) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        );
                      }
                      if (progressState is WeeklyHistoryLoaded) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          child: WeeklyHistorySection(history: progressState.history),
                        );
                      }
                      if (progressState is WeeklyProgressError) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          child: Text(
                            progressState.message,
                            style: AppTextStyles.bodyText.copyWith(color: AppColors.error),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  
                  // Seans Geçmişi Başlığı
                  const SectionHeader(
                    label: 'BİREYSEL İDMANLAR',
                    icon: Icons.history_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Seans Geçmişi Listesi
                  BlocConsumer<WorkoutHistoryCubit, WorkoutHistoryState>(
                    listener: (context, state) {
                      if (state.status == WorkoutHistoryStatus.failure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.error ?? 'Hata oluştu'), backgroundColor: AppColors.error),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state.status == WorkoutHistoryStatus.loading) {
                        return const ListSkeleton();
                      }

                      if (state.history.isEmpty) {
                        return const _EmptyState();
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.history.length,
                        itemBuilder: (context, index) {
                          final session = state.history[index];
                          return _SessionCard(
                            session: session,
                            targetClientId: targetClientId,
                            onDelete: _confirmDelete,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutHistoryCubit, WorkoutHistoryState>(
      builder: (context, historyState) {
        final totalSessions = historyState.history.length;
        final totalMinutes = historyState.history.fold<int>(0, (sum, s) => sum + (s.totalSeconds ~/ 60));

        return BlocBuilder<WeeklyProgressCubit, WeeklyProgressState>(
          builder: (context, progressState) {
            String successPercentage = '-';
            if (progressState is WeeklyHistoryLoaded && progressState.history.isNotEmpty) {
              final latest = progressState.history.first;
              successPercentage = '%${latest.successPercentage.round()}';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'TOPLAM SEANS',
                      value: '$totalSessions',
                      icon: Icons.fitness_center_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _SummaryCard(
                      label: 'TOPLAM SÜRE',
                      value: '${totalMinutes}dk',
                      icon: Icons.timer_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _SummaryCard(
                      label: 'SON HAFTA',
                      value: successPercentage,
                      icon: Icons.emoji_events_rounded,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.primary;
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadius.lg,
      shadow: AppElevation.cardShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.cardCaption.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.cardValue.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final WorkoutSession session;
  final int? targetClientId;
  final void Function(BuildContext, WorkoutSession) onDelete;

  const _SessionCard({
    required this.session,
    required this.targetClientId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime date = session.createdAt;
    final String formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(date);
    final int minutes = session.totalSeconds ~/ 60;
    final int exerciseCount = session.logs.map((l) => l.exerciseName).toSet().length;
    final int setCount = session.logs.length;
    final color = AppColors.primary;

    return PressableScale(
      onTap: () => context.push('/workout-detail', extra: {
        'session': session,
        'clientId': targetClientId,
      }),
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        shadow: AppElevation.softGlow(color),
        borderRadius: AppRadius.xl,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.workoutDayName,
                    style: AppTextStyles.listTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xxs,
                    children: [
                      _SessionStatBadge(
                        icon: Icons.calendar_today_rounded,
                        label: formattedDate,
                      ),
                      _SessionStatBadge(
                        icon: Icons.timer_rounded,
                        label: '$minutes dk',
                      ),
                      _SessionStatBadge(
                        icon: Icons.fitness_center_rounded,
                        label: '$exerciseCount Egzersiz',
                      ),
                      _SessionStatBadge(
                        icon: Icons.repeat_rounded,
                        label: '$setCount Set',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (targetClientId == null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                    onPressed: () => onDelete(context, session),
                  ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textMuted,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionStatBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SessionStatBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.tagText.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Henüz idman kaydınız yok.',
              style: AppTextStyles.emptyTitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Hemen bir idmana başlayın!',
              style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
