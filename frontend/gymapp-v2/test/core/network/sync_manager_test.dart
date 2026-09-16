import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/constants/storage_keys.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/core/network/network_info.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockNetworkInfo extends Mock implements NetworkInfo {}
class MockDioClient extends Mock implements DioClient {}
class MockDio extends Mock implements Dio {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late Directory tempDir;
  late MockNetworkInfo networkInfo;
  late MockDioClient dioClient;
  late MockDio dio;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_manager_test');
    Hive.init(tempDir.path);
    networkInfo = MockNetworkInfo();
    dioClient = MockDioClient();
    dio = MockDio();
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => networkInfo.onConnectivityChanged).thenAnswer((_) => const Stream.empty());
    when(() => dioClient.dio).thenReturn(dio);
    when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data'))).thenAnswer(
      (inv) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: inv.positionalArguments.first as String),
        statusCode: 200,
      ),
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('kuyruğa eklenen kayıt o anki kullanıcıya ait işaretlenir', () async {
    final box = await Hive.openBox<String>(SyncManager.boxName);
    int? user = 1;
    final manager = SyncManager(
      networkInfo: networkInfo,
      dioClient: dioClient,
      syncBox: box,
      currentUserId: () => user,
    );

    await manager.addToQueue('/kayit', {'a': 1});

    final single = jsonDecode(box.values.single) as Map<String, dynamic>;
    expect(single['ownerId'], equals(1));
  });

  test('yalnızca oturumdaki kullanıcının kaydı gönderilir, başkasınınki kuyrukta kalır', () async {
    final box = await Hive.openBox<String>(SyncManager.boxName);
    int? user = 1;
    final manager = SyncManager(
      networkInfo: networkInfo,
      dioClient: dioClient,
      syncBox: box,
      currentUserId: () => user,
    );

    user = 1;
    await manager.addToQueue('/kayit-1', {});
    user = 2;
    await manager.addToQueue('/kayit-2', {});

    user = 1;
    await manager.syncPendingData();

    verify(() => dio.post<Map<String, dynamic>>('/kayit-1', data: any(named: 'data'))).called(1);
    verifyNever(() => dio.post<Map<String, dynamic>>('/kayit-2', data: any(named: 'data')));
    expect(box.length, equals(1));
    final remaining = jsonDecode(box.values.single) as Map<String, dynamic>;
    expect(remaining['ownerId'], equals(2));
  });

  test('oturum yokken hiçbir kayıt gönderilmez ve silinmez', () async {
    final box = await Hive.openBox<String>(SyncManager.boxName);
    int? user = 1;
    final manager = SyncManager(
      networkInfo: networkInfo,
      dioClient: dioClient,
      syncBox: box,
      currentUserId: () => user,
    );

    await manager.addToQueue('/kayit', {});
    await box.put('eski', jsonEncode({
      'id': 'eski',
      'endpoint': '/eski',
      'payload': <String, dynamic>{},
      'timestamp': '2026-01-01T00:00:00Z',
    }));
    user = null;
    await manager.syncPendingData();

    verifyNever(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')));
    expect(box.length, equals(2));
  });

  test('sahibi olmayan eski kayıt oturumdaki kullanıcıyla gönderilir', () async {
    final box = await Hive.openBox<String>(SyncManager.boxName);
    int? user = 1;
    final manager = SyncManager(
      networkInfo: networkInfo,
      dioClient: dioClient,
      syncBox: box,
      currentUserId: () => user,
    );

    await box.put('eski', jsonEncode({
      'id': 'eski',
      'endpoint': '/eski',
      'payload': <String, dynamic>{},
      'timestamp': '2026-01-01T00:00:00Z',
    }));

    await manager.syncPendingData();

    verify(() => dio.post<Map<String, dynamic>>('/eski', data: any(named: 'data'))).called(1);
    expect(box.isEmpty, isTrue);
  });

  test('sunucu reddederse kayıt kuyrukta kalır', () async {
    final box = await Hive.openBox<String>(SyncManager.boxName);
    int? user = 1;
    final manager = SyncManager(
      networkInfo: networkInfo,
      dioClient: dioClient,
      syncBox: box,
      currentUserId: () => user,
    );

    when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/kayit'),
        type: DioExceptionType.badResponse,
      ),
    );

    await manager.addToQueue('/kayit', {});
    await manager.syncPendingData();

    expect(box.length, equals(1));
  });

  test('kuyruk kutusu diskte şifreli durur', () async {
    final storage = MockSecureStorage();
    when(() => storage.read(key: StorageKeys.syncQueueKey)).thenAnswer((_) async => null);
    when(() => storage.write(key: StorageKeys.syncQueueKey, value: any(named: 'value')))
        .thenAnswer((_) async {});

    await openSyncQueueBox(storage);
    final box = Hive.box<String>(SyncManager.boxName);
    await box.put('k', jsonEncode({'payload': {'content': 'gizli-mesaj-123'}}));
    await box.close();

    final bytes = File('${tempDir.path}/${SyncManager.boxName}.hive').readAsBytesSync();
    expect(latin1.decode(bytes).contains('gizli-mesaj-123'), isFalse);
    verify(() => storage.write(key: StorageKeys.syncQueueKey, value: any(named: 'value'))).called(1);
  });

  test('eski şifresiz kutudaki kayıtlar silinmeden taşınır, antrenman ucu düzeltilir', () async {
    final storage = MockSecureStorage();
    when(() => storage.read(key: StorageKeys.syncQueueKey)).thenAnswer((_) async => null);
    when(() => storage.write(key: StorageKeys.syncQueueKey, value: any(named: 'value')))
        .thenAnswer((_) async {});

    final legacy = await Hive.openBox<String>(SyncManager.legacyBoxName);
    await legacy.put('m1', jsonEncode({
      'id': 'm1',
      'endpoint': '/social/chat/send',
      'payload': {'content': 'selam'},
      'timestamp': '2026-01-01T00:00:00Z',
    }));
    await legacy.put('w1', jsonEncode({
      'id': 'w1',
      'endpoint': '/training/session',
      'payload': {'totalSeconds': 60},
      'timestamp': '2026-01-01T00:00:00Z',
    }));
    await legacy.close();

    await openSyncQueueBox(storage);
    final box = Hive.box<String>(SyncManager.boxName);

    expect(box.length, equals(2));
    final w1 = jsonDecode(box.get('w1')!) as Map<String, dynamic>;
    expect(w1['endpoint'], equals('/training/sessions'));
    final m1 = jsonDecode(box.get('m1')!) as Map<String, dynamic>;
    expect(m1['endpoint'], equals('/social/chat/send'));
    expect((m1['payload'] as Map<String, dynamic>)['content'], equals('selam'));
    expect(await Hive.boxExists(SyncManager.legacyBoxName), isFalse);
  });

  test('aynı anda iki gönderim çağrısı kaydı bir kez gönderir', () async {
    final gate = Completer<void>();
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')))
        .thenAnswer((inv) async {
      await gate.future;
      return Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: inv.positionalArguments.first as String),
        statusCode: 200,
      );
    });

    final box = await Hive.openBox<String>(SyncManager.boxName);
    final manager = SyncManager(
      networkInfo: networkInfo,
      dioClient: dioClient,
      syncBox: box,
      currentUserId: () => 1,
    );

    await manager.addToQueue('/kayit', {});
    final first = manager.syncPendingData();
    final second = manager.syncPendingData();
    gate.complete();
    await Future.wait([first, second]);

    verify(() => dio.post<Map<String, dynamic>>('/kayit', data: any(named: 'data'))).called(1);
    expect(box.isEmpty, isTrue);
  });
}
