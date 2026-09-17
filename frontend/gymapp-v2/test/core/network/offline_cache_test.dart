import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/cache_status.dart';
import 'package:gymapp_v2/core/network/offline_cache.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Ağ katmanını taklit eden adaptör: ya gövde döndürür ya da verilen hatayı fırlatır.
class _FakeAdapter implements HttpClientAdapter {
  /// Üretimde `IOHttpClientAdapter`, `SocketException`'ı isteğin **kendi**
  /// `RequestOptions`'ı ile `connectionError`'a çevirir. Sahte adaptör de aynısını
  /// yapmalı: sabit bir options ile fırlatılan hata, önbellek anahtarını yanlış
  /// yola bağlar ve testi gerçekte olmayan bir hataya inandırır.
  DioExceptionType? failureType;
  Map<String, dynamic> body = const <String, dynamic>{};
  int statusCode = 200;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    if (failureType != null) {
      throw DioException(requestOptions: options, type: failureType!);
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Çevrimdışı okuma önbelleği (E1 + E3).
///
/// Buradaki en pahalı hata "eski veri gösterildi" değil, **yetki hatasının eski
/// veriyle maskelenmesidir**: 403 dönen bir uç önbellekten cevaplanırsa, erişimi
/// kesilmiş kullanıcı veriyi görmeye devam eder.
void main() {
  late Directory tempDir;
  late _FakeAdapter adapter;
  late Dio dio;

  const DioExceptionType offline = DioExceptionType.connectionError;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('offline_cache_test');
    Hive.init(tempDir.path);
    await Hive.openBox<String>(OfflineCache.boxName);

    adapter = _FakeAdapter();
    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(OfflineCacheInterceptor(OfflineCache()));
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('çevrimdışıyken son başarılı yanıt dönüyor', () async {
    adapter.body = {'success': true, 'data': 'ilk hâl'};
    await dio.get<Map<String, dynamic>>('/social/chat/conversations');

    adapter.failureType = offline;
    final response = await dio.get<Map<String, dynamic>>('/social/chat/conversations');

    expect(response.data!['data'], 'ilk hâl');
  });

  test('hiç önbelleğe alınmamış uç çevrimdışıyken hata veriyor', () async {
    adapter.failureType = offline;

    expect(
      () => dio.get<Map<String, dynamic>>('/training/programs'),
      throwsA(isA<DioException>()),
    );
  });

  test('sunucu hatası önbellekle maskelenmiyor', () async {
    adapter.body = {'success': true, 'data': 'gizli veri'};
    await dio.get<Map<String, dynamic>>('/social/chat/messages/10');

    // Erişim kesildi: sunucu 403 dönüyor. Önbellek bunu yutup veriyi göstermemeli.
    adapter.statusCode = 403;
    adapter.body = {'success': false, 'message': 'Yetkisiz'};

    await expectLater(
      dio.get<Map<String, dynamic>>('/social/chat/messages/10'),
      throwsA(
        isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 403),
      ),
    );
  });

  test('POST yanıtı cihazda saklanmıyor', () async {
    // Girişin yanıtı bir POST gövdesidir ve içinde token taşır. GET filtresi
    // olmasaydı bu gövde diske yazılırdı.
    adapter.body = {
      'success': true,
      'data': {'accessToken': 'gizli-token'},
    };
    await dio.post<Map<String, dynamic>>('/auth/login');

    expect(Hive.box<String>(OfflineCache.boxName).keys, isEmpty);
  });

  test('POST çevrimdışıyken önbellekten cevaplanmıyor', () async {
    adapter.body = {'success': true, 'data': 'gönderildi'};
    await dio.post<Map<String, dynamic>>('/social/chat/send');

    adapter.failureType = offline;

    await expectLater(
      dio.post<Map<String, dynamic>>('/social/chat/send'),
      throwsA(isA<DioException>()),
    );
  });

  test('sorgu parametreleri farklı sayfaları birbirine karıştırmıyor', () async {
    adapter.body = {'data': 'sayfa 0'};
    await dio.get<Map<String, dynamic>>('/list', queryParameters: {'page': 0});
    adapter.body = {'data': 'sayfa 1'};
    await dio.get<Map<String, dynamic>>('/list', queryParameters: {'page': 1});

    adapter.failureType = offline;
    final first = await dio.get<Map<String, dynamic>>('/list', queryParameters: {'page': 0});

    expect(first.data!['data'], 'sayfa 0');
  });

  test('kutu tavana dayanınca büyümeyi bırakıyor ama çalışmaya devam ediyor', () async {
    adapter.body = {'data': 'x'};
    for (int i = 0; i <= OfflineCache.maxEntries; i++) {
      await dio.get<Map<String, dynamic>>('/list', queryParameters: {'q': i});
    }

    final box = Hive.box<String>(OfflineCache.boxName);
    expect(box.length, lessThanOrEqualTo(OfflineCache.maxEntries));

    // Tavan aşıldıktan sonra da yazma çalışmalı: sayaç ters kurulursa önbellek
    // sessizce devre dışı kalır ve hiçbir test bunu fark etmez.
    adapter.body = {'data': 'son'};
    await dio.get<Map<String, dynamic>>('/list', queryParameters: {'q': 'son'});
    adapter.failureType = offline;
    final cached = await dio.get<Map<String, dynamic>>('/list', queryParameters: {'q': 'son'});

    expect(cached.data!['data'], 'son');
  });

  test('tavan dolunca referans verisi (besin kataloğu, egzersizler) silinmez', () async {
    adapter.body = {'success': true, 'data': ['katalog']};
    await dio.get<Map<String, dynamic>>('/nutrition/foods/catalog');
    adapter.body = {'success': true, 'data': ['egzersiz']};
    await dio.get<Map<String, dynamic>>('/training/exercises');

    adapter.body = {'data': 'x'};
    for (int i = 0; i <= OfflineCache.maxEntries; i++) {
      await dio.get<Map<String, dynamic>>('/list', queryParameters: {'q': i});
    }

    adapter.failureType = offline;
    final catalog = await dio.get<Map<String, dynamic>>('/nutrition/foods/catalog');
    final exercises = await dio.get<Map<String, dynamic>>('/training/exercises');

    expect(catalog.data!['data'], ['katalog']);
    expect(exercises.data!['data'], ['egzersiz']);
  });

  test('bağlantı gelince sunucudan gelen taze veri önbelleğin yerine geçiyor', () async {
    adapter.body = {'data': 'eski'};
    await dio.get<Map<String, dynamic>>('/list');

    adapter.body = {'data': 'yeni'};
    final response = await dio.get<Map<String, dynamic>>('/list');
    expect(response.data!['data'], 'yeni');

    adapter.failureType = offline;
    final cached = await dio.get<Map<String, dynamic>>('/list');
    expect(cached.data!['data'], 'yeni');
  });

  test('yazma zamanı okunuyor', () async {
    final cache = OfflineCache();
    await cache.write('/profile', {'name': 'Ali'});
    final cachedAt = cache.readCachedAt('/profile');

    expect(cachedAt, isNotNull);
    final now = DateTime.now();
    expect(cachedAt!.year, now.year);
    expect(cachedAt.month, now.month);
    expect(cachedAt.day, now.day);
  });

  test('eski biçimli kayıt hâlâ okunuyor', () async {
    final box = Hive.box<String>(OfflineCache.boxName);
    await box.put('/old', jsonEncode({'a': 1}));

    final cache = OfflineCache();
    final data = cache.read('/old');
    final cachedAt = cache.readCachedAt('/old');

    expect(data, {'a': 1});
    expect(cachedAt, isNull);
  });

  test('bildirici doluyor ve taze yanıtta temizleniyor', () async {
    final notifier = CacheStatusNotifier();
    final testDio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(OfflineCacheInterceptor(OfflineCache(), notifier));

    adapter.body = {'data': 'ilk'};
    await testDio.get<Map<String, dynamic>>('/test-status');
    expect(notifier.value, isNull);

    adapter.failureType = offline;
    final cached = await testDio.get<Map<String, dynamic>>('/test-status');
    expect(cached.data!['data'], 'ilk');
    expect(notifier.value, isNotNull);

    adapter.failureType = null;
    adapter.body = {'data': 'ikinci'};
    await testDio.get<Map<String, dynamic>>('/test-status');
    expect(notifier.value, isNull);
  });

  test('clear kutudaki bütün kayıtları siler', () async {
    final cache = OfflineCache();
    await cache.write('/profile', {'name': 'Ali'});
    await cache.write('/social/chat/conversations', ['sohbet']);

    await cache.clear();

    expect(Hive.box<String>(OfflineCache.boxName).isEmpty, isTrue);
    expect(cache.read('/profile'), isNull);
  });
}
