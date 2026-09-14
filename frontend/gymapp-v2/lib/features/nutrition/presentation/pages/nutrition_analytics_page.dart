import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/nutrition_dashboard_model.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../bloc/nutrition_analytics/nutrition_analytics_bloc.dart';
import '../widgets/no_active_diet_program_view.dart';
import 'package:intl/intl.dart';

class NutritionAnalyticsPage extends StatelessWidget {
  final int? programId;
  final int? targetUserId;
  const NutritionAnalyticsPage({super.key, this.programId, this.targetUserId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NutritionAnalyticsBloc(GetIt.I<NutritionRepository>())
        ..add(FetchDashboardData(programId: programId, targetUserId: targetUserId)),
      child: NutritionAnalyticsView(programId: programId, targetUserId: targetUserId),
    );
  }
}

class NutritionAnalyticsView extends StatelessWidget {
  final int? programId;
  final int? targetUserId;
  const NutritionAnalyticsView({super.key, this.programId, this.targetUserId});

  @override
  Widget build(BuildContext context) {
    final isCoachView = targetUserId != null;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            isCoachView ? 'Sporcu Beslenme Analizi' : 'Analiz & Raporlar',
            style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: AppColors.textPrimary),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: AppTextStyles.buttonText.copyWith(fontSize: 11),
            unselectedLabelStyle: AppTextStyles.bodyText.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            isScrollable: false,
            tabs: const [
              Tab(icon: Icon(Icons.restaurant_menu_rounded, size: 18), text: 'Öğün'),
              Tab(icon: Icon(Icons.pie_chart_rounded, size: 18), text: 'Makro'),
              Tab(icon: Icon(Icons.analytics_rounded, size: 18), text: 'Analiz'),
            ],
          ),
        ),
        body: BlocBuilder<NutritionAnalyticsBloc, NutritionAnalyticsState>(
          builder: (context, state) {
            if (state is NutritionAnalyticsLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            } else if (state is NutritionAnalyticsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                    const SizedBox(height: AppSpacing.md),
                    Text(state.message, style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                      ),
                      onPressed: () => context.read<NutritionAnalyticsBloc>().add(FetchDashboardData(programId: programId, targetUserId: targetUserId)),
                      child: Text('Tekrar Dene', style: AppTextStyles.buttonText),
                    ),
                  ],
                ),
              );
            } else if (state is NutritionAnalyticsLoaded) {
              if (!state.dashboardData.hasActiveProgram) {
                return NoActiveDietProgramView(
                  isCoachView: isCoachView,
                  onSelectProgram: isCoachView ? null : () => context.push('/nutrition/list/client'),
                );
              }
              return TabBarView(
                children: [
                  _buildOgunTakibiTab(context, state),
                  _buildMakroTakibiTab(context, state),
                  _buildDetayliHedefTab(context, state),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildOgunTakibiTab(BuildContext context, NutritionAnalyticsLoaded state) {
    final daily = state.dashboardData.dailySummary;
    final weekly = state.dashboardData.weeklySummary;

    return RefreshIndicator(
      onRefresh: () async => context.read<NutritionAnalyticsBloc>().add(FetchDashboardData(programId: programId, targetUserId: targetUserId)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(label: 'HAFTALIK KALORİ GRAFİĞİ (X-Y)'),
            const SizedBox(height: AppSpacing.sm),
            _buildWeeklyXYChart(weekly),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(label: 'ÖĞÜN BAZLI DAĞILIM (GÜNLÜK)'),
            const SizedBox(height: AppSpacing.sm),
            _buildMealBreakdownList(daily.mealBreakdown),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(label: 'GÜNLÜK YENEN YEMEKLER'),
            const SizedBox(height: AppSpacing.sm),
            _buildDailyFoodsList(daily.dailyFoods),
            const SizedBox(height: AppLayout.bottomNavClearance),
          ],
        ),
      ),
    );
  }

  Widget _buildMakroTakibiTab(BuildContext context, NutritionAnalyticsLoaded state) {
    final daily = state.dashboardData.dailySummary;
    final weekly = state.dashboardData.weeklySummary;

    return RefreshIndicator(
      onRefresh: () async => context.read<NutritionAnalyticsBloc>().add(FetchDashboardData(programId: programId, targetUserId: targetUserId)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(label: 'MAKRO DAĞILIMI'),
            const SizedBox(height: AppSpacing.sm),
            _buildMacroCircularChart(daily, weekly),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(label: 'GÜNLÜK MAKRO HEDEFLERİ'),
            const SizedBox(height: AppSpacing.sm),
            _buildDailyNumericalView(daily, weekly),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(label: 'YEMEKLER VE MAKROLAR'),
            const SizedBox(height: AppSpacing.sm),
            _buildFoodMacroList(daily.dailyFoods),
            const SizedBox(height: AppLayout.bottomNavClearance),
          ],
        ),
      ),
    );
  }

  Widget _buildDetayliHedefTab(BuildContext context, NutritionAnalyticsLoaded state) {
    return RefreshIndicator(
      onRefresh: () async => context.read<NutritionAnalyticsBloc>().add(FetchDashboardData(programId: programId, targetUserId: targetUserId)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailedNutrientAnalysis(state.dashboardData.nutrientAnalysis),
            const SizedBox(height: AppLayout.bottomNavClearance),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyXYChart(WeeklySummaryModel weekly) {
    return GlassContainer(
      height: 220,
      padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1000),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= weekly.dailyLogs.length) return const SizedBox();
                  final date = DateTime.now().subtract(Duration(days: weekly.dailyLogs.length - 1 - value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(DateFormat('E').format(date).toUpperCase(), style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: TextStyle(color: AppColors.textMuted, fontSize: 8)),
                reservedSize: 28,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (weekly.dailyLogs.length - 1).toDouble(),
          minY: 0,
          maxY: (weekly.targetCalories * 1.5),
          lineBarsData: [
            // Target Line
            LineChartBarData(
              spots: List.generate(weekly.dailyLogs.length, (i) => FlSpot(i.toDouble(), weekly.targetCalories)),
              isCurved: false,
              color: AppColors.primary.withValues(alpha: 0.3),
              barWidth: 2,
              dashArray: [5, 5],
              dotData: const FlDotData(show: false),
            ),
            // Actual Data
            LineChartBarData(
              spots: List.generate(weekly.dailyLogs.length, (i) => FlSpot(i.toDouble(), weekly.dailyLogs[i].calories)),
              isCurved: true,
              color: AppColors.primary,
              barWidth: 6,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 6,
                  color: AppColors.textPrimary,
                  strokeWidth: 3,
                  strokeColor: AppColors.primary,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.4), AppColors.primary.withValues(alpha: 0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealBreakdownList(List<MealTypeBreakdownModel> breakdown) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMealTableRow('ÖĞÜN', 'KALORİ', '%', header: true),
          const Divider(color: AppColors.glassBorder, height: 24),
          if (breakdown.isEmpty)
            ...['Kahvaltı', 'Öğle Yemeği', 'Akşam Yemeği', 'Diğer'].map((label) =>
               _buildMealTableRow(label, '0 kcal', '%0', color: _getMealColor(label))
             )
          else
            ...breakdown.map((item) {
              return _buildMealTableRow(
                item.mealLabel,
                '${item.calories.toInt()} kcal',
                '%${item.percentage.toInt()}',
                color: _getMealColor(item.mealLabel),
              );
            }),
        ],
      ),
    );
  }

  Color _getMealColor(String label) {
    if (label.contains('Kahvaltı')) return AppColors.mealBreakfast;
    if (label.contains('Öğle')) return AppColors.mealLunch;
    if (label.contains('Akşam')) return AppColors.mealDinner;
    if (label.contains('Spor Öncesi')) return AppColors.mealPreWorkout;
    if (label.contains('Spor Sonrası')) return AppColors.mealPostWorkout;
    if (label.contains('Gece Öğünü')) return AppColors.mealOther;
    return AppColors.mealOther;
  }

  Widget _buildMealTableRow(String label, String calories, String percentage, {bool header = false, Color? color}) {
    final style = header 
        ? AppTextStyles.sectionLabel.copyWith(color: AppColors.primary)
        : AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary, fontSize: 18);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (!header) Container(width: 10, height: 10, decoration: BoxDecoration(color: color ?? AppColors.textMuted, shape: BoxShape.circle)),
                if (!header) const SizedBox(width: 10),
                Text(label, style: style),
              ],
            ),
          ),
          Expanded(flex: 1, child: Text(calories, textAlign: TextAlign.right, style: style.copyWith(color: header ? AppColors.primary : AppColors.textPrimary))),
          Expanded(flex: 1, child: Text(percentage, textAlign: TextAlign.right, style: style.copyWith(color: AppColors.primary))),
        ],
      ),
    );
  }

  Widget _buildDailyFoodsList(List<FoodFrequencyModel> foods) {
    if (foods.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.restaurant_rounded, color: AppColors.textMuted, size: 36),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Bugün henüz yemek girişi yok',
                style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    return GlassContainer(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: foods.length,
        separatorBuilder: (context, index) => const Divider(color: AppColors.glassBorder, height: 1),
        itemBuilder: (context, index) {
          final food = foods[index];
          return ListTile(
            title: Text(food.foodName, style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary, fontSize: 16)),
            trailing: Text('${food.totalCalories.toStringAsFixed(1)} kcal', style: AppTextStyles.listTitle.copyWith(color: AppColors.primary, fontSize: 16)),
          );
        },
      ),
    );
  }

  Widget _buildMacroCircularChart(DailySummaryModel daily, WeeklySummaryModel weekly) {
    final totalMacros = daily.protein + daily.carbs + daily.fat;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(value: daily.protein, color: AppColors.protein, radius: 20, showTitle: false),
                      PieChartSectionData(value: daily.carbs, color: AppColors.carbs, radius: 20, showTitle: false),
                      PieChartSectionData(value: daily.fat, color: AppColors.fat, radius: 20, showTitle: false),
                      if (totalMacros == 0) PieChartSectionData(value: 1, color: AppColors.glassBorder, radius: 20, showTitle: false),
                    ],
                    centerSpaceRadius: 60,
                    sectionsSpace: 4,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(daily.calories.toStringAsFixed(1), style: AppTextStyles.heroDisplay.copyWith(fontSize: 32, color: AppColors.textPrimary)),
                    Text('Kcal', style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.glassBorder),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Protein', daily.protein, AppColors.protein),
              _buildLegendItem('Karb.', daily.carbs, AppColors.carbs),
              _buildLegendItem('Yağ', daily.fat, AppColors.fat),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, double val, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        RichText(
          text: TextSpan(
            style: AppTextStyles.cardCaption.copyWith(color: AppColors.textSecondary),
            children: [
              TextSpan(text: '$label '),
              TextSpan(text: '${val.toInt()}g', style: AppTextStyles.listTitle.copyWith(fontSize: 12, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFoodMacroList(List<FoodFrequencyModel> foods) {
    if (foods.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.restaurant_rounded, color: AppColors.textMuted, size: 36),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Bugün henüz yemek girişi yok',
                style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    return GlassContainer(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: foods.length,
        separatorBuilder: (context, index) => const Divider(color: AppColors.glassBorder, height: 1),
        itemBuilder: (context, index) {
          final food = foods[index];
          return ListTile(
            title: Text(food.foodName, style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary, fontSize: 16)),
            subtitle: Text(
              'P: ${food.totalProtein.toStringAsFixed(1)}g • C: ${food.totalCarbs.toStringAsFixed(1)}g • F: ${food.totalFat.toStringAsFixed(1)}g',
              style: AppTextStyles.cardCaption.copyWith(color: AppColors.textSecondary, fontSize: 13),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMacroTableRow(String label, String target, String current, String remaining, {bool header = false, Color? dotColor, double? progress}) {
    final style = header 
        ? AppTextStyles.sectionLabel.copyWith(color: AppColors.primary)
        : AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary, fontSize: 18);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    if (dotColor != null) Container(width: 10, height: 10, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                    if (dotColor != null) const SizedBox(width: 10),
                    Text(label, style: style),
                  ],
                ),
              ),
              Expanded(child: Text(target, textAlign: TextAlign.center, style: style)),
              Expanded(child: Text(current, textAlign: TextAlign.center, style: style.copyWith(color: header ? AppColors.primary : AppColors.textPrimary))),
              Expanded(child: Text(remaining, textAlign: TextAlign.center, style: style.copyWith(
                  color: !header && remaining.startsWith('-') ? AppColors.error : (header ? AppColors.primary : AppColors.textMuted)
              ))),
            ],
          ),
          if (!header && progress != null && dotColor != null) ...[
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.glassWhite,
                valueColor: AlwaysStoppedAnimation<Color>(progress > 1.0 ? AppColors.error : dotColor),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDailyNumericalView(DailySummaryModel daily, WeeklySummaryModel weekly) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMacroTableRow('MAKRO', 'GÜN. HEDEF', 'ALINAN', '%', header: true),
          const Divider(color: AppColors.glassBorder, height: 24),
          _buildDailyRow('Kalori', weekly.targetCalories, daily.calories, dotColor: AppColors.primary),
          _buildDailyRow('Protein', weekly.targetProtein, daily.protein, dotColor: AppColors.protein),
          _buildDailyRow('Karb.', weekly.targetCarbs, daily.carbs, dotColor: AppColors.carbs),
          _buildDailyRow('Yağ', weekly.targetFat, daily.fat, dotColor: AppColors.fat),
        ],
      ),
    );
  }

  Widget _buildDailyRow(String label, double target, double current, {Color? dotColor}) {
    final percent = target > 0 ? (current / target * 100).toInt() : 0;
    final progress = target > 0 ? (current / target) : 0.0;
    return _buildMacroTableRow(
      label, 
      target.toStringAsFixed(1), 
      current.toStringAsFixed(1), 
      '$percent%', 
      dotColor: dotColor,
      progress: progress,
    );
  }

  Widget _buildNutrientAnalysisItem(NutrientAnalysisModel a) {
    final isNegative = a.difference < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  a.nutrientName,
                  style: AppTextStyles.listTitle.copyWith(fontSize: 15, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: (isNegative ? AppColors.error : AppColors.textMuted).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${a.difference >= 0 ? "+" : ""}${a.difference.toStringAsFixed(1)}${a.unit}',
                  style: AppTextStyles.tagText.copyWith(
                    color: isNegative ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (a.target > 0 ? (a.reached / a.target) : 0.0).clamp(0.0, 1.0),
              backgroundColor: AppColors.glassWhite,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hedef: ${a.target.toStringAsFixed(1)}${a.unit}',
                style: AppTextStyles.cardCaption.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                'Ulaşılan: ${a.reached.toStringAsFixed(1)}${a.unit}',
                style: AppTextStyles.cardCaption.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedNutrientAnalysis(List<NutrientAnalysisModel> analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(label: 'AYRINTILI BESİN ANALİZİ (HAFTALIK)'),
        const SizedBox(height: AppSpacing.sm),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (analysis.isEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.bar_chart_rounded, color: AppColors.textMuted, size: 36),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Analiz verisi yok',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ] else
                ...analysis.asMap().entries.map((entry) {
                  final index = entry.key;
                  final a = entry.value;
                  return Column(
                    children: [
                      _buildNutrientAnalysisItem(a),
                      if (index < analysis.length - 1)
                        const Divider(color: AppColors.glassBorder, height: AppSpacing.lg),
                    ],
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}
