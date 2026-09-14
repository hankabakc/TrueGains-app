import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';

/// Cam kart içindeki ListTile, Flutter'ın "ink splashes may be invisible" denetimini
/// tetikliyordu (Sentry'de 152 olay). Kart kendi Material'ını taşımazsa hata geri gelir.
void main() {
  testWidgets('içindeki ListTile Flutter hatası üretmez', (tester) async {
    await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassContainer(child: ListTile(title: Text('Yulaf'), onTap: () {})),
          ),
        ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('varsayılan metin stili değişmeden geçer', (tester) async {
    late TextStyle disardaki;
    late TextStyle icerideki;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DefaultTextStyle(
            style: const TextStyle(fontSize: 27, color: Colors.purple),
            child: Builder(
              builder: (context) {
                disardaki = DefaultTextStyle.of(context).style;
                return GlassContainer(
                  child: Builder(
                    builder: (context) {
                      icerideki = DefaultTextStyle.of(context).style;
                      return const SizedBox();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Material, textStyle verilmezse kendi varsayılanını dayatır ve tüm cam
    // kartlardaki yazı sessizce değişir.
    expect(icerideki, disardaki);
  });
}
