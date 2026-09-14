import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'skeleton_pulse.dart';

const double _kSkeletonBubbleHeight = 56.0;
const double _kBubbleTailRadius = 4.0;

class ChatLoadingSkeleton extends StatelessWidget {
  final int bubbleCount;
  const ChatLoadingSkeleton({super.key, this.bubbleCount = 5});

  static const List<double> _widths = [0.65, 0.45, 0.75, 0.50, 0.60];
  static const List<Alignment> _alignments = [
    Alignment.centerRight,
    Alignment.centerLeft,
    Alignment.centerRight,
    Alignment.centerLeft,
    Alignment.centerRight,
  ];

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: bubbleCount,
        itemBuilder: (context, index) {
          final widthFactor = _widths[index % _widths.length];
          final alignment = _alignments[index % _alignments.length];
          final isRight = alignment == Alignment.centerRight;

          return Align(
            alignment: alignment,
            child: Container(
              width: MediaQuery.sizeOf(context).width * widthFactor,
              height: _kSkeletonBubbleHeight,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: isRight ? AppColors.chatBubbleMine : AppColors.chatBubbleTheirs,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.md),
                  topRight: const Radius.circular(AppRadius.md),
                  bottomLeft: Radius.circular(isRight ? AppRadius.md : _kBubbleTailRadius),
                  bottomRight: Radius.circular(isRight ? _kBubbleTailRadius : AppRadius.md),
                ),
                border: Border.all(
                  color: isRight ? AppColors.chatBubbleMineBorder : AppColors.glassBorder,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
