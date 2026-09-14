import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/macro_ring_stat.dart';
import 'package:gymapp_v2/core/widgets/nutrient_chip.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:intl/intl.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_entry_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_entry/diet_entry_bloc.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_entry/diet_entry_event.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_entry/diet_entry_state.dart';
import 'package:gymapp_v2/features/nutrition/presentation/widgets/no_active_diet_program_view.dart';

class DietEntryPage extends StatefulWidget {
  const DietEntryPage({super.key});

  @override
  State<DietEntryPage> createState() => _DietEntryPageState();
}

class _DietEntryPageState extends State<DietEntryPage> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    // Sayfa açıldığında verilerin güncel olduğundan emin ol
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DietEntryBloc>().add(const InitializeDietEntry());
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DietEntryBloc, DietEntryState>(
      builder: (context, state) {
        final bloc = context.read<DietEntryBloc>();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              _buildBackgroundGlow(),
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(context),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.md),
                          _buildDateNavigator(context, state, bloc),
                          const SizedBox(height: AppSpacing.lg),

                           if (state.status == DietEntryStatus.loading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                            )
                          else if (state.mainProgram == null)
                            NoActiveDietProgramView(
                              isCoachView: false,
                              onSelectProgram: () => context.push('/nutrition/list/client'),
                            )
                          else ...[
                            if (state.log != null) _buildMacroSummaryCard(state),
                            if (state.log != null) const SizedBox(height: AppSpacing.xl),
                            if (state.error != null && state.log == null)
                              _buildErrorState(state.error!)
                            else if (state.log != null)
                              _buildMealsList(context, state, bloc)
                            else
                              const SizedBox(),
                          ],

                          const SizedBox(height: AppLayout.bottomNavClearance),
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
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
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
          'BESLENME GÜNLÜĞÜ',
          style: AppTextStyles.greeting.copyWith(
            fontSize: 18,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    return Positioned(
      top: 80,
      right: -120,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (_, __) => Container(
          width: 350,
          height: 350,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.04 + _glowController.value * 0.03),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateNavigator(BuildContext context, DietEntryState state, DietEntryBloc bloc) {
    final bool isToday = _isToday(state.selectedDate);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isToday ? AppColors.primary.withValues(alpha: 0.35) : AppColors.glassBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
            onPressed: () => bloc.add(ChangeDate(state.selectedDate.subtract(const Duration(days: 1)))),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: state.selectedDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now().add(const Duration(days: 7)),
                  builder: (context, child) => Theme(
                    data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary)),
                    child: child!,
                  ),
                );
                if (picked != null) bloc.add(ChangeDate(picked));
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('d MMMM', 'tr_TR').format(state.selectedDate),
                    style: AppTextStyles.greeting.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    isToday ? 'Bugün' : DateFormat('EEEE', 'tr_TR').format(state.selectedDate),
                    style: AppTextStyles.cardCaption.copyWith(
                      color: isToday ? AppColors.primary : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            onPressed: () => bloc.add(ChangeDate(state.selectedDate.add(const Duration(days: 1)))),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSummaryCard(DietEntryState state) {
    final totalCal = state.totalCalories;
    final targetCal = state.targetCalories;
    final remaining = (targetCal - totalCal).toInt();

    String statusText;
    Color statusColor;
    if (totalCal == 0) {
      statusText = 'Henüz bir şey yemedin';
      statusColor = AppColors.textMuted;
    } else if (targetCal <= 0) {
      statusText = '${totalCal.toInt()} kcal tüketildi';
      statusColor = AppColors.textSecondary;
    } else if (remaining < 0) {
      statusText = '${remaining.abs()} kcal aşıldı';
      statusColor = AppColors.error;
    } else if (remaining < 200) {
      statusText = 'Hedefe çok yakın!';
      statusColor = AppColors.success;
    } else {
      statusText = '$remaining kcal kaldı';
      statusColor = AppColors.textSecondary;
    }

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baslik ve durum rozeti onceden yan yanaydi; ikisi de esnek olmadigi
          // icin dar telefonlarda "RIGHT OVERFLOWED BY 16 PIXELS" veriyordu.
          // Rozet kendi satirina indi: metin ne kadar uzarsa uzasin tasmaz.
          Text(
            'BUGÜNKÜ TÜKETİMİM',
            style: AppTextStyles.sectionLabel.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${totalCal.toInt()}',
                style: AppTextStyles.heroDisplay.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 42,
                  letterSpacing: -1,
                ),
              ),
              Text(
                targetCal > 0 ? ' / ${targetCal.toInt()} kcal' : ' kcal',
                style: AppTextStyles.bodyText.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              statusText,
              style: AppTextStyles.tagText.copyWith(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MacroRingStat(
                label: 'KALORİ',
                current: totalCal,
                target: targetCal,
                color: remaining < 0 ? AppColors.error : AppColors.primary,
                isCalories: true,
              ),
              MacroRingStat(
                label: 'PROTEİN',
                current: state.totalProtein,
                target: state.mainProgram?.targetProtein ?? 0,
                color: AppColors.protein,
              ),
              MacroRingStat(
                label: 'KARB.',
                current: state.totalCarbs,
                target: state.mainProgram?.targetCarbs ?? 0,
                color: AppColors.carbs,
              ),
              MacroRingStat(
                label: 'YAĞ',
                current: state.totalFat,
                target: state.mainProgram?.targetFat ?? 0,
                color: AppColors.fat,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.glassBorder, height: 1),
          const SizedBox(height: AppSpacing.md),
          _buildMicroNutrients(state),
        ],
      ),
    );
  }

  Widget _buildMicroNutrients(DietEntryState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          NutrientChip(
            label: 'Şeker',
            current: state.totalSugar,
            target: state.mainProgram?.targetSugar ?? 0,
            unit: 'g',
            color: AppColors.sugar,
            highlightExceed: true,
          ),
          NutrientChip(
            label: 'Lif',
            current: state.totalFiber,
            target: state.mainProgram?.targetFiber ?? 0,
            unit: 'g',
            color: AppColors.fiber,
            highlightExceed: false,
          ),
          NutrientChip(
            label: 'Sodyum',
            current: state.totalSodium,
            target: state.mainProgram?.targetSodium ?? 0,
            unit: 'mg',
            color: AppColors.sodium,
            highlightExceed: true,
          ),
          NutrientChip(
            label: 'Kolesterol',
            current: state.totalCholesterol,
            target: state.mainProgram?.targetCholesterol ?? 0,
            unit: 'mg',
            color: AppColors.cholesterol,
            highlightExceed: true,
          ),
          NutrientChip(
            label: 'Potasyum',
            current: state.totalPotassium,
            target: state.mainProgram?.targetPotassium ?? 0,
            unit: 'mg',
            color: AppColors.potassium,
            highlightExceed: false,
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList(BuildContext context, DietEntryState state, DietEntryBloc bloc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(label: 'ÖĞÜNLER', accent: AppColors.primary),
        const SizedBox(height: AppSpacing.md),
        if (state.log!.plannedMeals.isEmpty && state.log!.extraEntries.isEmpty) _buildEmptyState(),
        ...state.log!.plannedMeals.map((meal) {
          final extras = state.log!.extraEntries.where((e) => e.mealType == meal.mealType).toList();
          return _buildPlannedMealCard(context, state, bloc, meal, extras);
        }),
      ],
    );
  }

  Widget _buildPlannedMealCard(BuildContext context, DietEntryState state, DietEntryBloc bloc, PlannedMealModel meal, List<dynamic> extras) {
    final selected = state.localSelections[meal.mealId] ?? {};
    final isAllSelected = selected.length == meal.plannedIngredients.length && meal.plannedIngredients.isNotEmpty;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              _getMealIcon(meal.mealType),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.mealType.trName.toUpperCase(),
                      style: AppTextStyles.listTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${meal.plannedIngredients.length} besin planlandı',
                      style: AppTextStyles.cardCaption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isAllSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isAllSelected ? AppColors.primary : AppColors.textMuted,
                ),
                onPressed: () => bloc.add(ToggleAllMeal(meal)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...meal.plannedIngredients.map((ing) {
            final isIngSelected = selected.contains(ing.id);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Checkbox(
                value: isIngSelected,
                activeColor: AppColors.primary,
                onChanged: (_) => bloc.add(ToggleIngredient(meal.mealId, ing.id!)),
              ),
              title: Text(
                ing.foodName,
                style: AppTextStyles.bodyText.copyWith(
                  color: isIngSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${ing.amount.toInt()}g • ${ing.calories.toInt()} kcal',
                style: AppTextStyles.cardCaption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Text(
          'Bu gün için kayıt yok',
          style: AppTextStyles.bodyText.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Text(
          'Hata: $message',
          style: AppTextStyles.bodyText.copyWith(
            color: AppColors.error,
          ),
        ),
      ),
    );
  }

  Widget _getMealIcon(MealType type) {
    IconData icon;
    switch (type) {
      case MealType.kahvalti:
        icon = Icons.wb_twilight_rounded;
        break;
      case MealType.ogleYemegi:
        icon = Icons.wb_sunny_rounded;
        break;
      case MealType.aksamYemegi:
        icon = Icons.nights_stay_rounded;
        break;
      default:
        icon = Icons.restaurant_rounded;
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

