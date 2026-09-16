import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:gymapp_v2/features/sync/presentation/unsynced_records_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncManager extends Mock implements SyncManager {}

void main() {
  late MockSyncManager syncManager;
  late UnsyncedRecordsCubit cubit;

  const record = RejectedRecord(
    key: 'k1',
    endpoint: '/training/sessions',
    reason: 'Egzersiz bulunamadı veya yetkiniz yok.',
  );

  setUp(() {
    syncManager = MockSyncManager();
    cubit = UnsyncedRecordsCubit(syncManager);
  });

  tearDown(() {
    cubit.close();
  });

  test('yükleyince reddedilen kayıtlar gelir', () {
    when(() => syncManager.rejectedRecords()).thenReturn([record]);

    cubit.load();

    expect(cubit.state.records, equals([record]));
    expect(cubit.state.busy, isFalse);
  });

  test('tekrar dene yöneticiye iletilir ve liste yenilenir', () async {
    when(() => syncManager.retry('k1')).thenAnswer((_) async {});
    when(() => syncManager.rejectedRecords()).thenReturn([]);

    await cubit.retry('k1');

    verify(() => syncManager.retry('k1')).called(1);
    expect(cubit.state.records, isEmpty);
    expect(cubit.state.busy, isFalse);
  });

  test('silme yöneticiye iletilir ve liste yenilenir', () async {
    when(() => syncManager.discard('k1')).thenAnswer((_) async {});
    when(() => syncManager.rejectedRecords()).thenReturn([]);

    await cubit.discard('k1');

    verify(() => syncManager.discard('k1')).called(1);
    expect(cubit.state.records, isEmpty);
    expect(cubit.state.busy, isFalse);
  });
}
