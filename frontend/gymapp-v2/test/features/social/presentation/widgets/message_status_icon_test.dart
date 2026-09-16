import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:gymapp_v2/features/social/data/models/message_model.dart';
import 'package:gymapp_v2/features/social/data/models/message_status.dart';
import 'package:gymapp_v2/features/social/presentation/widgets/message_status_icon.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncManager extends Mock implements SyncManager {}

/// Mesaj balonundaki "Gönderilemedi" işareti (G-80, KR14). Kuyruk kaydı balona localId ile bağlanır.
void main() {
  late MockSyncManager syncManager;
  late ValueNotifier<int> rejectedCount;

  MessageModel queued(String localId) => MessageModel(
        id: -1,
        conversationId: 10,
        senderId: 5,
        senderFullName: '',
        content: 'selam',
        status: MessageStatus.sent,
        sentAt: DateTime(2026, 9, 16),
        localId: localId,
      );

  RejectedRecord rejectedFor(String localId) => RejectedRecord(
        key: 'k-$localId',
        endpoint: '/social/chat/send',
        reason: 'Mesaj en fazla 2000 karakter olabilir.',
        localId: localId,
      );

  Future<void> pumpIcon(WidgetTester tester, MessageModel message) async {
    final GoRouter router = GoRouter(routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            Scaffold(body: Center(child: MessageStatusIcon(message: message))),
      ),
      GoRoute(
        path: '/unsynced-records',
        builder: (BuildContext context, GoRouterState state) => const Scaffold(body: Text('aktarılamayan kayıtlar')),
      ),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
  }

  setUp(() {
    syncManager = MockSyncManager();
    rejectedCount = ValueNotifier<int>(0);
    when(() => syncManager.rejectedCount).thenReturn(rejectedCount);
    when(() => syncManager.rejectedRecords()).thenReturn(<RejectedRecord>[]);
    GetIt.instance.registerSingleton<SyncManager>(syncManager);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('reddedilen kuyruk mesajında saat yerine kırmızı Gönderilemedi görünür', (WidgetTester tester) async {
    when(() => syncManager.rejectedRecords()).thenReturn(<RejectedRecord>[rejectedFor('L1')]);
    rejectedCount.value = 1;

    await pumpIcon(tester, queued('L1'));

    expect(find.text('Gönderilemedi'), findsOneWidget);
    expect(find.byIcon(Icons.schedule_rounded), findsNothing);
  });

  testWidgets('başka kaydın reddi bu balonu işaretlemez', (WidgetTester tester) async {
    when(() => syncManager.rejectedRecords()).thenReturn(<RejectedRecord>[rejectedFor('L2')]);
    rejectedCount.value = 1;

    await pumpIcon(tester, queued('L1'));

    expect(find.text('Gönderilemedi'), findsNothing);
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
  });

  testWidgets('ret gelince işaret ekran yeniden açılmadan belirir', (WidgetTester tester) async {
    await pumpIcon(tester, queued('L1'));

    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);

    when(() => syncManager.rejectedRecords()).thenReturn(<RejectedRecord>[rejectedFor('L1')]);
    rejectedCount.value = 1;
    await tester.pump();

    expect(find.text('Gönderilemedi'), findsOneWidget);
  });

  testWidgets('Gönderilemedi işaretine dokununca aktarılamayan kayıtlar açılır', (WidgetTester tester) async {
    when(() => syncManager.rejectedRecords()).thenReturn(<RejectedRecord>[rejectedFor('L1')]);
    rejectedCount.value = 1;

    await pumpIcon(tester, queued('L1'));
    await tester.tap(find.text('Gönderilemedi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('aktarılamayan kayıtlar'), findsOneWidget);
  });
}
