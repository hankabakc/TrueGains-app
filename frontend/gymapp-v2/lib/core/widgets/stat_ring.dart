import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatRing extends StatelessWidget {
  final double progress;
  final Color color;
  final double size;
  final Widget center;

  const StatRing({
    super.key,
    required this.progress,
    required this.color,
    this.size = 80.0,
    required this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.glassWhite,
              color: color,
              strokeWidth: 6.0,
              strokeCap: StrokeCap.round,
            ),
          ),
          center,
        ],
      ),
    );
  }
}
