import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/widgets/skeleton_pulse.dart';

void main() {
  group('SkeletonPulse', () {
    testWidgets('çocuk çizilir', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonPulse(
              child: Text('içerik'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('içerik'), findsOneWidget);
    });

    testWidgets('opaklık nabız aralığında kalır', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonPulse(
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final fadeFinder = find.descendant(
        of: find.byType(SkeletonPulse),
        matching: find.byType(FadeTransition),
      );
      final fade = tester.widget<FadeTransition>(fadeFinder.first);
      expect(fade.opacity.value, inInclusiveRange(0.35, 0.75));
    });

    testWidgets('animasyonları kaldır ayarı açıkken opaklık değişmez', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: SkeletonPulse(
                child: SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final fadeFinder = find.descendant(
        of: find.byType(SkeletonPulse),
        matching: find.byType(FadeTransition),
      );
      final fade1 = tester.widget<FadeTransition>(fadeFinder.first);
      final value1 = fade1.opacity.value;

      await tester.pump(const Duration(milliseconds: 200));

      final fade2 = tester.widget<FadeTransition>(fadeFinder.first);
      final value2 = fade2.opacity.value;

      expect(value1, equals(value2));
      expect(value1, closeTo(0.75, 0.001));
    });

    testWidgets('animasyonları kaldır ayarı kapalıyken opaklık değişir', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: false),
          child: MaterialApp(
            home: Scaffold(
              body: SkeletonPulse(
                child: SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final fadeFinder = find.descendant(
        of: find.byType(SkeletonPulse),
        matching: find.byType(FadeTransition),
      );
      final fade1 = tester.widget<FadeTransition>(fadeFinder.first);
      final value1 = fade1.opacity.value;

      await tester.pump(const Duration(milliseconds: 200));

      final fade2 = tester.widget<FadeTransition>(fadeFinder.first);
      final value2 = fade2.opacity.value;

      expect(value1, isNot(equals(value2)));
    });
  });
}

