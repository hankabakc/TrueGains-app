import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/features/measurement/models/client_measurements_summary.dart';
import 'package:gymapp_v2/features/measurement/models/shared_measurement.dart';
import 'package:gymapp_v2/features/measurement/ui/pages/progress_charts_page.dart';
import 'package:gymapp_v2/features/measurement/ui/pages/measurements_page.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/measurement/measurement_bloc.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/measurement/measurement_event.dart';
import 'package:gymapp_v2/core/constants/app_strings.dart';

class CoachClientProgressPage extends StatelessWidget {
  final ClientMeasurementsSummary summary;

  const CoachClientProgressPage({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.clientName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const Text(
              'Gelişim Detayları',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: AppColors.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider<MeasurementBloc>(
                  create: (context) => sl<MeasurementBloc>()
                    ..add(LoadMeasurements(clientId: summary.clientId)),
                  child: ProgressChartsPage(targetClientId: summary.clientId),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 32),
            const Text(
              'Paylaşılan Ölçümler',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...summary.measurements.map((m) => _buildMeasurementCard(context, m)),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider<MeasurementBloc>(
                  create: (context) => sl<MeasurementBloc>()
                    ..add(LoadMeasurements(clientId: summary.clientId)),
                  child: MeasurementsPage(targetClientId: summary.clientId),
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: const Text(
              'Tüm Geçmişi Görüntüle',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (summary.measurements.isEmpty) return const SizedBox();
    final latest = summary.measurements.first;

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem('Son Kilo', '${latest.weight ?? "--"} kg'),
              _summaryItem('Yağ %', '${latest.bodyFatPct ?? "--"}%'),
              _summaryItem('Ölçüm', '${summary.measurements.length} Adet'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementCard(BuildContext context, SharedMeasurement m) {
    final dateStr = '${m.measurementDate.day}.${m.measurementDate.month}.${m.measurementDate.year}';

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.event_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _metricCol(AppStrings.weight, '${m.weight ?? "--"}'),
                _metricCol(AppStrings.heightLabel, '${m.height ?? "--"}'),
                _metricCol(AppStrings.bodyFatLabel, '${m.bodyFatPct ?? "--"}'),
                _metricCol(AppStrings.muscleMassLabel, '${m.muscleMass ?? "--"}'),
              ],
            ),
            if (m.notes != null && m.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  m.notes!,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricCol(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
