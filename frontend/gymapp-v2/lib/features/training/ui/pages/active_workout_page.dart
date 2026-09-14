import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/empty_state.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';
import 'package:gymapp_v2/features/training/models/completed_set_data.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/active_workout/active_workout_bloc.dart';
import 'package:gymapp_v2/features/training/bloc/weekly_progress_cubit.dart';
import 'package:gymapp_v2/core/utils/formatting_utils.dart';
import 'package:gymapp_v2/features/training/ui/widgets/last_performance_banner.dart';
import 'package:gymapp_v2/features/training/models/exercise.dart';
import 'package:gymapp_v2/features/training/ui/widgets/exercise_selector_modal.dart';
import 'package:gymapp_v2/features/training/repository/training_repository.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';

class ActiveWorkoutPage extends StatefulWidget {
  final WorkoutDay workoutDay;
  final int? trainingBlockId;
  final int restSeconds;

  const ActiveWorkoutPage({
    super.key,
    required this.workoutDay,
    this.trainingBlockId,
    this.restSeconds = 90,
  });

  @override
  State<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();


  @override
  void initState() {
    super.initState();
    final ActiveWorkoutBloc bloc = context.read<ActiveWorkoutBloc>();
    if (bloc.state.workoutDay?.id != widget.workoutDay.id) {
      bloc.add(
        StartWorkout(
          widget.workoutDay,
          trainingBlockId: widget.trainingBlockId,
          restSeconds: widget.restSeconds,
        ),
      );
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ActiveWorkoutBloc, ActiveWorkoutState>(
      listenWhen: (prev, curr) =>
          prev.currentWeight != curr.currentWeight ||
          prev.currentReps != curr.currentReps ||
          prev.status != curr.status ||
          prev.currentSetIndex != curr.currentSetIndex ||
          prev.currentExerciseIndex != curr.currentExerciseIndex,
      listener: (context, state) {
        // Sync controllers with BLoC state when they change (e.g. on set start)
        if (_weightController.text != state.currentWeight.toInt().toString()) {
          _weightController.text = state.currentWeight == 0 ? '' : state.currentWeight.toInt().toString();
        }
        if (_repsController.text != state.currentReps.toString()) {
          _repsController.text = state.currentReps == 0 ? '' : state.currentReps.toString();
        }

      },
      builder: (context, state) {
        if (state.status == ActiveWorkoutStatus.finished) {
           // We can also handle navigation in listener, but for safety it's here
           // Actually it's better in listener to avoid build-time navigation
           return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
        }

        if (state.workoutDay == null || state.workoutDay!.exercises.isEmpty) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: EmptyState(
              icon: Icons.assignment_rounded,
              title: 'Antrenman günü veya egzersiz listesi bulunamadı.',
            ),
          );
        }

        // Index Out of Bounds koruması
        final bool isIndexValid =
            state.currentExerciseIndex >= 0 &&
            state.currentExerciseIndex < state.workoutDay!.exercises.length;

        if (!isIndexValid) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final currentExercise =
            state.workoutDay!.exercises[state.currentExerciseIndex];

        return BlocListener<ActiveWorkoutBloc, ActiveWorkoutState>(
          listenWhen: (prev, curr) => prev.status != curr.status && curr.status == ActiveWorkoutStatus.finished,
          listener: (context, state) {
            // Antrenman bittiğinde WebSocket sinyali beklemeden yerel reaktivite ile gelişimi yenile
            context.read<WeeklyProgressCubit>().loadMyProgress();
            
            context.pushReplacement(
              '/workout-summary',
              extra: {
                'completedSets': state.completedSets,
                'isOfflineSaved': state.isOfflineSaved,
              },
            );
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: _buildTimerTitle(state),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.bolt_rounded, color: AppColors.primary),
                  onPressed: () => _confirmQuickFinish(context),
                ),
              ],
            ),
            body: Stack(
              children: [
                _buildModernBackground(),
                Column(
                  children: [
                    SizedBox(height: kToolbarHeight + AppSpacing.xxl),
                    _buildExerciseNavigationList(state),
                    _buildExerciseInfo(currentExercise, state),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: _buildMainControl(state),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimerTitle(ActiveWorkoutState state) {
    return GlassContainer(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      borderRadius: AppRadius.pill,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.primary, size: 18),
          SizedBox(width: AppSpacing.xs),
          Text(
            FormattingUtils.formatDuration(state.totalWorkoutSeconds),
            style: AppTextStyles.greeting.copyWith(
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBackground() {
    return Stack(
      children: [
        Positioned(
          bottom: -100,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
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
        ),
      ],
    );
  }

  Widget _buildExerciseInfo(WorkoutExercise ex, ActiveWorkoutState state) {
    final sub = state.substitutions[ex.id];
    final exerciseName = sub != null ? sub.name : ex.exerciseName;
    final effectiveId = sub != null ? sub.id : ex.exerciseId;
    final int targetSets = ex.targetSets ?? 3;
    final bool isExtraSet = state.currentSetIndex > targetSets;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Text(
            exerciseName.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTextStyles.heroTitle.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '(değiştirildi)',
              style: AppTextStyles.cardCaption.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isExtraSet)
                _buildGhostBadge(
                  'EKSTRA SET ${state.currentSetIndex}',
                  highlight: true,
                )
              else
                _buildGhostBadge(
                  'SET ${state.currentSetIndex} / $targetSets',
                ),
              SizedBox(width: AppSpacing.sm),
              _buildGhostBadge(
                'HEDEF: ${ex.targetReps ?? '8-12'} TEKRAR',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          LastPerformanceBanner(key: ValueKey(effectiveId), exerciseId: effectiveId),
        ],
      ),
    );
  }

  Widget _buildGhostBadge(String text, {bool highlight = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: highlight ? AppColors.primary : AppColors.glassBorder,
        ),
      ),
      child: highlight
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  color: AppColors.primary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  text,
                  style: AppTextStyles.sectionLabel.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            )
          : Text(
              text,
              style: AppTextStyles.sectionLabel.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
    );
  }

  Widget _buildMainControl(ActiveWorkoutState state) {
    switch (state.status) {
      case ActiveWorkoutStatus.ready:
        return _buildReadyView(state);
      case ActiveWorkoutStatus.preparing:
        return _buildPreparingView(state);
      case ActiveWorkoutStatus.active:
        return _buildActiveView(state);
      case ActiveWorkoutStatus.resting:
        return _buildRestView(state);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPreparingView(ActiveWorkoutState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            state.preparationSeconds.toString(),
            style: AppTextStyles.heroDisplay.copyWith(
              fontSize: 120,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'HAZIR MISIN?',
            style: AppTextStyles.emptyTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyView(ActiveWorkoutState state) {
    final currentExercise = state.workoutDay!.exercises[state.currentExerciseIndex];
    final bool showSubstitute = state.completedSets.where((s) => s.workoutExerciseId == currentExercise.id).isEmpty;
    final int targetSets = currentExercise.targetSets ?? 3;
    final bool isExtraSet = state.currentSetIndex > targetSets;

    return Column(
      children: [
        Icon(
          Icons.timer_3_rounded,
          size: 80,
          color: AppColors.primary,
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          isExtraSet ? 'EKSTRA SET İÇİN HAZIR MISIN?' : 'SIRADAKİ SET İÇİN HAZIR MISIN?',
          style: AppTextStyles.emptyTitle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        PremiumButton(
          text: 'SET\'E BAŞLA',
          onPressed: () => context.read<ActiveWorkoutBloc>().add(StartSet()),
        ),
        SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.done_all_rounded, size: 20),
              label: Text(
                'EGZERSİZİ BİTİR',
                style: AppTextStyles.buttonText.copyWith(color: AppColors.primary),
              ),
              onPressed: () => context.read<ActiveWorkoutBloc>().add(const FinishExercise()),
            ),
            TextButton.icon(
              icon: const Icon(Icons.skip_next_rounded, size: 20),
              label: Text(
                'EGZERSİZİ ATLA',
                style: AppTextStyles.buttonText.copyWith(color: AppColors.textMuted),
              ),
              onPressed: () => context.read<ActiveWorkoutBloc>().add(const SkipExercise()),
            ),
            if (showSubstitute) ...[
              TextButton.icon(
                icon: const Icon(Icons.swap_horiz_rounded, size: 20, color: AppColors.primary),
                label: Text(
                  'DEĞİŞTİR',
                  style: AppTextStyles.buttonText.copyWith(color: AppColors.primary),
                ),
                onPressed: () async {
                  final repo = sl<TrainingRepository>();
                  final res = await repo.getAllExercises();
                  if (!mounted) return;
                  final picked = await showModalBottomSheet<Exercise>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ExerciseSelectorModal(allExercises: res.data ?? []),
                  );
                  if (!mounted) return;
                  if (picked != null) {
                    context.read<ActiveWorkoutBloc>().add(SubstituteExercise(picked));
                  }
                },
              ),
            ],
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        _buildCompletedSetsEditor(state),
      ],
    );
  }

  Widget _buildActiveView(ActiveWorkoutState state) {
    return Column(
      children: [
        Text(
          FormattingUtils.formatDuration(state.setStopwatchSeconds),
          style: AppTextStyles.heroDisplay.copyWith(
            fontSize: 72,
            color: AppColors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          'SET SÜRESİ',
          style: AppTextStyles.sectionLabel.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 3,
          ),
        ),
        SizedBox(height: AppSpacing.xxl),
        GlassContainer(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildValueInput(
                      controller: _weightController,
                      label: 'AĞIRLIK',
                      subtitle: 'KG',
                      icon: Icons.fitness_center_rounded,
                      keyboardType: TextInputType.number,
                      formatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (val) {
                        final weight = double.tryParse(val) ?? 0.0;
                        context.read<ActiveWorkoutBloc>().add(UpdateWorkoutInput(weight: weight));
                      },
                    ),
                  ),
                  SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: _buildValueInput(
                      controller: _repsController,
                      label: 'TEKRAR',
                      subtitle: 'REP',
                      icon: Icons.repeat_rounded,
                      keyboardType: TextInputType.number,
                      formatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (val) {
                        final reps = int.tryParse(val) ?? 0;
                        context.read<ActiveWorkoutBloc>().add(UpdateWorkoutInput(reps: reps));
                      },
                    ),
                  ),
                ],
              ),
              PremiumButton(
                text: 'SETİ BİTİR',
                onPressed: () => _finishSet(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRestView(ActiveWorkoutState state) {
    final totalRestSeconds = state.sessionRestSeconds;
    final progressValue = totalRestSeconds > 0
        ? 1.0 - (state.restTimerSeconds / totalRestSeconds)
        : 0.0;

    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: progressValue.clamp(0.0, 1.0),
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.glassWhite,
                  color: AppColors.primary,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${state.restTimerSeconds}',
                    style: AppTextStyles.heroDisplay.copyWith(
                      fontSize: 64,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'DİNLENME',
                    style: AppTextStyles.sectionLabel.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.xxl * 1.5),
        TextButton.icon(
          onPressed: () => context.read<ActiveWorkoutBloc>().add(SkipRest()),
          icon: const Icon(Icons.skip_next_rounded, size: 28),
          label: Text(
            'DİNLENMEYİ GEÇ',
            style: AppTextStyles.buttonText.copyWith(
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildValueInput({
    required TextEditingController controller,
    required String label,
    required String subtitle,
    required IconData icon,
    required TextInputType keyboardType,
    required void Function(String) onChanged,
    List<TextInputFormatter>? formatters,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.cardLabel.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          textAlign: TextAlign.center,
          onChanged: onChanged,
          style: AppTextStyles.heroDisplay.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: AppTextStyles.heroDisplay.copyWith(color: AppColors.textPrimary.withValues(alpha: 0.1)),
            contentPadding: EdgeInsets.zero,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.xxs),
        Text(
          subtitle,
          style: AppTextStyles.cardLabel.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  void _finishSet(BuildContext context) {
    final bloc = context.read<ActiveWorkoutBloc>();
    final state = bloc.state;

    if (state.currentWeight <= 0) {
      _showSnackBar(
        context,
        'Lütfen geçerli bir ağırlık giriniz (kg).',
        AppColors.warning,
      );
      return;
    }

    if (state.currentReps <= 0) {
      _showSnackBar(
        context,
        'Lütfen tekrar sayısını giriniz.',
        AppColors.warning,
      );
      return;
    }

    bloc.add(const FinishSet());
  }

  Widget _buildExerciseNavigationList(ActiveWorkoutState state) {
    if (state.workoutDay == null) return const SizedBox.shrink();
    final exercises = state.workoutDay!.exercises;

    return Container(
      height: 48,
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        physics: const BouncingScrollPhysics(),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final ex = exercises[index];
          final bool isCurrent = state.currentExerciseIndex == index;
          final bool isFinished = state.finishedExerciseIds.contains(ex.id);
          final bool isSkipped = state.skippedExerciseIds.contains(ex.id);

          Color chipBgColor;
          Color textColor;
          Widget? prefixIcon;
          TextDecoration decoration = TextDecoration.none;

          if (isCurrent) {
            chipBgColor = AppColors.primary;
            textColor = Colors.black;
            prefixIcon = const Icon(Icons.fitness_center_rounded, size: 16, color: Colors.black);
          } else if (isFinished) {
            chipBgColor = AppColors.primary.withValues(alpha: 0.15);
            textColor = AppColors.primary;
            prefixIcon = const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary);
          } else if (isSkipped) {
            chipBgColor = AppColors.textPrimary.withValues(alpha: 0.03);
            textColor = AppColors.textMuted;
            decoration = TextDecoration.lineThrough;
            prefixIcon = const Icon(Icons.block_rounded, size: 16, color: AppColors.textMuted);
          } else {
            chipBgColor = AppColors.textPrimary.withValues(alpha: 0.05);
            textColor = AppColors.textSecondary;
          }

          final sub = state.substitutions[ex.id];
          return Container(
            margin: EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (prefixIcon != null) ...[
                    prefixIcon,
                    SizedBox(width: AppSpacing.xxs),
                  ],
                  Text(
                    sub != null ? sub.name : ex.exerciseName,
                    style: AppTextStyles.cardCaption.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      decoration: decoration,
                    ),
                  ),
                ],
              ),
              selected: isCurrent,
              onSelected: (selected) {
                if (index != state.currentExerciseIndex) {
                  context.read<ActiveWorkoutBloc>().add(GoToExercise(index));
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: chipBgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                side: BorderSide(
                  color: isCurrent ? AppColors.primary : AppColors.glassBorder,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompletedSetsEditor(ActiveWorkoutState state) {
    if (state.workoutDay == null) return const SizedBox.shrink();
    final currentExercise = state.workoutDay!.exercises[state.currentExerciseIndex];

    final List<MapEntry<int, CompletedSetData>> exerciseSets = [];
    for (int i = 0; i < state.completedSets.length; i++) {
      if (state.completedSets[i].workoutExerciseId == currentExercise.id) {
        exerciseSets.add(MapEntry(i, state.completedSets[i]));
      }
    }

    if (exerciseSets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Text(
            'TAMAMLANAN SETLER',
            style: AppTextStyles.sectionLabel.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: exerciseSets.length,
          itemBuilder: (context, index) {
            final entry = exerciseSets[index];
            final globalIndex = entry.key;
            final setData = entry.value;

            return GlassContainer(
              margin: EdgeInsets.only(bottom: AppSpacing.xs),
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Text(
                    '${setData.setIndex}. Set',
                    style: AppTextStyles.bodyText.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${setData.weight.toStringAsFixed(0)} kg × ${setData.reps} Tekrar',
                    style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                    onPressed: () => _showEditSetDialog(context, globalIndex, setData),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                    onPressed: () {
                      context.read<ActiveWorkoutBloc>().add(DeleteCompletedSet(globalIndex));
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showEditSetDialog(BuildContext context, int globalIndex, CompletedSetData setData) {
    // Bloc'u önceden yakala. Event'i diyalog TAMAMEN kapandıktan SONRA (.then) gönder;
    // böylece sayfa, dialog overlay'i kapanırken yeniden çizilmez. Bu, "Duplicate
    // GlobalKeys / _dependents.isEmpty / RenderFlex overflow" hatalarını engeller.
    final bloc = context.read<ActiveWorkoutBloc>();
    showDialog<({double weight, int reps})>(
      context: context,
      builder: (_) => _EditSetDialog(setData: setData),
    ).then((result) {
      if (result != null) {
        bloc.add(EditCompletedSet(globalIndex, result.weight, result.reps));
      }
    });
  }

  void _confirmQuickFinish(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => GlassContainer(
            padding: EdgeInsets.all(AppSpacing.xl),
            borderRadius: AppRadius.xl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.priority_high_rounded,
                  color: AppColors.error,
                  size: 48,
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'İdmanı Bitir?',
                  style: AppTextStyles.heroTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Antrenmanı erken sonlandırmak istediğine emin misin?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'İPTAL',
                          style: AppTextStyles.buttonText.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: PremiumButton(
                        text: 'EVET, BİTİR',
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<ActiveWorkoutBloc>().add(
                            QuickFinishWorkout(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  // FormattingUtils.formatDuration kullanıldı

  void _showSnackBar(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        margin: EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }
}

/// Seti düzenleme diyaloğu. Controller'ları kendi yaşam döngüsünde yönetir
/// (dispose, rota tamamen kaldırıldıktan sonra çalışır) — böylece "TextEditingController
/// used after being disposed" hatası oluşmaz. Sonucu pop ile döndürür; kaydetme event'i
/// çağıran tarafta, diyalog kapandıktan sonra gönderilir.
class _EditSetDialog extends StatefulWidget {
  final CompletedSetData setData;

  const _EditSetDialog({required this.setData});

  @override
  State<_EditSetDialog> createState() => _EditSetDialogState();
}

class _EditSetDialogState extends State<_EditSetDialog> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.setData.weight.toInt().toString());
    _repsController = TextEditingController(text: widget.setData.reps.toString());
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _submit() {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final reps = int.tryParse(_repsController.text) ?? 0;
    if (weight > 0 && reps > 0) {
      Navigator.pop(context, (weight: weight, reps: reps));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Text(
        'Seti Düzenle',
        style: AppTextStyles.emptyTitle.copyWith(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Ağırlık (kg)',
              labelStyle: TextStyle(color: AppColors.textMuted),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.glassBorder)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
            ),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _repsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Tekrar',
              labelStyle: TextStyle(color: AppColors.textMuted),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.glassBorder)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
            ),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'İPTAL',
            style: AppTextStyles.buttonText.copyWith(color: AppColors.textMuted),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            'KAYDET',
            style: AppTextStyles.buttonText.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
