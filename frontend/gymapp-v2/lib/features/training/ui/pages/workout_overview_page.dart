import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/empty_state.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';
import 'package:gymapp_v2/features/training/repository/training_repository.dart';

class WorkoutOverviewPage extends StatefulWidget {
  final TrainingBlock program;
  final WorkoutDay workoutDay;

  const WorkoutOverviewPage({
    super.key,
    required this.program,
    required this.workoutDay,
  });

  @override
  State<WorkoutOverviewPage> createState() => _WorkoutOverviewPageState();
}

class _WorkoutOverviewPageState extends State<WorkoutOverviewPage> {
  int _restSeconds = 90;

  // Çift dokunuşta /active-workout'un iki kez push edilip "Duplicate GlobalKeys"
  // hatasına yol açmasını engeller.
  bool _startingWorkout = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultRestSeconds();
  }

  Future<void> _loadDefaultRestSeconds() async {
    final val = await sl<TrainingRepository>().getDefaultRestSeconds();
    if (!mounted) return;
    setState(() {
      _restSeconds = val;
    });
  }

  Future<void> _saveRestSeconds(int seconds) async {
    await sl<TrainingRepository>().saveDefaultRestSeconds(seconds);
    if (!mounted) return;
    setState(() {
      _restSeconds = seconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentDay = widget.workoutDay;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildBackgroundGlow(),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: AppLayout.bentoCellHeight,
                pinned: true,
                backgroundColor: AppColors.background,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: EdgeInsets.only(left: AppSpacing.lg, bottom: AppSpacing.md),
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.program.name,
                        style: AppTextStyles.heroTitle.copyWith(
                          fontSize: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Gün: ${currentDay.name}',
                        style: AppTextStyles.sectionLabel.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                  ),
                ),
              ),
              if (currentDay.exercises.isEmpty)
                const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.assignment_rounded,
                    title: 'Hareket bulunamadı.',
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildExerciseCard(
                        context,
                        currentDay.exercises[index],
                        index,
                      ),
                      childCount: currentDay.exercises.length,
                    ),
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: AppLayout.bottomNavClearance + AppSpacing.lg + 120)),
            ],
          ),
          if (currentDay.exercises.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildStartSection(context, currentDay),
            ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    return Positioned(
      top: 100,
      right: -100,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, WorkoutExercise ex, int index) {
    return GlassContainer(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: AppTextStyles.emptyTitle.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex.exerciseName,
                  style: AppTextStyles.listTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    _miniBadge(
                      Icons.repeat_rounded,
                      '${ex.targetSets ?? 3} Set',
                    ),
                    SizedBox(width: AppSpacing.xs),
                    _miniBadge(
                      Icons.fitness_center_rounded,
                      '${ex.targetReps ?? '8-12'} Tekrar',
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push(
              '/exercise-progress',
              extra: {
                'exerciseId': ex.exerciseId,
                'exerciseName': ex.exerciseName,
              },
            ),
            icon: Icon(
              Icons.auto_graph_rounded,
              color: AppColors.primary.withValues(alpha: 0.8),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBadge(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.sm / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          SizedBox(width: AppSpacing.xxs),
          Text(
            text,
            style: AppTextStyles.cardCaption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartSection(BuildContext context, WorkoutDay currentDay) {
    final values = [60, 90, 120, 150, 180];

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withValues(alpha: 0),
            AppColors.background.withValues(alpha: 0.95),
            AppColors.background,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DİNLENME SÜRESİ:',
                  style: AppTextStyles.sectionLabel.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                  children: values.map((val) {
                    final bool isSelected = _restSeconds == val;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: GestureDetector(
                        onTap: () => _saveRestSeconds(val),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(AppRadius.sm / 2),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.glassBorder,
                            ),
                          ),
                          child: Text(
                            '$val sn',
                            style: AppTextStyles.cardCaption.copyWith(
                              color: isSelected ? Colors.black : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PremiumButton(
              text: 'İDMANI BAŞLAT',
              icon: Icons.timer_outlined,
              onPressed: () {
                if (_startingWorkout) return;
                _startingWorkout = true;
                context.push(
                  '/active-workout',
                  extra: {
                    'day': currentDay,
                    'trainingBlockId': widget.program.id,
                    'restSeconds': _restSeconds,
                  },
                ).then((_) {
                  if (mounted) _startingWorkout = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
