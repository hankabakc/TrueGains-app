import 'package:flutter/material.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/util/motion.dart';

/// Bara metaforu: her cevap bara bir plaka ekler. Plakalar bir sette olduğu gibi
/// ortadan dışa doğru dizilir. Literal sayım üstteki etikette durduğu için
/// merkezden dolum bilgi kaybettirmez.
class IntroProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  /// Literal sayım burada durur; bu yüzden plakaların merkezden dolması bilgi
  /// kaybettirmez.
  final String label;

  const IntroProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.label,
  });

  /// Plakaların dolum sırası: merkeze en yakın olan önce.
  /// totalSteps = 8 için -> 3, 4, 2, 5, 1, 6, 0, 7
  static List<int> fillOrder(int totalSteps) {
    final double center = (totalSteps - 1) / 2;
    final List<int> order = List<int>.generate(totalSteps, (i) => i);
    order.sort(
      (a, b) => (a - center).abs().compareTo((b - center).abs()),
    );
    return order;
  }

  @override
  Widget build(BuildContext context) {
    final List<int> order = fillOrder(totalSteps);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.sectionLabel),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 20,
            child: Row(
              children: List<Widget>.generate(totalSteps, (index) {
                final bool loaded = order.indexOf(index) <= currentStep;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Center(
                      child: AnimatedContainer(
                        duration: motionDuration(context, AppDurations.base),
                        curve: Curves.easeOutQuint,
                        height: loaded ? 20 : 6,
                        decoration: BoxDecoration(
                          color: loaded ? AppColors.primary : AppColors.card,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
