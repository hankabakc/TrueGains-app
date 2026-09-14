import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';
import 'package:gymapp_v2/features/training/models/exercise.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/create_program/create_personal_program_cubit.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/create_program/create_personal_program_state.dart';
import 'package:gymapp_v2/features/training/ui/widgets/day_builder_card.dart';
import 'package:gymapp_v2/features/training/ui/pages/exercise_selection_page.dart';
import 'package:gymapp_v2/features/training/ui/widgets/exercise_param_form.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/training/bloc/training_bloc.dart';
import 'package:gymapp_v2/features/training/bloc/training_event.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/features/training/repository/training_repository.dart';
import 'package:gymapp_v2/features/training/models/weekly_progress.dart';

class CreatePersonalProgramPage extends StatefulWidget {
  final TrainingBlock? initialBlock;
  final bool isTemplateMode;
  final bool isReadOnly;

  const CreatePersonalProgramPage({
    super.key,
    this.initialBlock,
    this.isTemplateMode = false,
    this.isReadOnly = false,
  });

  @override
  State<CreatePersonalProgramPage> createState() => _CreatePersonalProgramPageState();
}

class _CreatePersonalProgramPageState extends State<CreatePersonalProgramPage> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text:
          widget.initialBlock?.name ??
          (widget.isTemplateMode
              ? 'Yeni Antrenman Şablonu'
              : 'Kişisel Antrenman Programım'),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      final isAuthenticated = authState is AuthAuthenticated;
      if (!isAuthenticated) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bu sayfaya erişim yetkiniz bulunmamaktadır.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        );
        context.pop();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              sl<CreatePersonalProgramCubit>()..init(
                widget.initialBlock,
                isTemplateMode: widget.isTemplateMode,
              ),
      child: BlocConsumer<CreatePersonalProgramCubit, CreatePersonalProgramState>(
        listener: (context, state) {
          if (state.status == CreatePersonalProgramStatus.success) {
            context.read<TrainingBloc>().add(const LoadMyPrograms());

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Program başarıyla oluşturuldu!')),
            );
            context.pop(true);
          } else if (state.status == CreatePersonalProgramStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error ?? 'Hata oluştu!')),
            );
          }
        },
        builder: (context, state) {
          final authState = context.read<AuthBloc>().state;
          final isCoach = authState is AuthAuthenticated && authState.auth.role == UserRole.COACH;
          final isTemplateBanner = widget.isTemplateMode || (widget.initialBlock?.isTemplate ?? false);
          final isAssignedBanner = isCoach && !isTemplateBanner && widget.initialBlock != null && widget.initialBlock!.coachId != null && widget.initialBlock!.clientId > 0;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              title: Text(
                widget.initialBlock != null
                    ? (state.isTemplate ? 'ŞABLONU DÜZENLE' : 'PROGRAMI DÜZENLE')
                    : (state.isTemplate ? 'YENİ ŞABLON' : 'YENİ PROGRAM'),
                style: AppTextStyles.heroTitle,
              ),
              centerTitle: true,
            ),
            body: Column(
              children: [
                if (isTemplateBanner)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.md),
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '⚠️ Şablon Güncellemesi: Bu şablon üzerinde yapacağınız değişiklikler sadece yeni atayacağınız sporcuları etkiler. Mevcut atanmış sporcuların programları DEĞİŞMEZ.',
                            style: AppTextStyles.bodyText.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isAssignedBanner)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.md),
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '⚡ Atanmış Program: Bu program doğrudan sporcunuza bağlıdır. Yapacağınız değişiklikler anlık olarak sporcunun ekranına yansıyacaktır.',
                            style: AppTextStyles.bodyText.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: TextField(
                    controller: _nameController,
                    enabled: !widget.isReadOnly,
                    style: AppTextStyles.listTitle,
                    decoration: InputDecoration(
                      labelText: 'PROGRAM ADI',
                      labelStyle: AppTextStyles.sectionLabel.copyWith(color: AppColors.primary),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ),
                _DurationWeeksSelector(isReadOnly: widget.isReadOnly),
                if (isAssignedBanner && widget.initialBlock != null)
                  _WeekAdherenceStrip(
                    clientId: widget.initialBlock!.clientId,
                    startDate: widget.initialBlock!.startDate,
                    durationWeeks: state.durationWeeks,
                    targetDays: state.draftDays.where((d) => d.exercises.isNotEmpty).length,
                  ),
                const _DaySelectorHeader(),
                Expanded(
                  child: state.isLoadingExercises
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : _ProgramBuilderList(isReadOnly: widget.isReadOnly),
                ),
                _SaveActionSection(
                  blockId: widget.initialBlock?.id,
                  isReadOnly: widget.isReadOnly,
                  nameController: _nameController,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DaySelectorHeader extends StatelessWidget {
  const _DaySelectorHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreatePersonalProgramCubit, CreatePersonalProgramState>(
      builder: (context, state) {
        return SizedBox(
          height: 90,
          child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: state.draftDays.length,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Material(
                    elevation: 0,
                    color: Colors.transparent,
                    child: Opacity(
                      opacity: 0.8,
                      child: child,
                    ),
                  );
                },
                child: child,
              );
            },
            onReorderItem: (oldIdx, newIdx) {
              context.read<CreatePersonalProgramCubit>().reorderDays(oldIdx, newIdx);
            },
            itemBuilder: (context, index) {
              final isSelected = state.selectedDayIndex == index;
              final isOff = state.isOffDays[index];
              final day = state.draftDays[index];
              return GestureDetector(
                key: ValueKey('day_${day.name}'),
                onTap: () => context.read<CreatePersonalProgramCubit>().selectDay(index),
                child: Container(
                  width: 60,
                  margin: EdgeInsets.symmetric(horizontal: AppSpacing.xxs, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.glassWhite,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.glassBorder,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.dayOrder}',
                        style: isSelected 
                            ? AppTextStyles.cardValue.copyWith(color: Colors.white)
                            : AppTextStyles.cardValue,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        isOff ? 'OFF' : 'GÜN',
                        style: isSelected 
                            ? AppTextStyles.cardLabel.copyWith(color: Colors.white.withValues(alpha: 0.8))
                            : AppTextStyles.cardLabel,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProgramBuilderList extends StatelessWidget {
  final bool isReadOnly;
  const _ProgramBuilderList({required this.isReadOnly});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreatePersonalProgramCubit, CreatePersonalProgramState>(
      builder: (context, state) {
        final currentDay = state.draftDays[state.selectedDayIndex];
        final isOff = state.isOffDays[state.selectedDayIndex];

        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                label: 'GÜN DETAYI',
              ),
              SizedBox(height: AppSpacing.md),
              DayBuilderCard(
                dayIndex: state.selectedDayIndex + 1,
                dayOrder: state.selectedDayIndex,
                workoutDay: currentDay,
                isOffDay: isOff,
                isMagnetEnabled: state.isMagnetEnabled[state.selectedDayIndex],
                expandedGroups: state.expandedGroups[state.selectedDayIndex],
                isReadOnly: isReadOnly,
                onOffDayToggle: (val) => context.read<CreatePersonalProgramCubit>().toggleOffDay(state.selectedDayIndex),
                onToggleMagnet: () => context.read<CreatePersonalProgramCubit>().toggleMagnet(state.selectedDayIndex, !state.isMagnetEnabled[state.selectedDayIndex]),
                onToggleGroup: (groupName) => context.read<CreatePersonalProgramCubit>().toggleGroup(state.selectedDayIndex, groupName),
                onAddExercises: () async {
                  final cubit = context.read<CreatePersonalProgramCubit>();
                  final List<Exercise>? selected =
                      await showModalBottomSheet<List<Exercise>>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder:
                            (modalContext) => BlocProvider.value(
                              value: cubit,
                              child: ExerciseSelectionPage(
                                allExercises: state.allExercises,
                                isSelectionMode: true,
                              ),
                            ),
                      );
                  if (selected != null && context.mounted) {
                    final workoutExercises =
                        selected
                            .map(
                              (e) => WorkoutExercise(
                                id: 0,
                                exerciseId: e.id,
                                exerciseName: e.name,
                                muscleGroup: e.muscleGroup,
                                orderIndex: 0,
                                targetSets: 3,
                                targetReps: '10',
                                logs: [],
                              ),
                            )
                            .toList();
                    cubit.addExercises(
                      state.selectedDayIndex,
                      workoutExercises,
                    );
                  }
                },
                onEditExercise: (exIndex, exercise) {
                  final cubit = context.read<CreatePersonalProgramCubit>();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder:
                        (modalContext) => BlocProvider.value(
                          value: cubit,
                          child: ExerciseEditModal(
                            exerciseOrder: exIndex + 1,
                            initialData: exercise,
                            onSaved:
                                (updated) => cubit.updateExercise(
                                  state.selectedDayIndex,
                                  exIndex,
                                  updated,
                                ),
                            onDelete:
                                () => cubit.deleteExercise(
                                  state.selectedDayIndex,
                                  exIndex,
                                ),
                          ),
                        ),
                  );
                },
                onReorderItem: (oldIdx, newIdx) => context.read<CreatePersonalProgramCubit>().reorderExercises(state.selectedDayIndex, oldIdx, newIdx),
                onReorderMuscleGroup: (oldIdx, newIdx) => context.read<CreatePersonalProgramCubit>().reorderMuscleGroups(state.selectedDayIndex, oldIdx, newIdx),
                onReorderInGroup: (groupName, oldIdx, newIdx) => context.read<CreatePersonalProgramCubit>().reorderExerciseInGroup(state.selectedDayIndex, groupName, oldIdx, newIdx),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SaveActionSection extends StatelessWidget {
  final int? blockId;
  final bool isReadOnly;
  final TextEditingController nameController;
  const _SaveActionSection({this.blockId, this.isReadOnly = false, required this.nameController});

  @override
  Widget build(BuildContext context) {
    if (isReadOnly) return const SizedBox.shrink();

    return BlocBuilder<CreatePersonalProgramCubit, CreatePersonalProgramState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.glassBorder)),
          ),
          child: state.status == CreatePersonalProgramStatus.loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : PremiumButton(
                  text:
                      blockId != null
                          ? (state.isTemplate
                              ? 'ŞABLONU GÜNCELLE'
                              : 'PROGRAMI GÜNCELLE')
                          : (state.isTemplate
                              ? 'ŞABLONU OLUŞTUR'
                              : 'PROGRAMI OLUŞTUR'),
                  onPressed: () {
                    final name = nameController.text.trim();
                    
                    context.read<CreatePersonalProgramCubit>().saveProgram(
                      name.isEmpty ? (state.isTemplate ? 'Yeni Şablon' : 'Kişisel Program') : name,
                    );
                  },
                ),
        );
      },
    );
  }
}

class _DurationWeeksSelector extends StatelessWidget {
  final bool isReadOnly;

  const _DurationWeeksSelector({required this.isReadOnly});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreatePersonalProgramCubit, CreatePersonalProgramState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROGRAM SÜRESİ (HAFTA)',
                style: AppTextStyles.sectionLabel.copyWith(color: AppColors.primary),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                    onPressed: isReadOnly
                        ? null
                        : () {
                            context.read<CreatePersonalProgramCubit>().setDurationWeeks(state.durationWeeks - 1);
                          },
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.glassWhite,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Text(
                      '${state.durationWeeks}',
                      style: AppTextStyles.cardValue,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    onPressed: isReadOnly
                        ? null
                        : () {
                            context.read<CreatePersonalProgramCubit>().setDurationWeeks(state.durationWeeks + 1);
                          },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeekAdherenceStrip extends StatefulWidget {
  final int clientId;
  final DateTime startDate;
  final int durationWeeks;
  final int targetDays;

  const _WeekAdherenceStrip({
    required this.clientId,
    required this.startDate,
    required this.durationWeeks,
    required this.targetDays,
  });

  @override
  State<_WeekAdherenceStrip> createState() => _WeekAdherenceStripState();
}

class _WeekAdherenceStripState extends State<_WeekAdherenceStrip> {
  int? _selectedWeekIndex;
  List<WeeklyHistoryItem>? _history;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final res = await sl<TrainingRepository>().getClientWeeklyHistory(widget.clientId);
      if (res.success && res.data != null) {
        if (mounted) {
          setState(() {
            _history = res.data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  DateTime _getAnchorMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final anchorMonday = _getAnchorMonday(widget.startDate);
    final Map<int, WeeklyHistoryItem> weekMap = {};
    if (_history != null) {
      for (final item in _history!) {
        final itemMonday = _getAnchorMonday(item.weekStartDate);
        final k = (itemMonday.difference(anchorMonday).inDays / 7).floor() + 1;
        if (k >= 1 && k <= widget.durationWeeks) {
          weekMap[k] = item;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          child: Text(
            'HAFTALIK UYUM (SPORCU)',
            style: AppTextStyles.sectionLabel.copyWith(color: AppColors.primary),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: widget.durationWeeks,
            itemBuilder: (context, index) {
              final weekNum = index + 1;
              final isSelected = _selectedWeekIndex == index;
              final hasData = weekMap.containsKey(weekNum);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedWeekIndex = isSelected ? null : index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: AppSpacing.sm, bottom: AppSpacing.sm, top: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (hasData ? AppColors.primary.withValues(alpha: 0.15) : AppColors.glassWhite),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (hasData ? AppColors.primary.withValues(alpha: 0.4) : AppColors.glassBorder),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Hafta $weekNum',
                      style: isSelected
                          ? AppTextStyles.cardLabel.copyWith(color: Colors.white, fontWeight: FontWeight.bold)
                          : AppTextStyles.cardLabel.copyWith(color: hasData ? Colors.white : AppColors.textMuted),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_selectedWeekIndex != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.glassWhite,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: () {
                final weekNum = _selectedWeekIndex! + 1;
                final item = weekMap[weekNum];
                if (item != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hafta $weekNum Detayları',
                        style: AppTextStyles.listTitle.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Tamamlanan Günler: ${item.completedDays} / ${item.targetDays}',
                        style: AppTextStyles.bodyText,
                      ),
                      Text(
                        'Başarı Oranı: %${item.successPercentage.toStringAsFixed(1)}',
                        style: AppTextStyles.bodyText,
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hafta $weekNum Detayları',
                        style: AppTextStyles.listTitle.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '0 / ${widget.targetDays} — kayıt yok',
                        style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  );
                }
              }(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
