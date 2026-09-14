import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'skeleton_pulse.dart';

class ListSkeleton extends StatelessWidget {
  final int rowCount;
  final double rowHeight;
  const ListSkeleton({super.key, this.rowCount = 5, this.rowHeight = 72});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rowCount,
        itemBuilder: (context, index) => Container(
          key: ValueKey('list_skeleton_row_$index'),
          height: rowHeight,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}
