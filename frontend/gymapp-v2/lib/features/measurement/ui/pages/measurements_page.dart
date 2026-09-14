import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/constants/app_strings.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/measurement/measurement_bloc.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/measurement/measurement_event.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/measurement/measurement_state.dart';
import 'package:gymapp_v2/features/measurement/models/measurement.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/pressable_scale.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:gymapp_v2/core/widgets/list_skeleton.dart';
import 'add_measurement_page.dart';
import 'progress_charts_page.dart';

class MeasurementsPage extends StatelessWidget {
  final int? targetClientId;
  const MeasurementsPage({super.key, this.targetClientId});

  @override
  Widget build(BuildContext context) {
    return MeasurementsView(targetClientId: targetClientId);
  }
}

class MeasurementsView extends StatefulWidget {
  final int? targetClientId;
  const MeasurementsView({super.key, this.targetClientId});

  @override
  State<MeasurementsView> createState() => _MeasurementsViewState();
}

class _MeasurementsViewState extends State<MeasurementsView> {
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
          AppStrings.bodyMeasurements,
          style: AppTextStyles.pageTitle,
        ),
        actions: [
          if (widget.targetClientId == null) ...[
            BlocBuilder<MeasurementBloc, MeasurementState>(
              builder: (context, state) {
                if (state is MeasurementLoaded && state.measurements.isNotEmpty) {
                  return IconButton(
                    icon: Icon(
                      state.isSelectionMode
                          ? Icons.close_rounded
                          : Icons.share_rounded,
                      color: AppColors.primary,
                    ),
                    onPressed:
                        () => context.read<MeasurementBloc>().add(
                          ToggleSelectionMode(),
                        ),
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ],
      ),
      body: BlocListener<MeasurementBloc, MeasurementState>(
        listener: (context, state) {
          if (state is MeasurementLoaded) {
            if (state.shareSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(AppStrings.shareSuccess),
                  backgroundColor: AppColors.success,
                ),
              );
            } else if (state.shareError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.shareError!),
                  backgroundColor: AppColors.error,
                ),
              );
            } else if (state.deleteError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.deleteError!),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
        child: BlocBuilder<MeasurementBloc, MeasurementState>(
          builder: (context, state) {
            if (state is MeasurementLoading) {
              return const ListSkeleton();
            } else if (state is MeasurementError) {
              return _buildErrorState(state.message);
            } else if (state is MeasurementLoaded) {
              if (state.measurements.isEmpty) {
                return _buildEmptyState();
              }
              return _buildContent(state);
            }
            return const SizedBox();
          },
        ),
      ),
      floatingActionButton: widget.targetClientId == null
          ? FloatingActionButton.extended(
            onPressed:
                () => Navigator.push<bool>(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (_) => const AddMeasurementPage(),
                  ),
                ).then(
                  (v) =>
                      v == true && context.mounted
                          ? context.read<MeasurementBloc>().add(
                            LoadMeasurements(clientId: widget.targetClientId),
                          )
                          : null,
                ),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add_rounded, color: AppColors.background),
            label: Text(
              AppStrings.newMeasurement,
              style: AppTextStyles.buttonText.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.background,
              ),
            ),
          )
          : null,
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            error,
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed:
                () => context.read<MeasurementBloc>().add(
                  LoadMeasurements(clientId: widget.targetClientId),
                ),
            child: const Text(AppStrings.tryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.straighten_rounded,
            size: 80,
            color: AppColors.textMuted.withValues(alpha: 0.2),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppStrings.noMeasurementRecords,
            style: AppTextStyles.emptyTitle.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.firstMeasurementPrompt,
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(MeasurementLoaded state) {
    final latest = state.measurements.first;
    Measurement? prev;
    if (state.measurements.length >= 2) {
      prev = state.measurements[1];
    }

    return RefreshIndicator(
      onRefresh:
          () async => context.read<MeasurementBloc>().add(
            LoadMeasurements(clientId: widget.targetClientId),
          ),
      color: AppColors.primary,
      backgroundColor: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: state.measurements.length + 4, // SelectionBar, SummaryRow, CTA, SectionHeader, and list of items
            itemBuilder: (context, index) {
              if (index == 0) {
                if (state.isSelectionMode) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${state.selectedIds.length} ${AppStrings.selected}',
                          style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary),
                        ),
                        TextButton.icon(
                          onPressed:
                              state.selectedIds.isEmpty
                                  ? null
                                  : () => context.read<MeasurementBloc>().add(
                                    ShareSelectedMeasurements(),
                                  ),
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: const Text(AppStrings.share),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }
              
              if (index == 1) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        AppStrings.weightTitle,
                        '${latest.weight?.toStringAsFixed(1) ?? "--"} kg',
                        Icons.monitor_weight_rounded,
                        AppColors.measurementChart[0],
                        latest.weight,
                        prev?.weight,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildSummaryCard(
                        AppStrings.fatPctTitle,
                        latest.bodyFatPct != null
                            ? '%${latest.bodyFatPct!.toStringAsFixed(1)}'
                            : '--',
                        Icons.percent_rounded,
                        AppColors.measurementChart[2],
                        latest.bodyFatPct,
                        prev?.bodyFatPct,
                      ),
                    ),
                  ],
                );
              }

              if (index == 2) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xl),
                  child: PressableScale(
                    onTap:
                        () => Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder:
                                (_) => BlocProvider.value(
                                  value: context.read<MeasurementBloc>(),
                                  child: ProgressChartsPage(
                                    targetClientId: widget.targetClientId,
                                  ),
                                ),
                          ),
                        ),
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      borderRadius: AppRadius.md,
                      shadow: AppElevation.softGlow(AppColors.primary),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Icon(
                              Icons.auto_graph_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            AppStrings.viewProgressCharts,
                            style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.textMuted,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (index == 3) {
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      label: AppStrings.pastMeasurements,
                      icon: Icons.history_rounded,
                    ),
                    SizedBox(height: AppSpacing.md),
                  ],
                );
              }

              final mIndex = index - 4;
              final m = state.measurements[mIndex];
              Measurement? itemPrev;
              if (mIndex + 1 < state.measurements.length) {
                itemPrev = state.measurements[mIndex + 1];
              }
              return _buildMeasurementCard(m, itemPrev, state);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
    double? current,
    double? previous,
  ) {
    Widget? deltaWidget;
    if (current != null && previous != null) {
      final delta = current - previous;
      if (delta != 0) {
        final isPositive = delta > 0;
        final deltaColor = AppColors.textSecondary;
        final iconData = isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
        deltaWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, color: deltaColor, size: 12),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              '${isPositive ? "+" : ""}${delta.toStringAsFixed(1)}',
              style: AppTextStyles.tagText.copyWith(
                color: deltaColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        );
      }
    }

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.lg,
      shadow: AppElevation.softGlow(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              if (deltaWidget != null) deltaWidget,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: AppTextStyles.cardCaption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: AppTextStyles.cardValue.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard(Measurement m, Measurement? prev, MeasurementLoaded state) {
    final date = m.createdAt ?? DateTime.now();
    final dateStr = '${date.day}.${date.month}.${date.year}';
    final isSelected = state.selectedIds.contains(m.id);

    return Dismissible(
      key: Key('m_${m.id}'),
      direction:
          state.isSelectionMode
              ? DismissDirection.none
              : DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      onDismissed:
          (_) => context.read<MeasurementBloc>().add(DeleteMeasurement(m.id!)),
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.zero,
        borderRadius: AppRadius.lg,
        shadow: AppElevation.softGlow(isSelected ? AppColors.primary : AppColors.glassBorder),
        border: isSelected
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
            : Border.all(color: AppColors.glassBorder),
        child: Column(
          children: [
            InkWell(
              onTap:
                  state.isSelectionMode
                      ? () => context.read<MeasurementBloc>().add(
                        ToggleMeasurementSelection(m.id!),
                      )
                      : null,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.glassWhite,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppRadius.lg),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (state.isSelectionMode) ...[
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 18,
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                          ),
                          const SizedBox(width: AppSpacing.md),
                        ] else
                          const Icon(
                            Icons.event_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          dateStr,
                          style: AppTextStyles.listTitle.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        if (m.isSharedWithCoach && widget.targetClientId == null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                  color: AppColors.success.withValues(alpha: 0.5),
                                  width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded,
                                    size: 10, color: AppColors.success),
                                const SizedBox(width: AppSpacing.xxs),
                                Text(
                                  AppStrings.shared,
                                  style: AppTextStyles.tagText.copyWith(
                                      color: AppColors.success,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (m.notes != null && m.notes!.isNotEmpty)
                          Icon(
                            Icons.sticky_note_2_rounded,
                            size: 16,
                            color: AppColors.primary.withValues(alpha: 0.6),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        _metricRow(
                          Icons.monitor_weight_rounded,
                          AppStrings.weight,
                          '${m.weight?.toStringAsFixed(1) ?? "--"} kg',
                          Icons.height_rounded,
                          AppStrings.heightLabel,
                          '${m.height?.toStringAsFixed(1) ?? "--"} cm',
                          m.weight,
                          prev?.weight,
                          null,
                          null,
                          AppColors.measurementChart[0],
                          AppColors.measurementChart[4],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _metricRow(
                          Icons.percent_rounded,
                          AppStrings.bodyFatLabel,
                          m.bodyFatPct != null ? '%${m.bodyFatPct!.toStringAsFixed(1)}' : '--',
                          Icons.fitness_center_rounded,
                          AppStrings.muscleMassLabel,
                          '${m.muscleMass?.toStringAsFixed(1) ?? "--"} kg',
                          m.bodyFatPct,
                          prev?.bodyFatPct,
                          m.muscleMass,
                          prev?.muscleMass,
                          AppColors.measurementChart[2],
                          AppColors.measurementChart[6],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _metricRow(
                          Icons.accessibility_new_rounded,
                          AppStrings.shoulders,
                          '${m.shoulders?.toStringAsFixed(1) ?? "--"} cm',
                          Icons.straighten_rounded,
                          AppStrings.waist,
                          '${m.waist?.toStringAsFixed(1) ?? "--"} cm',
                          m.shoulders,
                          prev?.shoulders,
                          m.waist,
                          prev?.waist,
                          AppColors.measurementChart[4],
                          AppColors.measurementChart[3],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _metricRow(
                          Icons.fitness_center_rounded,
                          AppStrings.arms,
                          '${m.leftArm?.toStringAsFixed(0) ?? "0"}/${m.rightArm?.toStringAsFixed(0) ?? "0"} cm',
                          Icons.directions_run_rounded,
                          AppStrings.legs,
                          '${m.leftLeg?.toStringAsFixed(0) ?? "0"}/${m.rightLeg?.toStringAsFixed(0) ?? "0"} cm',
                          null,
                          null,
                          null,
                          null,
                          AppColors.measurementChart[0],
                          AppColors.measurementChart[5],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(
    IconData icon1,
    String l1,
    String v1,
    IconData icon2,
    String l2,
    String v2,
    double? cur1,
    double? prev1,
    double? cur2,
    double? prev2,
    Color color1,
    Color color2,
  ) {
    return Row(
      children: [
        Expanded(child: _miniMetric(icon1, l1, v1, cur1, prev1, color1)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _miniMetric(icon2, l2, v2, cur2, prev2, color2)),
      ],
    );
  }

  Widget _miniMetric(IconData icon, String label, String value, double? current, double? previous, Color color) {
    Widget? deltaWidget;
    if (current != null && previous != null) {
      final delta = current - previous;
      if (delta != 0) {
        final isPositive = delta > 0;
        final deltaColor = AppColors.textSecondary;
        final iconData = isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
        deltaWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, color: deltaColor, size: 10),
            Text(
              delta.toStringAsFixed(1),
              style: AppTextStyles.tagText.copyWith(
                color: deltaColor,
                fontWeight: FontWeight.bold,
                fontSize: 8,
              ),
            ),
          ],
        );
      }
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: AppTextStyles.cardCaption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (deltaWidget != null) ...[
                    const SizedBox(width: 4),
                    deltaWidget,
                  ],
                ],
              ),
              Text(
                value,
                style: AppTextStyles.listTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
