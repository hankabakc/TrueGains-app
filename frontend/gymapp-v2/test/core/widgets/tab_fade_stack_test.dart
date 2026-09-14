import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/widgets/tab_fade_stack.dart';

class _CounterWidget extends StatefulWidget {
  const _CounterWidget();

  @override
  State<_CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<_CounterWidget> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $count'),
        ElevatedButton(
          onPressed: () => setState(() => count++),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

void main() {
  group('TabFadeStack', () {
    testWidgets('seçili sekmenin içeriği görünür', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TabFadeStack(
              index: 0,
              children: [
                Text('Tab A'),
                Text('Tab B'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Tab A'), findsOneWidget);
      expect(find.text('Tab B'), findsNothing);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TabFadeStack(
              index: 1,
              children: [
                Text('Tab A'),
                Text('Tab B'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tab A'), findsNothing);
      expect(find.text('Tab B'), findsOneWidget);
    });

    testWidgets('sekme değişse de sayfa durumu korunur', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TabFadeStack(
              index: 0,
              children: [
                _CounterWidget(),
                Text('Tab B'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);

      await tester.tap(find.text('Increment'));
      await tester.pump();
      expect(find.text('Count: 1'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TabFadeStack(
              index: 1,
              children: [
                _CounterWidget(),
                Text('Tab B'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tab B'), findsOneWidget);
      expect(find.text('Count: 1'), findsNothing);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TabFadeStack(
              index: 0,
              children: [
                _CounterWidget(),
                Text('Tab B'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets("geçişte opaklık 1'e ulaşır", (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TabFadeStack(
              index: 0,
              children: [
                Text('Tab A'),
                Text('Tab B'),
              ],
            ),
          ),
        ),
      );

      final initialFade = tester.widget<FadeTransition>(
        find.descendant(of: find.byType(TabFadeStack), matching: find.byType(FadeTransition)),
      );
      expect(initialFade.opacity.value, 1.0);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TabFadeStack(
              index: 1,
              children: [
                Text('Tab A'),
                Text('Tab B'),
              ],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 60));
      final midFade = tester.widget<FadeTransition>(
        find.descendant(of: find.byType(TabFadeStack), matching: find.byType(FadeTransition)),
      );
      expect(midFade.opacity.value, lessThan(1.0));

      await tester.pumpAndSettle();
      final finalFade = tester.widget<FadeTransition>(
        find.descendant(of: find.byType(TabFadeStack), matching: find.byType(FadeTransition)),
      );
      expect(finalFade.opacity.value, 1.0);
    });

    testWidgets('animasyonları kaldır ayarı açıkken sekme değişimi anında tamamlanır', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: TabFadeStack(
                index: 0,
                children: [
                  Text('Tab A'),
                  Text('Tab B'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: TabFadeStack(
                index: 1,
                children: [
                  Text('Tab A'),
                  Text('Tab B'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1));
      final fade = tester.widget<FadeTransition>(
        find.descendant(of: find.byType(TabFadeStack), matching: find.byType(FadeTransition)),
      );
      expect(fade.opacity.value, 1.0);
    });
  });
}

