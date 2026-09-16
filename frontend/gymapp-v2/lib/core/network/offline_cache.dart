import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gymapp_v2/core/constants/storage_keys.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'cache_status.dart';

/// Başarılı `GET` yanıtlarının cihazdaki son bilinen hâli.
///
/// Yazma kuyruğu (`sync_queue`) çevrimdışı **yazmayı** taşıyordu; burası çevrimdışı
/// **okumayı** taşır. Aynı desen: tek Hive kutusu, tek biçim (JSON metin). Model
/// başına `toJson` yazmamak için sunucudan gelen ham gövde saklanır.
class OfflineCache {
  static const String boxName = 'offline_cache';

  /// ponytail: kaba tavan. Serbest metinli uçlar (besin arama gibi) her sorgu için
  /// yeni anahtar üretir; sınır aşılınca kutu tamamen boşaltılır. Gerçek LRU
  /// gerekirse her kayda erişim zamanı eklenmeli.
  static const int maxEntries = 200;

  /// Kutu her erişimde aranır: böylece önbellek, açılış sırasına bağımlılık
  /// kurmadan (kutu henüz açılmamışsa sessizce devre dışı) çalışır.
  Box<String>? get _box => Hive.isBoxOpen(boxName) ? Hive.box<String>(boxName) : null;

  static String keyFor(RequestOptions options) {
    final List<String> query = options.queryParameters.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .toList()
      ..sort();
    return '${options.path}?${query.join('&')}';
  }

  Future<void> write(String key, Object? data) async {
    final Box<String>? box = _box;
    if (box == null || data == null) return;
    if (box.length >= maxEntries && !box.containsKey(key)) {
      await box.clear();
    }
    await box.put(key, jsonEncode({'t': DateTime.now().toIso8601String(), 'd': data}));
  }

  dynamic read(String key) {
    final String? raw = _box?.get(key);
    if (raw == null) return null;
    final dynamic decoded = jsonDecode(raw);
    if (decoded is Map && decoded.containsKey('t') && decoded.containsKey('d')) {
      return decoded['d'];
    }
    return decoded;
  }

  /// Kaydın yazıldığı an; eski biçimli kayıtlarda bilinmez (null).
  DateTime? readCachedAt(String key) {
    final String? raw = _box?.get(key);
    if (raw == null) return null;
    final dynamic decoded = jsonDecode(raw);
    if (decoded is Map && decoded.containsKey('t')) {
      final dynamic t = decoded['t'];
      if (t is String) {
        return DateTime.tryParse(t);
      }
    }
    return null;
  }

  Future<void> clear() async {
    await _box?.clear();
  }
}

/// Önbellek kutusunu şifreli olarak açar.
///
/// Kutuda mesaj içeriği ve ölçüm gibi kişisel veri birikiyor; sunucuda AES ile
/// korunan alanların cihazda düz metin durmaması için kutu da şifrelenir. Anahtar
/// `FlutterSecureStorage`'ta (Android Keystore) tutulur.
Future<void> openOfflineCacheBox(FlutterSecureStorage storage) async {
  final List<int> key = await _readOrCreateCacheKey(storage);
  try {
    await Hive.openBox<String>(
      OfflineCache.boxName,
      encryptionCipher: HiveAesCipher(key),
    );
  } catch (_) {
    // Anahtar kaybolduysa/değiştiyse eski kutu okunamaz. Önbellek atılabilir veri:
    // sunucudan yeniden gelir, bu yüzden silip yeniden açmak doğru davranıştır.
    await Hive.deleteBoxFromDisk(OfflineCache.boxName);
    await Hive.openBox<String>(
      OfflineCache.boxName,
      encryptionCipher: HiveAesCipher(key),
    );
  }
}

Future<List<int>> _readOrCreateCacheKey(FlutterSecureStorage storage) async {
  final String? existing = await storage.read(key: StorageKeys.offlineCacheKey);
  if (existing != null) return base64Decode(existing);

  final List<int> key = Hive.generateSecureKey();
  await storage.write(key: StorageKeys.offlineCacheKey, value: base64Encode(key));
  return key;
}

/// Başarılı `GET` yanıtlarını saklar, bağlantı yokken son bilinen hâli döndürür.
class OfflineCacheInterceptor extends Interceptor {
  final OfflineCache _cache;
  final CacheStatusNotifier? _status;

  OfflineCacheInterceptor(this._cache, [this._status]);

  /// Yalnızca "sunucuya ulaşılamadı" hâlleri. Sunucunun **verdiği** hatalar
  /// (401/403/404/500) önbellekten cevaplanmaz: erişimi kesilmiş kullanıcıya eski
  /// veriyi göstermek, hata mesajı göstermekten çok daha pahalıdır.
  static const Set<DioExceptionType> _unreachable = {
    DioExceptionType.connectionError,
    DioExceptionType.connectionTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.sendTimeout,
  };

  /// Sunucuya hiç ulaşılamadı mı (cevap yok). Oturum geri yükleme de aynı tanımı kullanır (KR15).
  static bool isUnreachable(DioException err) => _unreachable.contains(err.type);

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) async {
    _status?.markFresh();
    if (_isCacheable(response)) {
      await _cache.write(OfflineCache.keyFor(response.requestOptions), response.data);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.requestOptions.method != 'GET' || !isUnreachable(err)) {
      handler.next(err);
      return;
    }

    final dynamic cached = _cache.read(OfflineCache.keyFor(err.requestOptions));
    if (cached == null) {
      handler.next(err);
      return;
    }

    _status?.markStale(_cache.readCachedAt(OfflineCache.keyFor(err.requestOptions)));

    handler.resolve(
      Response<dynamic>(
        requestOptions: err.requestOptions,
        data: cached,
        statusCode: 200,
      ),
    );
  }

  bool _isCacheable(Response<dynamic> response) {
    return response.requestOptions.method == 'GET' &&
        response.statusCode == 200 &&
        (response.data is Map || response.data is List);
  }
}
