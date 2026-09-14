import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/features/profile/presentation/pages/about_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'TrueGains',
      packageName: 'com.hankabakc.coachconnect',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
      installerStore: null,
    );
  });

  testWidgets('sürüm ekranda görünür', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AboutPage(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('1.0.0 (1)'), findsOneWidget);
  });

  testWidgets('marka ve telif satırı görünür', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AboutPage(),
      ),
    );

    await tester.pump();

    expect(find.text('TrueGains'), findsOneWidget);
    expect(find.textContaining('© 2026 TrueGains'), findsOneWidget);
  });
}
