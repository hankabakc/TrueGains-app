import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_source.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_dashboard/diet_dashboard_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_dashboard/diet_dashboard_state.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/features/nutrition/presentation/widgets/day_picker_widget.dart';
import 'package:gymapp_v2/features/nutrition/presentation/widgets/macro_board_widget.dart';
import 'package:gymapp_v2/features/nutrition/presentation/widgets/meal_card_widget.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/nutrition/presentation/widgets/no_active_diet_program_view.dart';

class DietDashboardPage extends StatefulWidget {
  final int? programId;
  const DietDashboardPage({super.key, this.programId});

  @override
  State<DietDashboardPage> createState() => _DietDashboardPageState();
}

class _DietDashboardPageState extends State<DietDashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = sl<DietDashboardCubit>()..loadData(programId: widget.programId);
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          cubit.subscribeToUpdates(authState.auth.id);
        }
        return cubit;
      },
      child: BlocBuilder<DietDashboardCubit, DietDashboardState>(
        builder: (context, state) {
          final cubit = context.read<DietDashboardCubit>();

          return Scaffold(
            backgroundColor: AppColors.background,
            body:
                state.status == DietDashboardStatus.loading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                    : Stack(
                      children: [
                        _buildBackgroundGlow(),
                        CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            _buildSliverAppBar(context, state, cubit),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: AppSpacing.md),
                                    DayPickerWidget(state: state, cubit: cubit),
                                    const SizedBox(height: AppSpacing.lg),
                                    MacroBoardWidget(state: state),
                                    const SizedBox(height: AppSpacing.lg),
                                    if (state.mainProgram != null)
                                      _buildGoalsAction(context, state, cubit),
                                    const SizedBox(height: AppSpacing.xl),
                                    _buildMealsHeader(state),
                                    const SizedBox(height: AppSpacing.md),
                                    if (state.mainProgram == null)
                                      _buildNoProgramState(
                                        context,
                                        state,
                                        cubit,
                                      )
                                    else if (state.mainProgram!.targetCalories <= 0)
                                      _buildNoGoalsWarning(
                                        context,
                                        state,
                                        cubit,
                                      )
                                    else ...[
                                      _buildMealsList(context, state, cubit),
                                      const SizedBox(height: AppLayout.bottomNavClearance),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
          );
        },
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

  Widget _buildSliverAppBar(
    BuildContext context,
    DietDashboardState state,
    DietDashboardCubit cubit,
  ) {
    final authState = context.read<AuthBloc>().state;
    final isCoach = authState is AuthAuthenticated && authState.auth.user.role == UserRole.COACH;

    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: AppColors.background,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: Text(
          state.mainProgram?.name ?? 'Diyet Paneli',
          style: AppTextStyles.heroTitle.copyWith(
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      actions: [
        if (state.mainProgram != null &&
            (isCoach || state.mainProgram!.source != DietSource.coach))
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary),
            tooltip: 'Adı Değiştir',
            onPressed: () => _renameProgram(context, state, cubit),
          ),
        if (state.mainProgram != null)
          IconButton(
            icon: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
            ),
            onPressed: () async {
              final result = await context.push(
                '/nutrition/gemini-analysis',
                extra: {'programId': state.mainProgram?.id ?? widget.programId},
              );
              if (result == true && context.mounted) {
                cubit.loadData(programId: widget.programId, silent: true);
              }
            },
            tooltip: 'Gemini AI Analizi',
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildGoalsAction(
    BuildContext context,
    DietDashboardState state,
    DietDashboardCubit cubit,
  ) {
    final authState = context.read<AuthBloc>().state;
    final isClient = authState is AuthAuthenticated && authState.auth.user.role == UserRole.CLIENT;

    // Eğer kullanıcı sporcuysa ve diyet programı koç tarafından atanmışsa hedef değiştirme butonunu gizle
    if (isClient && state.mainProgram?.source == DietSource.coach) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
        ),
        icon: const Icon(Icons.track_changes_rounded),
        label: Text(
          'DİYET HEDEFLERİNİ BELİRLE',
          style: AppTextStyles.buttonText.copyWith(fontSize: 16),
        ),
        onPressed: () async {
          final result = await context.push(
            '/nutrition/diet-goals',
            extra: state.mainProgram,
          );
          if (result == true && context.mounted) {
            cubit.loadData(programId: widget.programId, silent: true);
          }
        },
      ),
    );
  }

  Widget _buildMealsHeader(DietDashboardState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'ÖĞÜNLERİN',
          style: AppTextStyles.sectionLabel,
        ),
        if (state.mainProgram != null &&
            state.selectedDayIndex < state.mainProgram!.dietDays.length)
          Text(
            state.mainProgram!.dietDays[state.selectedDayIndex].name,
            style: AppTextStyles.cardCaption.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildNoGoalsWarning(
    BuildContext context,
    DietDashboardState state,
    DietDashboardCubit cubit,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Henüz Hedef Belirlemediniz',
            style: AppTextStyles.emptyTitle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Yemek eklemeye başlamadan önce günlük kalori ve makro hedeflerinizi belirlemelisiniz.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyText.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Builder(
            builder: (context) {
              final authState = context.read<AuthBloc>().state;
              final isClient = authState is AuthAuthenticated && authState.auth.user.role == UserRole.CLIENT;
              if (isClient && state.mainProgram?.source == DietSource.coach) {
                return const SizedBox.shrink();
              }
              return PremiumButton(
                text: 'HEDEFLERİ BELİRLE',
                onPressed: () async {
                  final result = await context.push(
                    '/nutrition/diet-goals',
                    extra: state.mainProgram,
                  );
                  if (result == true && context.mounted) {
                    cubit.loadData(programId: widget.programId, silent: true);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoProgramState(
    BuildContext context,
    DietDashboardState state,
    DietDashboardCubit cubit,
  ) {
    final authState = context.read<AuthBloc>().state;
    final isCoach = authState is AuthAuthenticated && authState.auth.user.role == UserRole.COACH;

    return NoActiveDietProgramView(
      isCoachView: isCoach,
      onSelectProgram: () async {
        final result = await context.push('/nutrition/list/client');
        if (result == true && context.mounted) {
          cubit.loadData(programId: widget.programId, silent: true);
        }
      },
    );
  }

  Widget _buildMealsList(
    BuildContext context,
    DietDashboardState state,
    DietDashboardCubit cubit,
  ) {
    if (state.mainProgram == null ||
        state.selectedDayIndex >= state.mainProgram!.dietDays.length) {
      return const SizedBox();
    }
    final meals = state.mainProgram!.dietDays[state.selectedDayIndex].meals;
    return Column(
      children:
          meals.map((m) => MealCardWidget(
            state: state,
            cubit: cubit,
            meal: m,
            onAddFood: () => _openFoodPicker(
              context,
              cubit,
              mealId: m.id,
              mealType: m.mealType,
            ),
            onDeleteIngredient: (ing) => _deleteIngredientDialog(context, cubit, ing),
          )).toList(),
    );
  }

  Future<void> _openFoodPicker(
    BuildContext context,
    DietDashboardCubit cubit, {
    int? mealId,
    MealType? mealType,
  }) async {
    await context.push(
      '/nutrition/search',
      extra: {'mealId': mealId, 'isTemplateMode': false},
    );
    if (context.mounted) {
      cubit.loadData(programId: widget.programId, silent: true);
    }
  }

  Future<void> _deleteIngredientDialog(
    BuildContext context,
    DietDashboardCubit cubit,
    MealIngredientModel ing,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            title: Text(
              'Besin Sil',
              style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary),
            ),
            content: Text(
              '${ing.foodName} öğünden silinsin mi?',
              style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'İptal',
                  style: AppTextStyles.buttonText.copyWith(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Sil',
                  style: AppTextStyles.buttonText.copyWith(
                    fontSize: 14,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirm == true && ing.id != null) {
      cubit.deleteIngredient(ing.id!);
    }
  }

  Future<void> _renameProgram(
    BuildContext context,
    DietDashboardState state,
    DietDashboardCubit cubit,
  ) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => _RenameProgramDialog(initialName: state.mainProgram?.name ?? ''),
    );

    if (newName != null &&
        newName.isNotEmpty &&
        newName != state.mainProgram?.name) {
      cubit.renameProgram(state.mainProgram!.id, newName);
    }
  }
}

class _RenameProgramDialog extends StatefulWidget {
  final String initialName;
  const _RenameProgramDialog({required this.initialName});

  @override
  State<_RenameProgramDialog> createState() => _RenameProgramDialogState();
}

class _RenameProgramDialogState extends State<_RenameProgramDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      title: Text(
        'Program Adını Değiştir',
        style: AppTextStyles.listTitle.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: AppTextStyles.bodyText.copyWith(
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Yeni program adı',
          hintStyle: AppTextStyles.bodyText.copyWith(
            color: AppColors.textMuted,
          ),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.glassBorder)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'İPTAL',
            style: AppTextStyles.buttonText.copyWith(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(
            'KAYDET',
            style: AppTextStyles.buttonText.copyWith(
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

