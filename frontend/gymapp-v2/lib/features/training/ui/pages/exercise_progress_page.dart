import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/training/models/exercise_progress.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/progress_line_chart.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/analytics/exercise_analytics_cubit.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/analytics/exercise_analytics_state.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:intl/intl.dart';

class ExerciseProgressPage extends StatelessWidget {
  final int exerciseId;
  final String exerciseName;
  final int? clientId;

  const ExerciseProgressPage({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ExerciseAnalyticsCubit>()..loadExerciseProgress(exerciseId, clientId: clientId),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            exerciseName.toUpperCase(),
            style: AppTextStyles.greeting.copyWith(color: AppColors.textPrimary),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<ExerciseAnalyticsCubit, ExerciseAnalyticsState>(
          builder: (context, state) {
            if (state.status == ExerciseAnalyticsStatus.loading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (state.status == ExerciseAnalyticsStatus.failure) {
              return Center(child: Text(state.error ?? 'Veriler yüklenemedi', style: AppTextStyles.bodyText.copyWith(color: AppColors.error)));
            }

            if (state.progress.isEmpty) {
              return _buildEmptyState();
            }

            final List<FlSpot> spots = state.progress.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.oneRepMax);
            }).toList();

            final List<String> xLabels = state.progress.map((p) => DateFormat('dd/MM').format(p.date)).toList();
            final double maxY = state.progress.fold(0, (max, p) => p.oneRepMax > max ? p.oneRepMax : max);

            return SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'PROGRESSIVE OVERLOAD (1RM)',
                        style: AppTextStyles.listSubtitle.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      GestureDetector(
                        onTap: () {
                          showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppColors.background,
                              title: Text('Tek Tekrar Maksimumu (1RM) Nedir?',
                                  style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary)),
                              content: Text(
                                'Bu değer, kaldırdığınız ağırlık ve yaptığınız tekrar sayısı kullanılarak bilimsel (Epley) formülüyle hesaplanan, tek seferde kaldırabileceğiniz teorik maksimum ağırlık tahminidir. Gelişiminizi daha tutarlı takip etmenizi sağlar.',
                                style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Anladım',
                                      style: AppTextStyles.buttonText.copyWith(color: AppColors.primary)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  GlassContainer(
                    height: 300,
                    padding: EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
                    child: ProgressLineChart(
                      spots: spots,
                      xLabels: xLabels,
                      maxY: maxY,
                    ),
                  ),

                  SizedBox(height: AppSpacing.xl),
                  Text(
                    'GEÇMİŞ PERFORMANSLAR',
                    style: AppTextStyles.listSubtitle.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  SizedBox(height: AppSpacing.md),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.progress.length,
                    itemBuilder: (context, index) {
                      final p = state.progress[state.progress.length - 1 - index]; // En yeni en üstte
                      return _buildProgressTile(p);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_graph_rounded, size: 64, color: AppColors.textPrimary.withValues(alpha: 0.1)),
          SizedBox(height: AppSpacing.md),
          Text('Henüz gelişim verisi yok', style: AppTextStyles.listTitle.copyWith(color: AppColors.textSecondary)),
          SizedBox(height: AppSpacing.xs),
          Text('İdman yaptıkça grafik burada oluşacak.', style: AppTextStyles.listSubtitle.copyWith(color: AppColors.textMuted.withValues(alpha: 0.24))),
        ],
      ),
    );
  }

  Widget _buildProgressTile(ExerciseProgress p) {
    final dateStr = DateFormat('dd MMMM yyyy').format(p.date);
    return GlassContainer(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateStr, style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              SizedBox(height: AppSpacing.xxs),
              Text(
                'Max Kaldırılan: ${p.maxWeight} kg · ${p.totalSets} set',
                style: AppTextStyles.sectionLabel.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${p.oneRepMax.toStringAsFixed(1)} kg',
                  style: AppTextStyles.greeting.copyWith(color: AppColors.primary)),
              Text('Teorik Max (1RM)',
                  style: AppTextStyles.cardLabel.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
