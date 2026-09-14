import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/pressable_scale.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:gymapp_v2/core/widgets/stat_ring.dart';
import 'package:gymapp_v2/core/widgets/mini_sparkline_painter.dart';
import '../bloc/coach_dashboard/coach_dashboard_cubit.dart';

class CoachDashboardPage extends StatelessWidget {
  const CoachDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CoachDashboardCubit>(
      create: (_) => sl<CoachDashboardCubit>()..load(),
      child: Builder(
        builder: (innerContext) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.background,
                onRefresh: () async => innerContext.read<CoachDashboardCubit>().load(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCoachHeader(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildStatsGrid(context),
                      const SizedBox(height: AppSpacing.xl),
                      const SectionHeader(
                        label: 'HIZLI İŞLEMLER',
                        icon: Icons.bolt_rounded,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 1.3,
                        children: [
                          _buildGridActionCard(
                            context,
                            'Öğrencilerim',
                            Icons.groups_rounded,
                            AppColors.primary,
                            () => context.push('/coach/my-clients'),
                          ),
                          _buildGridActionCard(
                            context,
                            'Diyet Şablonları',
                            Icons.restaurant_menu_rounded,
                            AppColors.primary,
                            () => context.push('/coach-diet-templates'),
                          ),
                          _buildGridActionCard(
                            context,
                            'Su Takibi',
                            Icons.water_drop_rounded,
                            AppColors.primary,
                            () => context.push('/coach-water-tracking'),
                          ),
                          _buildGridActionCard(
                            context,
                            'Ölçümler',
                            Icons.straighten_rounded,
                            AppColors.primary,
                            () => context.push('/shared-measurements'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 100), // BottomNav spacing
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildCoachHeader() {
    return GlassContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      overlayGradient: AppColors.heroGradient,
      shadow: AppElevation.accentGlow(AppColors.primary),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.shield_rounded,
              color: AppColors.primary.withValues(alpha: 0.1),
              size: 72,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YÖNETİM PANELİ',
                style: AppTextStyles.cardLabel.copyWith(color: AppColors.primary, fontSize: 11),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Koç Merkezi',
                style: AppTextStyles.heroTitle.copyWith(fontSize: 32, letterSpacing: -1.0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return BlocBuilder<CoachDashboardCubit, CoachDashboardState>(
      builder: (context, state) {
        final activeStudentsVal = state.isLoading
            ? '—'
            : state.error != null
                ? '—'
                : state.stats?.activeStudents.toString() ?? '0';

        final monthlyEarningsVal = state.isLoading
            ? '—'
            : state.error != null
                ? '—'
                : state.stats != null
                    ? '${state.stats!.monthlyEarnings.toStringAsFixed(0)} ₺'
                    : '0 ₺';

        return Row(
          children: [
            Expanded(
              child: PressableScale(
                onTap: () => context.push('/coach/my-clients'),
                child: _buildStatCard(
                  'Aktif Öğrenci',
                  activeStudentsVal,
                  Icons.people_alt_rounded,
                  AppColors.primary,
                  rightWidget: const StatRing(
                    progress: 1.0,
                    color: AppColors.primary,
                    size: 40,
                    center: Icon(Icons.check_rounded, color: AppColors.primary, size: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                'Aylık Kazanç',
                monthlyEarningsVal,
                Icons.account_balance_wallet_rounded,
                AppColors.primary,
                bottomWidget: SizedBox(
                  width: double.infinity,
                  height: 24,
                  child: CustomPaint(
                    painter: MiniSparklinePainter(color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    Widget? rightWidget,
    Widget? bottomWidget,
  }) {
    return GlassContainer(
      height: 180,
      elevated: true,
      border: Border.all(color: color.withValues(alpha: 0.15)),
      shadow: AppElevation.cardShadow,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.xl),
                topRight: Radius.circular(AppRadius.xl),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      if (rightWidget != null) rightWidget,
                    ],
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: AppTextStyles.cardValue.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    title,
                    style: AppTextStyles.cardCaption,
                  ),
                  if (bottomWidget != null) ...[
                    const Spacer(),
                    bottomWidget,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return PressableScale(
      onTap: onTap,
      child: GlassContainer(
        elevated: true,
        border: Border.all(color: color.withValues(alpha: 0.15)),
        shadow: AppElevation.softGlow(color),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyText.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.8),
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
