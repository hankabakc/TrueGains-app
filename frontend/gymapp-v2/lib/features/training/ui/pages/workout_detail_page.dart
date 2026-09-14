import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/training/models/workout_session.dart';
import 'package:gymapp_v2/core/utils/formatting_utils.dart';

class WorkoutDetailPage extends StatelessWidget {
  final WorkoutSession session;
  final int? clientId;

  const WorkoutDetailPage({super.key, required this.session, this.clientId});

  @override
  Widget build(BuildContext context) {
    final List<WorkoutSessionLog> logs = session.logs;

    final int totalSets = logs.length;

    final int totalSeconds = session.totalSeconds;
    final String minutes = (totalSeconds / 60).toStringAsFixed(0);

    final DateTime createdAt = session.createdAt;
    final String formattedDate =
        DateFormat('d MMMM yyyy, HH:mm', 'tr_TR').format(createdAt);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildBackgroundGlow(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(height: AppSpacing.lg),
                        _buildHeader(
                          session.workoutDayName,
                          formattedDate,
                        ),
                        SizedBox(height: AppSpacing.xl),
                        _buildStatsRow(totalSets, minutes),
                        SizedBox(height: AppSpacing.xl),
                        _buildSectionHeader('SET DETAYLARI'),
                        _buildSetsList(logs),
                        SizedBox(height: AppLayout.bottomNavClearance),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildActionSection(context),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          Text(
            'İDMAN ÖZETİ',
            style: AppTextStyles.sectionLabel.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          SizedBox(width: AppSpacing.xxl), // Denge için
        ],
      ),
    );
  }

  Widget _buildBackgroundGlow() {
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
              AppColors.primary.withValues(alpha: 0.1),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String date) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            color: AppColors.primary,
            size: 48,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          title.toUpperCase(),
          style: AppTextStyles.heroTitle.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: AppSpacing.xxs),
        Text(
          date,
          style: AppTextStyles.bodyText.copyWith(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isClient = state is AuthAuthenticated && state.auth.role == UserRole.CLIENT;
            if (isClient) {
              return Text(
                'BU İDMANI TAMAMLADIN!',
                style: AppTextStyles.sectionLabel.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildStatsRow(int sets, String minutes) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          _buildStatCard('SET', '$sets', Icons.repeat_rounded, AppColors.primary),

          SizedBox(width: AppSpacing.sm),
          _buildStatCard('SÜRE', '${minutes}dk', Icons.timer_outlined, AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: GlassContainer(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTextStyles.greeting.copyWith(color: AppColors.textPrimary),
            ),
            Text(
              title,
              style: AppTextStyles.tagText.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: AppTextStyles.cardCaption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSetsList(List<WorkoutSessionLog> logs) {
    final Map<int, List<WorkoutSessionLog>> groupedLogs = {};
    final List<int> exerciseOrder = [];

    for (var log in logs) {
      if (!groupedLogs.containsKey(log.exerciseId)) {
        groupedLogs[log.exerciseId] = [];
        exerciseOrder.add(log.exerciseId);
      }
      groupedLogs[log.exerciseId]!.add(log);
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exerciseOrder.length,
      itemBuilder: (context, index) {
        final exerciseId = exerciseOrder[index];
        final exerciseLogs = groupedLogs[exerciseId]!;
        final exerciseName = exerciseLogs.first.exerciseName;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      exerciseName.toUpperCase(),
                      style: AppTextStyles.listTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.auto_graph_rounded, color: AppColors.primary, size: 20),
                    onPressed: () {
                      context.push('/exercise-progress', extra: {
                        'exerciseId': exerciseId,
                        'exerciseName': exerciseName,
                        if (clientId != null) 'clientId': clientId,
                      });
                    },
                  ),
                ],
              ),
            ),
            ...exerciseLogs.map((log) {
              return GlassContainer(
                margin: EdgeInsets.only(bottom: AppSpacing.sm),
                padding: EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${log.setIndex}. Set',
                            style: AppTextStyles.bodyText.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (log.durationSeconds > 0) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'Süre: ${FormattingUtils.formatDuration(log.durationSeconds)}',
                              style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${log.actualWeight} kg',
                          style: AppTextStyles.bubbleText.copyWith(fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${log.actualReps} Tekrar',
                          style: AppTextStyles.cardCaption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }

  Widget _buildActionSection(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background.withValues(alpha: 0),
              AppColors.background.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: PremiumButton(
          text: 'KAPAT',
          onPressed: () => context.pop(),
        ),
      ),
    );
  }
}
