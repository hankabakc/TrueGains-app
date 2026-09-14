import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';

class ProgressLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final List<String> xLabels;
  final double minY;
  final double maxY;
  final String yUnit;
  final Color lineColor;

  const ProgressLineChart({
    super.key,
    required this.spots,
    required this.xLabels,
    this.minY = 0,
    required this.maxY,
    this.yUnit = 'kg',
    this.lineColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return const Center(
        child: Text(
          'Veri bulunamadı',
          style: TextStyle(color: Colors.white24),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY * 1.1, // Biraz üst boşluk
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: Colors.white10,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= xLabels.length) {
                  return const SizedBox();
                }
                // Sadece baş, orta ve son etiketleri göster (veya belli aralıklarla)
                if (xLabels.length > 5 && index % (xLabels.length ~/ 3) != 0 && index != xLabels.length - 1) {
                   return const SizedBox();
                }

                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    xLabels[index],
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY > 50 ? 20 : 10,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '${value.toInt()} $yUnit',
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  lineColor.withValues(alpha: 0.3),
                  lineColor.withValues(alpha: 0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => AppColors.surface.withValues(alpha: 0.8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                return LineTooltipItem(
                  '${touchedSpot.y.toStringAsFixed(1)} $yUnit\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: xLabels[touchedSpot.x.toInt()],
                      style: const TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.normal,
                        fontSize: 10,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
