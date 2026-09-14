import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';
import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/goal.dart';
import 'package:gymapp_v2/features/membership/presentation/bloc/intro/intro_state.dart';
import 'package:gymapp_v2/core/widgets/signup/intro_result_view.dart';

void main() {
  // Bar bir kez sessizce 0 piksel yükseklikte render oldu (ColoredBox gevşek
  // constraint altında constraints.smallest'a çöküyor). Bu test onu yakalar.
  testWidgets('makro barı görünür yükseklikte ve tam genişlikte çizilir',
      (tester) async {
    tester.view.physicalSize = const Size(1344, 2992);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IntroResultView(
            state: IntroState(
              gender: Gender.male,
              goal: Goal.koru,
              activityLevel: ActivityLevel.moderatelyActive,
            ),
            isActive: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // [0] Scaffold zemini; kalan üçü protein / karbonhidrat / yağ segmentleri.
    final Finder boxes = find.byType(ColoredBox);
    expect(boxes.evaluate().length, 4);

    double totalWidth = 0;
    for (int i = 1; i < 4; i++) {
      final Size size = tester.getSize(boxes.at(i));
      expect(size.height, greaterThanOrEqualTo(8.0));
      expect(size.width, greaterThan(0.0));
      totalWidth += size.width;
    }
    // Ekran genişliği 448, iki yandan AppSpacing.lg (24) padding.
    expect(totalWidth, closeTo(400, 0.5));
  });
}
