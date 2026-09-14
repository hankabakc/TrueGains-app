import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/util/motion.dart';

/// Sürüklenerek değer seçilen yatay cetvel. Bottom sheet açmaz: değer ve kontrol
/// aynı ekranda kalır. Seçili değer, sabit duran merkez göstergesinin altındadır.
class IntroRuler extends StatefulWidget {
  final int min;
  final int max;
  final int value;
  final ValueChanged<int> onChanged;

  const IntroRuler({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
  });

  @override
  State<IntroRuler> createState() => _IntroRulerState();
}

class _IntroRulerState extends State<IntroRuler> {
  static const double _tickWidth = 14.0;
  static const double _height = 88.0;

  late final ScrollController _controller;
  late int _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    // Merkezlenen indeks = offset / _tickWidth (yatay padding buna göre kurulur).
    _controller = ScrollController(
      initialScrollOffset: (widget.value - widget.min) * _tickWidth,
    );
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final int index = (_controller.offset / _tickWidth).round();
    final int next = (widget.min + index).clamp(widget.min, widget.max);
    if (next != _currentValue) {
      _currentValue = next;
      HapticFeedback.selectionClick();
      widget.onChanged(next);
    }
  }

  /// Sürükleme bitince en yakın çentiğe oturtur.
  bool _onScrollEnd(ScrollEndNotification notification) {
    if (!_controller.hasClients) return false;
    final double target = (_currentValue - widget.min) * _tickWidth;
    if ((_controller.offset - target).abs() < 0.5) return false;
    _controller.animateTo(
      target,
      duration: motionDuration(context, AppDurations.fast),
      curve: Curves.easeOutCubic,
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double sidePadding = (constraints.maxWidth - _tickWidth) / 2;

          return Stack(
            alignment: Alignment.center,
            children: [
              NotificationListener<ScrollEndNotification>(
                onNotification: _onScrollEnd,
                child: ListView.builder(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: sidePadding),
                  itemExtent: _tickWidth,
                  itemCount: widget.max - widget.min + 1,
                  itemBuilder: (context, index) {
                    final int tickValue = widget.min + index;
                    final bool isMajor = tickValue % 10 == 0;
                    final bool isMid = tickValue % 5 == 0;
                    final double tickHeight = isMajor
                        ? 32
                        : isMid
                            ? 20
                            : 12;

                    return Column(
                      children: [
                        Container(
                          width: 2,
                          height: tickHeight,
                          decoration: BoxDecoration(
                            color: isMajor
                                ? AppColors.textSecondary
                                : AppColors.textMuted,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        const Spacer(),
                        if (isMajor)
                          // Çentik kolonu 14px; etiket bu genişliğe sığmayıp
                          // dikey sarıyordu. OverflowBox etiketin kolonun
                          // dışına taşmasına izin verir. Yüksekliği sabitlemek
                          // ZORUNLU: Column dikeyde sınırsız constraint verdiği
                          // için OverflowBox aksi hâlde sonsuz yükseklik alır.
                          SizedBox(
                            height: 18,
                            child: OverflowBox(
                              maxWidth: 60,
                              minWidth: 0,
                              maxHeight: 18,
                              minHeight: 0,
                              child: Text(
                                '$tickValue',
                                maxLines: 1,
                                softWrap: false,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.cardCaption,
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                    );
                  },
                ),
              ),
              // Sabit merkez göstergesi — bu ekrandaki accent kullanımlarından biri.
              IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 3,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
