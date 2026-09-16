import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:gymapp_v2/features/sync/presentation/unsynced_records_cubit.dart';
import 'package:gymapp_v2/features/sync/presentation/unsynced_records_page.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncManager extends Mock implements SyncManager {}

void main() {
  late MockSyncManager syncManager;

  const record = RejectedRecord(
    key: 'k1',
    endpoint: '/training/sessions',
    reason: 'Egzersiz bulunamadı veya yetkiniz yok.',
  );

  setUp(() {
    syncManager = MockSyncManager();
    when(() => syncManager.rejectedRecords()).thenReturn([record]);
    when(() => syncManager.retry(any())).thenAnswer((_) async {});
    when(() => syncManager.discard(any())).thenAnswer((_) async {});
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => UnsyncedRecordsCubit(syncManager)..load(),
        child: const UnsyncedRecordsPage(),
      ),
    );
  }

  testWidgets('Sil önce onay ister; Vazgeç silmez, Sil siler', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pump();

    await tester.tap(find.text('Sil'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Kaydı sil'), findsOneWidget);

    await tester.tap(find.text('Vazgeç'));
    await tester.pump(const Duration(milliseconds: 100));
    verifyNever(() => syncManager.discard(any()));

    await tester.tap(find.text('Sil'));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Sil')));
    await tester.pump(const Duration(milliseconds: 100));

    verify(() => syncManager.discard('k1')).called(1);
  });

  testWidgets('Tekrar dene kaydı yeniden gönderir', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pump();

    await tester.tap(find.text('Tekrar dene'));
    await tester.pump(const Duration(milliseconds: 100));

    verify(() => syncManager.retry('k1')).called(1);
  });

  test('kayıt adı uca göre yazılır', () {
    expect(unsyncedRecordLabel('/training/sessions'), equals('Antrenman kaydı'));
    expect(unsyncedRecordLabel('/social/chat/send'), equals('Mesaj'));
    expect(unsyncedRecordLabel('/baska'), equals('Kayıt'));
  });
}
