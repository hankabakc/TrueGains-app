import 'package:flutter/material.dart';
import '../theme/app_dimens.dart';

class TabFadeStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const TabFadeStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<TabFadeStack> createState() => _TabFadeStackState();
}

class _TabFadeStackState extends State<TabFadeStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(TabFadeStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1.0;
      } else {
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: IndexedStack(
        index: widget.index,
        children: widget.children,
      ),
    );
  }
}
