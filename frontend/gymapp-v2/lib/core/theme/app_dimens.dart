import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

abstract final class AppRadius {
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double pill = 999.0;
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration scroll = Duration(milliseconds: 300);
}

abstract final class AppElevation {
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x66000000), // ~40% opacity black
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static List<BoxShadow> accentGlow(Color c) {
    return [
      BoxShadow(
        color: c.withValues(alpha: 0.14),
        blurRadius: 40,
        spreadRadius: -4,
        offset: const Offset(0, 12),
      ),
    ];
  }

  static List<BoxShadow> softGlow(Color c) {
    return [
      BoxShadow(
        color: c.withValues(alpha: 0.10),
        blurRadius: 24,
        spreadRadius: -4,
        offset: const Offset(0, 8),
      ),
    ];
  }
}

abstract final class AppLayout {
  static const double bentoCellHeight = 180.0;
  static const double bottomNavClearance = 100.0;
  static const double heroDecorIconSize = 72.0;
  static const double heroDecorIconOpacity = 0.1;
}
