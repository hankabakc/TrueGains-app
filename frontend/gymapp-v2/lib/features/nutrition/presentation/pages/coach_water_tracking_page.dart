import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/list_skeleton.dart';
import 'package:gymapp_v2/core/widgets/network_avatar.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import '../bloc/coach_water_tracking/coach_water_tracking_cubit.dart';
import '../bloc/coach_water_tracking/coach_water_tracking_state.dart';
import '../../data/models/client_water_tracking_model.dart';

class CoachWaterTrackingPage extends StatefulWidget {
  const CoachWaterTrackingPage({super.key});

  @override
  State<CoachWaterTrackingPage> createState() => _CoachWaterTrackingPageState();
}

class _CoachWaterTrackingPageState extends State<CoachWaterTrackingPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<CoachWaterTrackingCubit>(
      create: (context) => sl<CoachWaterTrackingCubit>()..loadStudentWaterIntakes(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Su Tüketim Takibi',
            style: AppTextStyles.pageTitle.copyWith(fontSize: 22),
          ),
        ),
        body: Stack(
          children: [
            _buildTopGlow(),
            Positioned.fill(
              child: BlocBuilder<CoachWaterTrackingCubit, CoachWaterTrackingState>(
                builder: (context, state) {
                  if (state is CoachWaterTrackingLoading) {
                    return const ListSkeleton();
                  }

                  if (state is CoachWaterTrackingError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary, fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.read<CoachWaterTrackingCubit>().loadStudentWaterIntakes(),
                            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
                            label: Text('Yeniden Dene', style: AppTextStyles.buttonText.copyWith(color: AppColors.textPrimary)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is CoachWaterTrackingLoaded) {
                    final students = state.studentWaterIntakes;

                    if (students.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_drink_rounded,
                              size: 64,
                              color: AppColors.textMuted.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Henüz size bağlı aktif bir sporcu bulunmuyor.',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => context.read<CoachWaterTrackingCubit>().loadStudentWaterIntakes(),
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return _StudentWaterTrackingCard(student: student);
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopGlow() {
    return Positioned(
      top: -100,
      right: -50,
      child: Container(
        width: 300,
        height: 300,
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
}

class _StudentWaterTrackingCard extends StatelessWidget {
  final ClientWaterTrackingModel student;
  const _StudentWaterTrackingCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final double percentage = student.ratio * 100;
    final bool isTargetReached = student.consumedWaterMl >= student.targetWaterMl;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                NetworkAvatar(
                  imageUrl: student.profilePhotoUrl,
                  fallbackText: student.fullName,
                  size: 48,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTargetReached ? 'Günlük Hedefe Ulaşıldı 🎉' : 'Hedefe Devam Ediyor',
                        style: TextStyle(
                          color: isTargetReached ? Colors.greenAccent : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isTargetReached ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '%${percentage.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isTargetReached ? Colors.greenAccent : AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tüketilen Su',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${student.consumedWaterMl}',
                            style: TextStyle(
                              color: isTargetReached ? Colors.greenAccent : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: ' / ${student.targetWaterMl} ml',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: student.ratio > 1.0 ? 1.0 : student.ratio,
                    minHeight: 12,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isTargetReached ? Colors.greenAccent : Colors.blueAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
