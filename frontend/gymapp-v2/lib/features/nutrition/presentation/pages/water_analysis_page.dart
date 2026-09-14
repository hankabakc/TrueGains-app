import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/water_analysis/water_analysis_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/water_analysis/water_analysis_state.dart';
import '../bloc/water/water_bloc.dart';
import '../../data/models/water_intake_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';

class WaterAnalysisPage extends StatelessWidget {
  final WaterLoaded state;
  const WaterAnalysisPage({super.key, required this.state});

  void _confirmDeleteIntake(BuildContext context, int id, int amountMl) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Text(
          'Su Kaydını Sil',
          style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '$amountMl ml su kaydı kalıcı olarak silinecek.',
          style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'İPTAL',
              style: AppTextStyles.buttonText.copyWith(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<WaterBloc>().add(DeleteWaterIntake(id));
            },
            child: Text(
              'SİL',
              style: AppTextStyles.buttonText.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<WaterAnalysisCubit>(),
      child: BlocBuilder<WaterAnalysisCubit, WaterAnalysisState>(
        builder: (context, analysisState) {
          return BlocBuilder<WaterBloc, WaterState>(
            builder: (context, waterState) {
              final displayState = waterState is WaterLoaded ? waterState : state;
              final cubit = context.read<WaterAnalysisCubit>();

              return Scaffold(
                backgroundColor: AppColors.background,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    'ANALİZ VE GEÇMİŞ',
                    style: AppTextStyles.greeting.copyWith(color: AppColors.textPrimary, fontSize: 16, letterSpacing: 2),
                  ),
                  centerTitle: true,
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SectionHeader(label: 'GELİŞİM GRAFİĞİ'),
                          _buildSmallToggle(cubit, analysisState),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildSharpChart(context, displayState.history, analysisState.isWeeklyView),
                      const SizedBox(height: AppSpacing.xl),
                      SectionHeader(
                        label: analysisState.isWeeklyView ? 'BU HAFTA (PZT - PAZ)' : 'BU AYIN ÖZETİ',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      analysisState.isWeeklyView ? _buildWeeklyTable(displayState.history) : _buildMonthlyTable(displayState.history),
                      const SizedBox(height: AppSpacing.xl),
                      const SectionHeader(label: 'BUGÜNKÜ KAYITLAR'),
                      const SizedBox(height: AppSpacing.md),
                      _buildHourlyLogsList(context, displayState.summary.intakes, analysisState),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSmallToggle(WaterAnalysisCubit cubit, WaterAnalysisState state) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          _buildSmallToggleButton('HAFTA', state.isWeeklyView, () => cubit.setWeeklyView(true)),
          _buildSmallToggleButton('AY', !state.isWeeklyView, () => cubit.setWeeklyView(false)),
        ],
      ),
    );
  }

  Widget _buildSmallToggleButton(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: isActive ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          child: Center(
            child: Text(
              title,
              style: AppTextStyles.tagText.copyWith(
                color: isActive ? AppColors.background : AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSharpChart(BuildContext context, List<WaterDailyTotalModel> history, bool isWeeklyView) {
    final now = DateTime.now();
    final List<DateTime> displayDays;

    if (isWeeklyView) {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      displayDays = List.generate(7, (index) => DateTime(monday.year, monday.month, monday.day).add(Duration(days: index)));
    } else {
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);
      displayDays = List.generate(lastDay.day, (index) => firstDay.add(Duration(days: index)));
    }

    final Map<String, WaterDailyTotalModel> historyMap = {for (var item in history) '${item.date.year}-${item.date.month}-${item.date.day}': item};

    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(16, 32, 24, 16),
      borderRadius: AppRadius.xl,
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: isWeeklyView ? 1 : 5,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= displayDays.length) return const SizedBox();
                    if (isWeeklyView) {
                      const days = ['Pt', 'Sa', 'Çr', 'Pr', 'Cu', 'Ct', 'Pz'];
                      return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(days[index], style: TextStyle(color: AppColors.textMuted, fontSize: 10)));
                    } else {
                      final day = displayDays[index].day;
                      if (day % 5 != 0 && day != 1 && day != displayDays.length) return const SizedBox();
                      return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('$day', style: TextStyle(color: AppColors.textMuted, fontSize: 10)));
                    }
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value % 1000 != 0) return const SizedBox();
                    return Text('${(value / 1000).toInt()}k', style: TextStyle(color: AppColors.textMuted, fontSize: 10));
                  },
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(displayDays.length, (index) {
                  final date = displayDays[index];
                  final key = '${date.year}-${date.month}-${date.day}';
                  final data = historyMap[key];
                  return FlSpot(index.toDouble(), (data?.targetMl ?? 3000).toDouble());
                }),
                isCurved: false,
                color: AppColors.glassBorder,
                barWidth: 1,
                dotData: const FlDotData(show: false),
                dashArray: [5, 5],
              ),
              LineChartBarData(
                spots: List.generate(displayDays.length, (index) {
                  final date = displayDays[index];
                  final key = '${date.year}-${date.month}-${date.day}';
                  final data = historyMap[key];
                  return FlSpot(index.toDouble(), (data?.totalIntakeMl ?? 0).toDouble());
                }),
                isCurved: false,
                color: AppColors.primary,
                barWidth: 3,
                dotData: FlDotData(
                  show: isWeeklyView,
                  getDotPainter: (spot, xPercentage, bar, index) => FlDotCirclePainter(radius: 3, color: AppColors.primary, strokeWidth: 1, strokeColor: AppColors.textPrimary),
                ),
                belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.3), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyTable(List<WaterDailyTotalModel> history) {
    final now = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (index) => monday.add(Duration(days: index)));
    final Map<String, WaterDailyTotalModel> historyMap = {for (var item in history) '${item.date.year}-${item.date.month}-${item.date.day}': item};

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: AppRadius.xl,
      child: Column(
        children: weekDays.map((date) {
          final key = '${date.year}-${date.month}-${date.day}';
          final item = historyMap[key];
          final intake = item?.totalIntakeMl ?? 0;
          final target = item?.targetMl ?? 3000;
          final isSuccess = intake >= target && intake > 0;
          final isToday = date.isAtSameMomentAs(now);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getWeekdayName(date.weekday),
                  style: AppTextStyles.bodyText.copyWith(
                    color: isToday ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  intake > 0 ? '$intake / $target ml' : '- / $target ml',
                  style: AppTextStyles.bodyText.copyWith(
                    color: isSuccess ? AppColors.success : AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyTable(List<WaterDailyTotalModel> history) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = List.generate(lastDayOfMonth.day, (index) => firstDayOfMonth.add(Duration(days: index)));
    final Map<String, WaterDailyTotalModel> historyMap = {for (var item in history) '${item.date.year}-${item.date.month}-${item.date.day}': item};

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: AppRadius.xl,
      child: Column(
        children: daysInMonth.map((date) {
          final key = '${date.year}-${date.month}-${date.day}';
          final item = historyMap[key];
          final intake = item?.totalIntakeMl ?? 0;
          final target = item?.targetMl ?? 3000;
          final isSuccess = intake >= target && intake > 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${date.day} ${_getMonthName(date.month)}',
                  style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary, fontSize: 12),
                ),
                Text(
                  intake > 0 ? '$intake ml' : '-',
                  style: AppTextStyles.bodyText.copyWith(
                    color: isSuccess ? AppColors.success : (intake > 0 ? AppColors.textSecondary : AppColors.textMuted),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHourlyLogsList(BuildContext context, List<WaterIntakeModel> intakes, WaterAnalysisState state) {
    if (intakes.isEmpty) {
      return Center(
        child: Text(
          'Bugün henüz su girişi yapılmadı.',
          style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 12),
        ),
      );
    }

    final sorted = List<WaterIntakeModel>.from(intakes)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayList = state.isLogsExpanded ? sorted : sorted.take(3).toList();
    final cubit = context.read<WaterAnalysisCubit>();

    return Column(
      children: [
        ...displayList.map((log) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')}',
                    style: AppTextStyles.cardCaption.copyWith(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  Text(
                    '${log.amountMl} ml',
                    style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary, fontSize: 13),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                    onPressed: () => _confirmDeleteIntake(context, log.id, log.amountMl),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            )),
        if (sorted.length > 3)
          TextButton(
            onPressed: () => cubit.toggleLogsExpanded(),
            child: Text(
              state.isLogsExpanded ? 'DAHA AZ GÖR' : 'TÜMÜNÜ GÖR (${sorted.length})',
              style: AppTextStyles.buttonText.copyWith(color: AppColors.primary, fontSize: 11),
            ),
          ),
      ],
    );
  }

  String _getWeekdayName(int day) {
    const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    return days[day - 1];
  }

  String _getMonthName(int month) {
    const months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return months[month - 1];
  }
}
