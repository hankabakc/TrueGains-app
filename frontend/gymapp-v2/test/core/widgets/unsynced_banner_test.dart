import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:gymapp_v2/core/widgets/unsynced_banner.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncManager extends Mock implements SyncManager {}

void main() {
  late MockSyncManager syncManager;
  late ValueNotifier<int> notifier;

  setUp(() {
    syncManager = MockSyncManager();
    notifier = ValueNotifier<int>(0);
    when(() => syncManager.rejectedCount).thenReturn(notifier);
    GetIt.instance.registerSingleton<SyncManager>(syncManager);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget buildTestableWidget() {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: UnsyncedBanner()),
        ),
        GoRoute(
          path: '/unsynced-records',
          builder: (_, __) => const Scaffold(body: Text('liste')),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('reddedilen kayıt yoksa şerit görünmez', (tester) async {
    notifier.value = 0;
    await tester.pumpWidget(buildTestableWidget());
    await tester.pump();

    expect(find.textContaining('aktarılamadı'), findsNothing);
  });

  testWidgets('reddedilen kayıt sayısı şeritte yazar', (tester) async {
    notifier.value = 2;
    await tester.pumpWidget(buildTestableWidget());
    await tester.pump();

    expect(find.text('2 kayıt sunucuya aktarılamadı · Göster'), findsOneWidget);
  });

  testWidgets('şeride dokununca liste açılır', (tester) async {
    notifier.value = 1;
    await tester.pumpWidget(buildTestableWidget());
    await tester.pump();

    await tester.tap(find.textContaining('aktarılamadı'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('liste'), findsOneWidget);
  });
}
