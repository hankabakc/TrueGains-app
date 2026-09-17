import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/core/network/offline_cache.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';
import 'package:gymapp_v2/features/nutrition/data/services/food_api_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class _FakeDioClient implements DioClient {
  @override
  Dio dio;

  _FakeDioClient(this.dio);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Yol başına cevap verir; `offline` açıkken her istek bağlantı hatasıyla düşer.
class _PathAdapter implements HttpClientAdapter {
  final Map<String, (int, Map<String, dynamic>)> replies = <String, (int, Map<String, dynamic>)>{};
  bool offline = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (offline) {
      throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
    }
    final (int, Map<String, dynamic>) reply = replies[options.path]!;
    return ResponseBody.fromString(
      jsonEncode(reply.$2),
      reply.$1,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// İnternetsiz besin arama (G-71, KR16): telefondaki katalogda aranır; sunucunun verdiği hata maskelenmez.
void main() {
  late Directory tempDir;
  late _PathAdapter adapter;
  late FoodApiService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('food_offline_test');
    Hive.init(tempDir.path);
    await Hive.openBox<String>(OfflineCache.boxName);

    adapter = _PathAdapter();
    adapter.replies['/nutrition/foods/catalog'] = (200, <String, dynamic>{
      'success': true,
      'message': 'Besin kataloğu listelendi.',
      'timestamp': '2026-09-16T00:00:00Z',
      'data': <Map<String, dynamic>>[
        <String, dynamic>{'id': 1, 'name': 'Yulaf Ezmesi', 'brand': 'Eti'},
        <String, dynamic>{'id': 2, 'name': 'Mercimek', 'brand': null},
        <String, dynamic>{'id': 3, 'name': 'Ayran', 'brand': 'Sütaş'},
      ],
    });
    final Dio dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(OfflineCacheInterceptor(OfflineCache()));
    service = FoodApiService(_FakeDioClient(dio));
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('internetsizken arama telefondaki katalogda ada ve markaya göre yapılır', () async {
    expect((await service.getCatalog()).success, isTrue);
    adapter.offline = true;

    final byName = await service.searchFood('yulaf');
    final byBrand = await service.searchFood('sütaş');

    expect(byName.success, isTrue);
    expect(byName.data!.map((FoodModel f) => f.name).toList(), equals(<String>['Yulaf Ezmesi']));
    expect(byBrand.data!.map((FoodModel f) => f.name).toList(), equals(<String>['Ayran']));
  });

  test('katalog hiç inmemişse internetsiz arama başarısız döner', () async {
    adapter.offline = true;
    final result = await service.searchFood('yulaf');
    expect(result.success, isFalse);
  });

  test('sunucu cevap verip hata döndüyse katalogda aranmaz', () async {
    await service.getCatalog();
    adapter.replies['/nutrition/foods/search'] = (500, <String, dynamic>{
      'success': false,
      'message': 'Sunucu hatası',
      'timestamp': '2026-09-16T00:00:00Z',
    });
    final result = await service.searchFood('yulaf');
    expect(result.success, isFalse);
  });
}
