import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/widgets/network_avatar.dart';

/// Avatar bileşeni iki şeyi garanti eder: adres yoksa kişi ikonu görünür (karanlık daire
/// değil) ve verilen boyut korunur. Fotoğraf gelmeyen ekranlarda kullanıcı boş daire
/// yerine ikon görmeli.
void main() {
  testWidgets('adres yoksa kişi ikonu gösterilir', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NetworkAvatar(imageUrl: null, size: 40)),
      ),
    );

    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });

  testWidgets('boş adres de ikonla karşılanır', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NetworkAvatar(imageUrl: '', size: 40)),
      ),
    );

    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });

  testWidgets('ad verildiğinde ikon yerine baş harf gösterilir', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NetworkAvatar(imageUrl: null, fallbackText: 'ahmet yılmaz', size: 40)),
      ),
    );

    // Liste ekranlarında herkesin aynı ikonu göstermesi kullanıcıları ayırt edilemez yapar.
    expect(find.text('A'), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsNothing);
  });

  testWidgets('ad boşsa ikona düşer', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NetworkAvatar(imageUrl: null, fallbackText: '   ', size: 40)),
      ),
    );

    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });
}
