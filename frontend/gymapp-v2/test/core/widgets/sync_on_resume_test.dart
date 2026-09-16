import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:gymapp_v2/core/widgets/sync_on_resume.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncManager extends Mock implements SyncManager {}

void main() {
  late MockSyncManager syncManager;

  setUp(() {
    syncManager = MockSyncManager();
    when(() => syncManager.syncPendingData()).thenAnswer((_) async {});
    GetIt.instance.registerSingleton<SyncManager>(syncManager);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('uygulama öne gelince bekleyen kayıtlar gönderilir', (tester) async {
    await tester.pumpWidget(const SyncOnResume(child: SizedBox()));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    verify(() => syncManager.syncPendingData()).called(1);
  });

  testWidgets('arka plana geçişte gönderim yapılmaz', (tester) async {
    await tester.pumpWidget(const SyncOnResume(child: SizedBox()));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

    verifyNever(() => syncManager.syncPendingData());
  });
}
