import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/widgets/empty_state.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('EmptyState Widget Tests', () {
    testWidgets('ikon, başlık ve açıklama çiziliyor', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const EmptyState(
            icon: Icons.fitness_center_rounded,
            title: 'Egzersiz bulunamadı.',
            message: 'Yeni bir egzersiz arayın.',
          ),
        ),
      );

      expect(find.byIcon(Icons.fitness_center_rounded), findsOneWidget);
      expect(find.text('Egzersiz bulunamadı.'), findsOneWidget);
      expect(find.text('Yeni bir egzersiz arayın.'), findsOneWidget);
    });

    testWidgets('message verilmezse yalnızca başlık çizilir', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const EmptyState(
            icon: Icons.assignment_rounded,
            title: 'Hareket bulunamadı.',
          ),
        ),
      );

      expect(find.byIcon(Icons.assignment_rounded), findsOneWidget);
      expect(find.text('Hareket bulunamadı.'), findsOneWidget);
      // Sadece başlık metni var, message yok
      expect(find.text('Yeni bir egzersiz arayın.'), findsNothing);
    });

    testWidgets('CTA yalnızca actionLabel ve onAction birlikte verilince çıkar',
        (tester) async {
      bool actionTriggered = false;

      // Durum 1: actionLabel veya onAction yokken buton çıkmaz
      await tester.pumpWidget(
        buildTestableWidget(
          const EmptyState(
            icon: Icons.shopping_cart_outlined,
            title: 'Sepet boş',
          ),
        ),
      );

      expect(find.byType(PremiumButton), findsNothing);

      // Durum 2: actionLabel ve onAction verilince buton çıkar ve tetiklenir
      await tester.pumpWidget(
        buildTestableWidget(
          EmptyState(
            icon: Icons.shopping_cart_outlined,
            title: 'Sepet boş',
            actionLabel: 'Alışverişe Başla',
            onAction: () {
              actionTriggered = true;
            },
          ),
        ),
      );

      expect(find.byType(PremiumButton), findsOneWidget);
      expect(find.text('Alışverişe Başla'), findsOneWidget);

      await tester.tap(find.byType(PremiumButton));
      await tester.pump();

      expect(actionTriggered, isTrue);
    });
  });
}
