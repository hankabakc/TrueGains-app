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

  DioException httpError(String path, int status, {String? message}) => DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.badResponse,
        response: Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: path),
          statusCode: status,
          data: message == null ? null : <String, dynamic>{'message': message},
        ),
      );

  test('sunucu kalıcı reddederse kayıt aktarılamadı olarak işaretlenir, silinmez', () async {
    when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data'))).thenThrow(
      httpError('/kayit', 404, message: 'Egzersiz bulunamadı veya yetkiniz yok.'),
    );

    final box = await Hive.openBox<String>(SyncManager.boxName);
    int? user = 1;
    final manager = SyncManager(
      networkInfo: networkInfo,
      dioClient: dioClient,
      syncBox: box,
      currentUserId: () => user,
    );

    await manager.addToQueue('/kayit', {'localId': 'L1'});
    await manager.syncPendingData();

    expect(box.length, equals(1));
    final item = jsonDecode(box.values.single) as Map<String, dynamic>;
    expect(item['status'], equals('rejected'));
    expect(item['reason'], equals('Egzersiz bulunamadı veya yetkiniz yok.'));
    expect(manager.rejectedCount.value, equals(1));
  });

  test('reddedilen kayıt kendiliğinden yeniden gönderilmez', () async {
    when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data'))).thenThrow(
      httpError('/kayit', 404, message: 'Egzersiz bulunamadı veya yetkiniz yok.'),
    );

    final box = await Hive.openBox<String>(SyncManager.boxName);
    int? user = 1;
    final manager = SyncManager(
      networkInfo: networkInfo,
      dioClient: dioClient,
      syncBox: box,
      currentUserId: () => user,
    );

    await manager.addToQueue('/kayit', {'localId': 'L1'});
    await manager.syncPendingData();
    await manager.syncPendingData();

    verify(() => dio.post<Map<String, dynamic>>('/kayit', data: any(named: 'data'))).called(1);
  });

  test('geçici sunucu hatasında kayıt bekler ve sonra gider', () async {
    when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data'))).thenThrow(
      httpError('/kayit', 503),
    );

    final box = await Hive.openBox<String>(SyncManager.boxName);
    int? user = 1;
    final manager = SyncManager(
      networkInfo: networkInfo,
      dioClient: dioClient,
      syncBox: box,
      currentUserId: () => user,
    );

    await manager.addToQueue('/kayit', {});
    await manager.syncPendingData();

    final item = jsonDecode(box.values.single) as Map<String, dynamic>;
    expect(item['status'], isNull);
    expect(manager.rejectedCount.value, equals(0));

    when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data'))).thenAnswer(
      (inv) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: inv.positionalArguments.first as String),
        statusCode: 200,
      ),
    );

    await manager.syncPendingData();
    expect(box.isEmpty, isTrue);
  });

  test('oturum hatası (401) ret sayılmaz', () async {
    when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data'))).thenThrow(
      httpError('/kayit', 401),
    );

    final box = await Hive.openBox<String>(SyncManager.boxName);
    int? user = 1;
    final manager = SyncManager(
      networkInfo: networkInfo,
      dioClient: dioClient,
      syncBox: box,
      currentUserId: () => user,
    );

    await manager.addToQueue('/kayit', {});
    await manager.syncPendingData();

    final item = jsonDecode(box.values.single) as Map<String, dynamic>;
    expect(item['status'], isNull);
    expect(manager.rejectedCount.value, equals(0));
  });

  test('tekrar dene kaydı aynı yükle yeniden gönderir, başarılıysa kuyruktan çıkar', () async {
    when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data'))).thenThrow(
      httpError('/kayit', 404, message: 'Egzersiz bulunamadı veya yetkiniz yok.'),
    );

    final box = await Hive.openBox<String>(SyncManager.boxName);
    int? user = 1;
    final manager = SyncManager(
      networkInfo: networkInfo,
      dioClient: dioClient,
      syncBox: box,
      currentUserId: () => user,
    );

    await manager.addToQueue('/kayit', {'localId': 'L1'});
    await manager.syncPendingData();

    when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data'))).thenAnswer(
      (inv) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: inv.positionalArguments.first as String),
        statusCode: 200,
      ),
    );

    final key = box.keys.single as String;
    await manager.retry(key);

    verify(() => dio.post<Map<String, dynamic>>('/kayit', data: {'localId': 'L1'})).called(2);
    expect(box.isEmpty, isTrue);
    expect(manager.rejectedCount.value, equals(0));
  });

  test('sil yalnızca seçilen kaydı kaldırır', () async {
    final box = await Hive.openBox<String>(SyncManager.boxName);
    int? user = 1;
    final manager = SyncManager(
      networkInfo: networkInfo,
      dioClient: dioClient,
      syncBox: box,
      currentUserId: () => user,
    );

    await box.put('a', jsonEncode({
      'id': 'a',
      'endpoint': '/a',
      'payload': <String, dynamic>{},
      'timestamp': '2026-01-01T00:00:00Z',
      'ownerId': 1,
      'status': 'rejected',
      'reason': 'x',
    }));
    await box.put('b', jsonEncode({
      'id': 'b',
      'endpoint': '/b',
      'payload': <String, dynamic>{},
      'timestamp': '2026-01-01T00:00:00Z',
      'ownerId': 1,
    }));

    await manager.discard('a');
    expect(box.keys.toList(), equals(['b']));
    expect(manager.rejectedCount.value, equals(0));
  });

  test('reddedilenler yalnızca oturumdaki kullanıcı için listelenir', () async {
    final box = await Hive.openBox<String>(SyncManager.boxName);
    int? user = 1;
    final manager = SyncManager(
      networkInfo: networkInfo,
      dioClient: dioClient,
      syncBox: box,
      currentUserId: () => user,
    );

    await box.put('r1', jsonEncode({
      'id': 'r1',
      'endpoint': '/r1',
      'payload': <String, dynamic>{},
      'timestamp': '2026-01-01T00:00:00Z',
      'ownerId': 1,
      'status': 'rejected',
      'reason': 'x',
    }));
    await box.put('r2', jsonEncode({
      'id': 'r2',
      'endpoint': '/r2',
      'payload': <String, dynamic>{},
      'timestamp': '2026-01-01T00:00:00Z',
      'ownerId': 2,
      'status': 'rejected',
      'reason': 'y',
    }));

    expect(manager.rejectedRecords().map((r) => r.key).toList(), equals(['r1']));
    manager.refreshRejectedCount();
    expect(manager.rejectedCount.value, equals(1));
  });

  test('reddedilen kayıt yükteki yerel kimliği taşır', () async {
    when(() => dio.post<Map<String, dynamic>>(
          '/social/chat/send',
          data: any(named: 'data'),
        )).thenThrow(httpError(
      '/social/chat/send',
      400,
      message: 'Mesaj en fazla 2000 karakter olabilir.',
    ));

    final box = await Hive.openBox<String>(SyncManager.boxName);
    final manager = SyncManager(
      networkInfo: networkInfo,
      dioClient: dioClient,
      syncBox: box,
      currentUserId: () => 1,
    );

    await manager.addToQueue(
      '/social/chat/send',
      <String, dynamic>{'conversationId': 10, 'content': 'selam', 'localId': 'L1'},
    );

    await manager.syncPendingData();

    expect(manager.rejectedRecords().single.localId, equals('L1'));
  });

  // --- G-83: internetsiz silme ve bekleyen kayıtların gösterimi ---

  SyncManager managerFor(Box<String> box, {int? Function()? user}) => SyncManager(
        networkInfo: networkInfo,
        dioClient: dioClient,
        syncBox: box,
        currentUserId: user ?? () => 1,
      );

  test('silme kaydı DELETE ile gider, POST edilmez, başarıda kuyruktan çıkar', () async {
    when(() => dio.delete<Map<String, dynamic>>(any())).thenAnswer(
      (inv) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: inv.positionalArguments.first as String),
        statusCode: 200,
      ),
    );
    final box = await Hive.openBox<String>(SyncManager.boxName);
    final manager = managerFor(box);

    await manager.addToQueue('/nutrition/meal-logs/items/7', <String, dynamic>{}, method: SyncManager.methodDelete);
    await manager.syncPendingData();

    verify(() => dio.delete<Map<String, dynamic>>('/nutrition/meal-logs/items/7')).called(1);
    verifyNever(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')));
    expect(box.isEmpty, isTrue);
  });

  test('silinecek kayıt sunucuda zaten yoksa (404) silme başarılı sayılır, ret listesine girmez', () async {
    when(() => dio.delete<Map<String, dynamic>>(any())).thenThrow(
      httpError('/nutrition/meal-logs/items/7', 404, message: 'Öğün öğesi bulunamadı: 7'),
    );
    final box = await Hive.openBox<String>(SyncManager.boxName);
    final manager = managerFor(box);

    await manager.addToQueue('/nutrition/meal-logs/items/7', <String, dynamic>{}, method: SyncManager.methodDelete);
    await manager.syncPendingData();

    expect(box.isEmpty, isTrue);
    expect(manager.rejectedCount.value, equals(0));
  });

  test('başkasının kalemini silme (400) aktarılamadı olarak kalır', () async {
    when(() => dio.delete<Map<String, dynamic>>(any())).thenThrow(
      httpError('/nutrition/meal-logs/items/7', 400, message: 'Bu kayıt size ait değil!'),
    );
    final box = await Hive.openBox<String>(SyncManager.boxName);
    final manager = managerFor(box);

    await manager.addToQueue('/nutrition/meal-logs/items/7', <String, dynamic>{}, method: SyncManager.methodDelete);
    await manager.syncPendingData();

    final item = jsonDecode(box.values.single) as Map<String, dynamic>;
    expect(item['status'], equals('rejected'));
    expect(manager.rejectedCount.value, equals(1));
  });

  test('önizleme cihazda kalır, sunucuya yalnızca yük gider', () async {
    final box = await Hive.openBox<String>(SyncManager.boxName);
    final manager = managerFor(box);

    await manager.addToQueue(
      '/kayit',
      <String, dynamic>{'a': 1},
      preview: <Map<String, dynamic>>[
        <String, dynamic>{'foodName': 'Yulaf', 'localId': 'L1'},
      ],
    );

    expect(manager.pendingRecords().single.preview.single['foodName'], equals('Yulaf'));

    await manager.syncPendingData();

    verify(() => dio.post<Map<String, dynamic>>('/kayit', data: <String, dynamic>{'a': 1})).called(1);
    expect(box.isEmpty, isTrue);
  });

  test('bekleyen kayıtlar yalnızca oturumdaki kullanıcının reddedilmemiş kayıtlarıdır', () async {
    final box = await Hive.openBox<String>(SyncManager.boxName);
    final manager = managerFor(box);

    await box.put('w1', jsonEncode(<String, dynamic>{
      'id': 'w1',
      'endpoint': '/nutrition/meal-logs/items/7',
      'method': 'DELETE',
      'payload': <String, dynamic>{},
      'timestamp': '2026-09-18T08:00:00Z',
      'ownerId': 1,
    }));
    await box.put('r1', jsonEncode(<String, dynamic>{
      'id': 'r1',
      'endpoint': '/r1',
      'payload': <String, dynamic>{},
      'timestamp': '2026-09-18T08:00:00Z',
      'ownerId': 1,
      'status': 'rejected',
      'reason': 'x',
    }));
    await box.put('o1', jsonEncode(<String, dynamic>{
      'id': 'o1',
      'endpoint': '/o1',
      'payload': <String, dynamic>{},
      'timestamp': '2026-09-18T08:00:00Z',
      'ownerId': 2,
    }));

    final List<PendingRecord> pending = manager.pendingRecords();

    expect(pending.map((PendingRecord r) => r.key).toList(), equals(<String>['w1']));
    expect(pending.single.method, equals(SyncManager.methodDelete));
  });

  test('bekleyen kayıttan tek kalem çıkar, son kalem çıkınca kayıt silinir, diğer kayıt kalır', () async {
    final box = await Hive.openBox<String>(SyncManager.boxName);
    final manager = managerFor(box);

    await manager.addToQueue(
      '/nutrition/meal-logs/log',
      <String, dynamic>{
        'mealType': 'KAHVALTI',
        'items': <Map<String, dynamic>>[
          <String, dynamic>{'foodId': 5, 'localId': 'L1'},
          <String, dynamic>{'foodId': 6, 'localId': 'L2'},
        ],
      },
      preview: <Map<String, dynamic>>[
        <String, dynamic>{'foodName': 'Yulaf', 'localId': 'L1'},
        <String, dynamic>{'foodName': 'Süt', 'localId': 'L2'},
      ],
    );
    await manager.addToQueue('/baska', <String, dynamic>{});
    final String mealKey = manager.pendingRecords().firstWhere((PendingRecord r) => r.endpoint != '/baska').key;

    await manager.removeQueuedItem(mealKey, 'L1');

    final Map<String, dynamic> meal = jsonDecode(box.get(mealKey)!) as Map<String, dynamic>;
    final List<dynamic> items = (meal['payload'] as Map<String, dynamic>)['items'] as List<dynamic>;
    expect(items.map((dynamic e) => (e as Map<String, dynamic>)['localId']).toList(), equals(<String>['L2']));
    expect(((meal['preview'] as List<dynamic>).single as Map<String, dynamic>)['foodName'], equals('Süt'));

    await manager.removeQueuedItem(mealKey, 'L2');

    expect(box.containsKey(mealKey), isFalse);
    expect(box.length, equals(1));
  });

  // --- K2-08 (G-84): kuyruk eklenme sırasıyla işlenir ---

  Future<void> putRecord(Box<String> box, String key, String endpoint, String timestamp) => box.put(
        key,
        jsonEncode(<String, dynamic>{
          'id': key,
          'endpoint': endpoint,
          'payload': <String, dynamic>{},
          'timestamp': timestamp,
          'ownerId': 1,
        }),
      );

  test('kayıtlar anahtar sırasıyla değil eklenme sırasıyla gönderilir', () async {
    final box = await Hive.openBox<String>(SyncManager.boxName);
    final manager = managerFor(box);
    // Anahtarların sözlük sırası (a, b) eklenme sırasının (b, a) tersi.
    await putRecord(box, 'b', '/ilk-mesaj', '2026-09-18T08:00:00.000');
    await putRecord(box, 'a', '/ikinci-mesaj', '2026-09-18T08:00:05.000');

    await manager.syncPendingData();

    verifyInOrder(<void Function()>[
      () => dio.post<Map<String, dynamic>>('/ilk-mesaj', data: any(named: 'data')),
      () => dio.post<Map<String, dynamic>>('/ikinci-mesaj', data: any(named: 'data')),
    ]);
  });

  test('bekleyen kayıtlar eklenme sırasıyla listelenir', () async {
    final box = await Hive.openBox<String>(SyncManager.boxName);
    final manager = managerFor(box);
    await putRecord(box, 'b', '/ilk', '2026-09-18T08:00:00.000');
    await putRecord(box, 'a', '/ikinci', '2026-09-18T08:00:05.000');

    expect(manager.pendingRecords().map((PendingRecord r) => r.endpoint).toList(), equals(<String>['/ilk', '/ikinci']));
  });

  // --- G-74: kişisel program kuyruğu (PUT, yük değiştirme, gönderim kilidi, gönderim sayacı) ---

  test('düzenleme kaydı PUT ile gider, POST edilmez, başarıda kuyruktan çıkar', () async {
    when(() => dio.put<Map<String, dynamic>>(any(), data: any(named: 'data'))).thenAnswer(
      (inv) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: inv.positionalArguments.first as String),
        statusCode: 200,
      ),
    );
    final box = await Hive.openBox<String>(SyncManager.boxName);
    final manager = managerFor(box);

    await manager.addToQueue('/training/programs/personal/7', <String, dynamic>{'name': 'Yeni'},
        method: SyncManager.methodPut);
    await manager.syncPendingData();

    verify(() => dio.put<Map<String, dynamic>>('/training/programs/personal/7', data: <String, dynamic>{'name': 'Yeni'}))
        .called(1);
    verifyNever(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')));
    expect(box.isEmpty, isTrue);
  });

  test('bekleyen kaydın yükü değişir, kuyruktaki yeri korunur; gönderilmiş kaydın yükü değişmez', () async {
    final box = await Hive.openBox<String>(SyncManager.boxName);
    final manager = managerFor(box);
    await putRecord(box, 'b', '/program', '2026-09-23T08:00:00.000');
    await putRecord(box, 'a', '/sonraki', '2026-09-23T08:00:05.000');

    final bool replaced = await manager.replacePayload('b', <String, dynamic>{'name': 'Düzenlendi'});
    await manager.syncPendingData();

    expect(replaced, isTrue);
    verifyInOrder(<void Function()>[
      () => dio.post<Map<String, dynamic>>('/program', data: <String, dynamic>{'name': 'Düzenlendi'}),
      () => dio.post<Map<String, dynamic>>('/sonraki', data: any(named: 'data')),
    ]);
    expect(await manager.replacePayload('b', <String, dynamic>{'name': 'Geç'}), isFalse);
    expect(box.isEmpty, isTrue);
  });

  test('bekleyen kayıt kullanıcı isteğiyle çıkarılır, diğer kayıt kalır', () async {
    final box = await Hive.openBox<String>(SyncManager.boxName);
    final manager = managerFor(box);
    await putRecord(box, 'a', '/program', '2026-09-23T08:00:00.000');
    await putRecord(box, 'b', '/baska', '2026-09-23T08:00:05.000');

    expect(await manager.removePending('a'), isTrue);
    expect(await manager.removePending('a'), isFalse);

    expect(box.keys.toList(), equals(<String>['b']));
  });

  test('gönderilmekte olan kayıt değiştirilemez ve çıkarılamaz; gönderilen yük gider, kayıt sonra silinir', () async {
    final Completer<Response<Map<String, dynamic>>> inFlight = Completer<Response<Map<String, dynamic>>>();
    when(() => dio.post<Map<String, dynamic>>('/program', data: any(named: 'data')))
        .thenAnswer((_) => inFlight.future);
    final box = await Hive.openBox<String>(SyncManager.boxName);
    final manager = managerFor(box);
    await putRecord(box, 'a', '/program', '2026-09-23T08:00:00.000');

    final Future<void> sync = manager.syncPendingData();
    await Future<void>.delayed(Duration.zero);

    expect(await manager.replacePayload('a', <String, dynamic>{'name': 'Geç düzenleme'}), isFalse);
    expect(await manager.removePending('a'), isFalse);
    final Map<String, dynamic> stored = jsonDecode(box.get('a')!) as Map<String, dynamic>;
    expect(stored['payload'], equals(<String, dynamic>{}));

    inFlight.complete(Response<Map<String, dynamic>>(requestOptions: RequestOptions(path: '/program'), statusCode: 200));
    await sync;

    expect(box.isEmpty, isTrue);
    expect(await manager.replacePayload('a', <String, dynamic>{'name': 'Geç düzenleme'}), isFalse);
  });

  test('gönderim turu kayıt ulaştırınca sayaç artar; hiçbir kayıt gitmezse artmaz', () async {
    final box = await Hive.openBox<String>(SyncManager.boxName);
    final manager = managerFor(box);
    await manager.addToQueue('/program', <String, dynamic>{});

    await manager.syncPendingData();
    expect(manager.sentCount.value, equals(1));

    when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')))
        .thenThrow(httpError('/program', 503, message: 'Bakımda'));
    await manager.addToQueue('/program', <String, dynamic>{});
    await manager.syncPendingData();

    expect(manager.sentCount.value, equals(1));
    expect(box.length, equals(1));
  });
}
