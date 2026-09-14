import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';

void main() {
  group('AppColors gradients', () {
    test('heroGradient yalnızca primary ailesini kullanır', () {
      expect(AppColors.heroGradient.colors, const <Color>[
        Color(0x1F00E5A0),
        Color(0x0D00B380),
        Colors.transparent,
      ]);
    });

    test('silinen secondary mavisi hiçbir gradyanda yok', () {
      const deletedBlueTransparent = Color(0x0D3B82F6);
      const deletedBlueOpaque = Color(0xFF3B82F6);

      final gradientsToInspect = <LinearGradient>[
        AppColors.heroGradient,
        AppColors.primaryGradient,
        AppColors.glassGradient,
      ];

      for (final gradient in gradientsToInspect) {
        expect(gradient.colors, isNot(contains(deletedBlueTransparent)));
        expect(gradient.colors, isNot(contains(deletedBlueOpaque)));
      }
    });
  });
}
