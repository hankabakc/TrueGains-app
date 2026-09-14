import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gymapp_v2/core/constants/app_strings.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/measurement/measurement_bloc.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/measurement/measurement_state.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/measurement/measurement_event.dart';
import 'package:gymapp_v2/features/measurement/models/measurement.dart';

class ChartLineData {
  final String label;
  final Color color;
  final List<FlSpot> spots;

  ChartLineData({
    required this.label,
    required this.color,
    required this.spots,
  });
}

class ProgressChartsPage extends StatelessWidget {
  final int? targetClientId;

  const ProgressChartsPage({super.key, this.targetClientId});

  @override
  Widget build(BuildContext context) {
    return ProgressChartsView(targetClientId: targetClientId);
  }
}

class ProgressChartsView extends StatefulWidget {
  final int? targetClientId;
  const ProgressChartsView({super.key, this.targetClientId});

  @override
  State<ProgressChartsView> createState() => _ProgressChartsViewState();
}

class _ProgressChartsViewState extends State<ProgressChartsView> {
  String _selectedCategory = 'Kompozisyon'; // 'Kompozisyon' veya 'Çevre Ölçüleri' veya 'Tümü'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.progressCharts,
          style: AppTextStyles.pageTitle,
        ),
      ),
      body: BlocBuilder<MeasurementBloc, MeasurementState>(
        builder: (context, state) {
          if (state is MeasurementLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is MeasurementLoaded) {
            if (state.measurements.length < 2) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.show_chart_rounded,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      AppStrings.minTwoMeasurements,
                      style: AppTextStyles.bodyText.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            // earliest to latest for left-to-right drawing
            final sorted = state.measurements.reversed.toList();

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    _buildCategoryFilter(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        physics: const BouncingScrollPhysics(),
                        children: _buildFilteredCharts(sorted),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is MeasurementError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Text(state.message, style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: () {
                      context.read<MeasurementBloc>().add(LoadMeasurements(clientId: widget.targetClientId));
                    },
                    child: const Text(AppStrings.tryAgain),
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFilterChip('Kompozisyon'),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip('Çevre Ölçüleri'),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip('Tümü'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String category) {
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (v) {
        if (v) {
          setState(() {
            _selectedCategory = category;
          });
        }
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      backgroundColor: AppColors.glassWhite,
      labelStyle: AppTextStyles.tagText.copyWith(
        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: BorderSide(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.5) : AppColors.glassBorder,
        ),
      ),
      showCheckmark: false,
    );
  }

  List<Widget> _buildFilteredCharts(List<Measurement> sorted) {
    final charts = <Widget>[];

    final isComp = _selectedCategory == 'Kompozisyon' || _selectedCategory == 'Tümü';
    final isCircum = _selectedCategory == 'Çevre Ölçüleri' || _selectedCategory == 'Tümü';

    if (isComp) {
      charts.addAll([
        _buildChartCard(
          title: AppStrings.weightChange,
          unit: 'kg',
          sorted: sorted,
          lines: [
            ChartLineData(
              label: AppStrings.weight,
              color: AppColors.measurementChart[0],
              spots: _buildSpots(sorted, (m) => m.weight),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildChartCard(
          title: AppStrings.heightChange,
          unit: 'cm',
          sorted: sorted,
          lines: [
            ChartLineData(
              label: AppStrings.heightLabel,
              color: AppColors.measurementChart[4],
              spots: _buildSpots(sorted, (m) => m.height),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildChartCard(
          title: AppStrings.bodyFatPct,
          unit: '%',
          sorted: sorted,
          lines: [
            ChartLineData(
              label: AppStrings.bodyFatLabel,
              color: AppColors.measurementChart[2],
              spots: _buildSpots(sorted, (m) => m.bodyFatPct),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildChartCard(
          title: AppStrings.muscleMassChange,
          unit: 'kg',
          sorted: sorted,
          lines: [
            ChartLineData(
              label: AppStrings.muscleMassLabel,
              color: AppColors.measurementChart[6],
              spots: _buildSpots(sorted, (m) => m.muscleMass),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
      ]);
    }

    if (isCircum) {
      charts.addAll([
        _buildChartCard(
          title: AppStrings.waistCircumference,
          unit: 'cm',
          sorted: sorted,
          lines: [
            ChartLineData(
              label: AppStrings.waist,
              color: AppColors.measurementChart[3],
              spots: _buildSpots(sorted, (m) => m.waist),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildChartCard(
          title: AppStrings.chestCircumference,
          unit: 'cm',
          sorted: sorted,
          lines: [
            ChartLineData(
              label: AppStrings.chest,
              color: AppColors.measurementChart[1],
              spots: _buildSpots(sorted, (m) => m.chest),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildChartCard(
          title: AppStrings.shouldersCircumference,
          unit: 'cm',
          sorted: sorted,
          lines: [
            ChartLineData(
              label: AppStrings.shoulders,
              color: AppColors.measurementChart[4],
              spots: _buildSpots(sorted, (m) => m.shoulders),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildChartCard(
          title: AppStrings.armCircumference,
          unit: 'cm',
          sorted: sorted,
          lines: [
            ChartLineData(
              label: AppStrings.leftArm,
              color: AppColors.measurementChart[0],
              spots: _buildSpots(sorted, (m) => m.leftArm),
            ),
            ChartLineData(
              label: AppStrings.rightArm,
              color: AppColors.measurementChart[6],
              spots: _buildSpots(sorted, (m) => m.rightArm),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildChartCard(
          title: AppStrings.legCircumference,
          unit: 'cm',
          sorted: sorted,
          lines: [
            ChartLineData(
              label: AppStrings.leftLeg,
              color: AppColors.measurementChart[5],
              spots: _buildSpots(sorted, (m) => m.leftLeg),
            ),
            ChartLineData(
              label: AppStrings.rightLeg,
              color: AppColors.measurementChart[9],
              spots: _buildSpots(sorted, (m) => m.rightLeg),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildChartCard(
          title: AppStrings.hipsCircumference,
          unit: 'cm',
          sorted: sorted,
          lines: [
            ChartLineData(
              label: AppStrings.hips,
              color: AppColors.measurementChart[8],
              spots: _buildSpots(sorted, (m) => m.hips),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
      ]);
    }

    if (charts.isNotEmpty) {
      charts.removeLast();
      charts.add(const SizedBox(height: AppLayout.bottomNavClearance));
    }

    return charts;
  }

  List<FlSpot> _buildSpots(List<Measurement> sorted, double? Function(Measurement) extractor) {
    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      final value = extractor(sorted[i]);
      if (value != null) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }
    return spots;
  }

  Widget _buildChartCard({
    required String title,
    required List<ChartLineData> lines,
    required String unit,
    required List<Measurement> sorted,
  }) {
    final allSpots = lines.expand((l) => l.spots).toList();
    if (allSpots.length < 2) return const SizedBox.shrink();

    final yValues = allSpots.map((s) => s.y).toList();
    final minY = yValues.reduce((a, b) => a < b ? a : b);
    final maxY = yValues.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.2;

    // A özeti: Güncel değer + toplam değişim hesaplama
    String summaryText = '';
    if (lines.first.spots.length >= 2) {
      final latestSpot = lines.first.spots.last;
      final earliestSpot = lines.first.spots.first;
      final diff = latestSpot.y - earliestSpot.y;
      final diffStr = diff == 0 ? '' : ' · ${diff > 0 ? "▲" : "▼"}${diff.abs().toStringAsFixed(1)}';
      summaryText = ' · ${latestSpot.y.toStringAsFixed(1)} $unit$diffStr';
    }

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.lg,
      shadow: AppElevation.softGlow(lines.first.color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$title$summaryText',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.listTitle.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Row(
                children: [
                  if (lines.length > 1) ...[
                    ...lines.map((line) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: line.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(
                                line.label,
                                style: AppTextStyles.tagText.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: lines.first.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      unit,
                      style: AppTextStyles.tagText.copyWith(
                        color: lines.first.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine:
                      (v) => FlLine(
                        color: AppColors.glassWhite,
                        strokeWidth: 1,
                      ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        int idx = v.toInt();
                        if (idx >= 0 && idx < sorted.length) {
                          final date = sorted[idx].createdAt;
                          if (date != null) {
                            return Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.xs),
                              child: Text(
                                '${date.day}/${date.month}',
                                style: AppTextStyles.cardCaption.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 9,
                                ),
                              ),
                            );
                          }
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget:
                          (v, m) => Text(
                            v.toInt().toString(),
                            style: AppTextStyles.cardCaption.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 9,
                            ),
                          ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: lines.map((line) {
                  return LineChartBarData(
                    spots: line.spots,
                    isCurved: true,
                    color: line.color,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter:
                          (s, p, b, i) => FlDotCirclePainter(
                            radius: 4,
                            color: line.color,
                            strokeWidth: 2,
                            strokeColor: AppColors.background,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          line.color.withValues(alpha: 0.3),
                          line.color.withValues(alpha: 0.01),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                minY: (minY - padding).clamp(0, double.infinity),
                maxY: maxY + padding,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
