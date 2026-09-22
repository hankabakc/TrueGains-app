import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gymapp_v2/core/constants/storage_keys.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/core/network/network_info.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Sunucunun kalıcı olarak reddettiği kuyruk kaydı (G-69).
class RejectedRecord extends Equatable {
  final String key;
  final String endpoint;
  final String reason;
  final DateTime? createdAt;

  /// Yükteki cihaz kimliği (G-79); mesaj balonu reddedilen kaydını bununla bulur (G-80). Yükte yoksa null.
  final String? localId;

  const RejectedRecord({required this.key, required this.endpoint, required this.reason, this.createdAt, this.localId});

  @override
  List<Object?> get props => [key, endpoint, reason, createdAt, localId];
}

/// Gönderilmeyi bekleyen (reddedilmemiş) kuyruk kaydı (G-83); günlük ekranı bekleyen öğünü ve silmeyi buradan okur.
class PendingRecord {
  final String key;
  final String endpoint;
  final String method;
  final Map<String, dynamic> payload;

  /// Yalnızca cihazdaki gösterim için (ad, besin değerleri); sunucuya gönderilmez.
  final List<Map<String, dynamic>> preview;

  const PendingRecord({
    required this.key,
    required this.endpoint,
    required this.method,
    required this.payload,
    this.preview = const <Map<String, dynamic>>[],
  });
}

/// Çevrimdışı yazma kuyruğu: bağlantı yokken yapılan istekleri saklar, bağlantı gelince gönderir.
///
/// Kayıt kime aitse yalnızca o kullanıcının oturumunda gönderilir; başkasının kaydına
/// dokunulmaz. Gönderilen kayıt dışında hiçbir kayıt silinmez.
class SyncManager {
  /// Şifreli kuyruk kutusu.
  static const String boxName = 'sync_queue_secure';

  /// G-68 öncesi şifresiz kutu; açılışta [boxName]'e taşınır.
  static const String legacyBoxName = 'sync_queue';

  /// Kalıcı ret sayılan durum kodları: aynı istek her denemede aynı cevabı alır. Geri kalan her şey
  /// (bağlantı yok, zaman aşımı, 401, 408, 429, 5xx) geçicidir; kayıt bekler, kendiliğinden yeniden denenir.
  static const Set<int> permanentStatusCodes = {400, 403, 404, 409, 422};

  static const String methodPost = 'POST';
  static const String methodDelete = 'DELETE';

  static const String _statusRejected = 'rejected';
  static const String _defaultReason = 'Sunucu bu kaydı kabul etmedi.';

  final NetworkInfo networkInfo;
  final DioClient dioClient;
  final Box<String> syncBox;

  /// O an oturum açmış kullanıcının kimliği; oturum yoksa null.
  final int? Function() currentUserId;

  /// Oturumdaki kullanıcının sunucuya aktarılamayan (reddedilen) kayıt sayısı; şerit bunu dinler.
  final ValueNotifier<int> rejectedCount = ValueNotifier<int>(0);

  /// Gönderim sürerken gelen ikinci çağrı beklemez, hemen döner; aynı kayıt iki kez gitmez.
  bool _isSyncing = false;

  SyncManager({
    required this.networkInfo,
    required this.dioClient,
    required this.syncBox,
    required this.currentUserId,
  }) {
    // İnternet bağlantısı değiştiğinde eşitlemeyi tetikle
    networkInfo.onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        syncPendingData();
      }
    });
  }

  /// Kalıcı ret mi: sunucu isteği okudu ve kabul etmedi.
  static bool isPermanentRejection(DioException e) {
    final int? status = e.response?.statusCode;
    return e.type == DioExceptionType.badResponse && status != null && permanentStatusCodes.contains(status);
  }

  static String _reasonOf(DioException e) {
    final Object? data = e.response?.data;
    if (data is Map && data['message'] is String && (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    return _defaultReason;
  }

  /// Çevrimdışı veriyi kuyruğa ekler; kayıt o an oturum açmış kullanıcıya ait işaretlenir.
  /// [preview] yalnızca cihazda gösterilir, gönderilmez (G-83).
  Future<void> addToQueue(
    String endpoint,
    Map<String, dynamic> payload, {
    String method = methodPost,
    List<Map<String, dynamic>> preview = const <Map<String, dynamic>>[],
  }) async {
    final String id = const Uuid().v4();
    final Map<String, dynamic> queueItem = {
      'id': id,
      'endpoint': endpoint,
      'method': method,
      'payload': payload,
      if (preview.isNotEmpty) 'preview': preview,
      'timestamp': DateTime.now().toIso8601String(),
      'ownerId': currentUserId(),
    };

    await syncBox.put(id, jsonEncode(queueItem));
  }

  /// Kuyrukta bekleyen, oturumdaki kullanıcıya ait kayıtları gönderir. Reddedilen kayıt atlanır.
  Future<void> syncPendingData() async {
    // ponytail: süren gönderim sırasında eklenen kayıt bir sonraki tetiklemede gider.
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      if (syncBox.isEmpty) return;

      final int? owner = currentUserId();
      if (owner == null) return;

      final bool isConnected = await networkInfo.isConnected;
      if (!isConnected) return;

      final List<String> keys = _keysInQueueOrder();

      for (final key in keys) {
        final String? rawData = syncBox.get(key);
        if (rawData == null) continue;

        Map<String, dynamic>? item;
        try {
          item = jsonDecode(rawData) as Map<String, dynamic>;

          // ponytail: sahibi olmayan kayıt yalnızca G-68 öncesi kurulumdan taşınmış olabilir
          // (üretimde kurulum yok); oturumdaki kullanıcıyla gönderilir.
          final Object? itemOwner = item['ownerId'];
          if (itemOwner != null && itemOwner != owner) continue;

          // Reddedilen kayıt kendiliğinden denenmez: aynı istek aynı cevabı alır. Kullanıcı "Tekrar dene" der.
          if (item['status'] == _statusRejected) continue;

          final String endpoint = item['endpoint'] as String;
          final Map<String, dynamic> payload = item['payload'] as Map<String, dynamic>;

          final response = _methodOf(item) == methodDelete
              ? await dioClient.dio.delete<Map<String, dynamic>>(endpoint)
              : await dioClient.dio.post<Map<String, dynamic>>(endpoint, data: payload);

          if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
            await syncBox.delete(key);
          }
        } on DioException catch (e) {
          // G-83: silinecek kayıt sunucuda zaten yoksa silme amacına ulaşmıştır; ret değil.
          if (item != null && _methodOf(item) == methodDelete && e.response?.statusCode == 404) {
            await syncBox.delete(key);
          } else if (item != null && isPermanentRejection(e)) {
            item['status'] = _statusRejected;
            item['reason'] = _reasonOf(e);
            await syncBox.put(key, jsonEncode(item));
          }
          // Geçici hata: kayıt olduğu gibi bekler, sonraki tetiklemede yeniden denenir.
        } catch (e) {
          // Bozuk kayıt ya da beklenmeyen hata: kayıt kuyrukta kalır.
        }
      }
    } finally {
      _isSyncing = false;
      refreshRejectedCount();
    }
  }

  /// Kayıt yöntemi; G-83 öncesi kayıtlarda alan yok, hepsi POST'tu.
  static String _methodOf(Map<String, dynamic> item) => (item['method'] as String?) ?? methodPost;

  /// Kuyruk anahtarları eklenme sırasıyla (K2-08). Anahtar rastgele UUID ve Hive dize anahtarları sözlük sırasıyla
  /// döndürür; sıra kayıttaki zaman damgasından gelir. Aynı öğünün iki işareti ve art arda yazılan mesajlar bu sırayla gider.
  // ponytail: aynı mikrosaniyedeki iki kaydın sırası belirsiz; olursa kayda sıra sayacı eklenir.
  List<String> _keysInQueueOrder() {
    final Map<String, DateTime> addedAt = <String, DateTime>{};
    for (final dynamic key in syncBox.keys) {
      DateTime at = DateTime(0);
      try {
        final Object? decoded = jsonDecode(syncBox.get(key) ?? '{}');
        if (decoded is Map<String, dynamic>) {
          at = DateTime.tryParse((decoded['timestamp'] as String?) ?? '') ?? at;
        }
      } on FormatException {
        // Bozuk kayıt en başa düşer; gönderimde yine atlanır.
      }
      addedAt[key as String] = at;
    }
    return addedAt.keys.toList()..sort((String a, String b) => addedAt[a]!.compareTo(addedAt[b]!));
  }

  /// Oturumdaki kullanıcının okunabilen kuyruk kayıtları (anahtar → kayıt), eklenme sırasıyla.
  List<MapEntry<String, Map<String, dynamic>>> _ownItems() {
    final int? owner = currentUserId();
    if (owner == null) return const <MapEntry<String, Map<String, dynamic>>>[];

    final List<MapEntry<String, Map<String, dynamic>>> items = <MapEntry<String, Map<String, dynamic>>>[];
    for (final String key in _keysInQueueOrder()) {
      final String? raw = syncBox.get(key);
      if (raw == null) continue;
      try {
        final Map<String, dynamic> item = jsonDecode(raw) as Map<String, dynamic>;
        final Object? itemOwner = item['ownerId'];
        if (itemOwner != null && itemOwner != owner) continue;
        items.add(MapEntry<String, Map<String, dynamic>>(key, item));
      } on FormatException {
        continue;
      }
    }
    return items;
  }

  /// Oturumdaki kullanıcının reddedilen kayıtları, eskiden yeniye.
  List<RejectedRecord> rejectedRecords() {
    final List<RejectedRecord> records = <RejectedRecord>[
      for (final MapEntry<String, Map<String, dynamic>> e in _ownItems())
        if (e.value['status'] == _statusRejected)
          RejectedRecord(
            key: e.key,
            endpoint: e.value['endpoint'] as String,
            reason: (e.value['reason'] as String?) ?? _defaultReason,
            createdAt: DateTime.tryParse((e.value['timestamp'] as String?) ?? ''),
            localId: (e.value['payload'] as Map<String, dynamic>?)?['localId'] as String?,
          ),
    ];
    records.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
    return records;
  }

  /// Oturumdaki kullanıcının gönderilmeyi bekleyen kayıtları; reddedilenler hariç (G-83).
  List<PendingRecord> pendingRecords() {
    return <PendingRecord>[
      for (final MapEntry<String, Map<String, dynamic>> e in _ownItems())
        if (e.value['status'] != _statusRejected)
          PendingRecord(
            key: e.key,
            endpoint: e.value['endpoint'] as String,
            method: _methodOf(e.value),
            payload: e.value['payload'] as Map<String, dynamic>,
            preview: <Map<String, dynamic>>[
              for (final dynamic p in (e.value['preview'] as List<dynamic>?) ?? const <dynamic>[])
                p as Map<String, dynamic>,
            ],
          ),
    ];
  }

  /// Kullanıcı onayıyla, gönderilmemiş kayıttaki tek kalemi çıkarır; kalem kalmazsa kayıt silinir (G-83).
  // ponytail: gönderim sürerken çıkarılan kalem o turda sunucuya gitmiş olabilir; günlük yeniden yüklenince
  // sunucudaki hâli görünür ve oradan silinir. Veri kaybı yok.
  Future<void> removeQueuedItem(String key, String localId) async {
    final String? raw = syncBox.get(key);
    if (raw == null) return;
    final Map<String, dynamic> item = jsonDecode(raw) as Map<String, dynamic>;
    final Map<String, dynamic> payload = item['payload'] as Map<String, dynamic>;
    bool keep(dynamic e) => (e as Map<String, dynamic>)['localId'] != localId;

    final List<dynamic> items = ((payload['items'] as List<dynamic>?) ?? const <dynamic>[]).where(keep).toList();
    if (items.isEmpty) {
      await syncBox.delete(key);
    } else {
      payload['items'] = items;
      item['preview'] = ((item['preview'] as List<dynamic>?) ?? const <dynamic>[]).where(keep).toList();
      await syncBox.put(key, jsonEncode(item));
    }
  }

  void refreshRejectedCount() {
    rejectedCount.value = rejectedRecords().length;
  }

  /// Kullanıcı "Tekrar dene" dedi: yük hiç değişmeden (aynı localId) yeniden gönderilir.
  Future<void> retry(String key) async {
    final String? raw = syncBox.get(key);
    if (raw == null) return;
    final Map<String, dynamic> item = jsonDecode(raw) as Map<String, dynamic>;
    item.remove('status');
    item.remove('reason');
    await syncBox.put(key, jsonEncode(item));
    await syncPendingData();
    refreshRejectedCount();
  }

  /// Yalnızca kullanıcı onayıyla çağrılır. Kaydı kendiliğinden silen tek yol başarılı gönderimdir.
  Future<void> discard(String key) async {
    await syncBox.delete(key);
    refreshRejectedCount();
  }
}

/// Kuyruk kutusunu şifreli açar; eski şifresiz kutudaki kayıtları silmeden taşır.
///
/// Kuyrukta mesaj içeriği ve antrenman kaydı bekliyor; sunucuda AES ile korunan alanların
/// cihazda düz metin durmaması için kutu şifrelenir (önbellekle aynı gerekçe, offline_cache.dart).
Future<void> openSyncQueueBox(FlutterSecureStorage storage) async {
  final List<int> key = await _readOrCreateQueueKey(storage);
  final Box<String> box = await _openEncryptedQueue(key);

  if (await Hive.boxExists(SyncManager.legacyBoxName)) {
    final Box<String> legacy = await Hive.openBox<String>(SyncManager.legacyBoxName);
    for (final dynamic legacyKey in legacy.keys) {
      final String? raw = legacy.get(legacyKey);
      if (raw != null) {
        await box.put(legacyKey as String, _fixLegacyEndpoint(raw));
      }
    }
    // Bütün kayıtlar şifreli kutuya yazıldıktan sonra: taşıma, silme değil.
    await legacy.deleteFromDisk();
  }
}

Future<Box<String>> _openEncryptedQueue(List<int> key) async {
  try {
    return await Hive.openBox<String>(SyncManager.boxName, encryptionCipher: HiveAesCipher(key));
  } catch (_) {
    // Anahtar kaybolduysa kutu okunamaz; anahtarsız şifreli veri kurtarılamaz
    // (offline_cache.dart ile aynı karar). Silinip yeniden açılır.
    await Hive.deleteBoxFromDisk(SyncManager.boxName);
    return Hive.openBox<String>(SyncManager.boxName, encryptionCipher: HiveAesCipher(key));
  }
}

/// G-68 öncesi kuyruk antrenmanı var olmayan /training/session ucuna yazıyordu (K4-09).
String _fixLegacyEndpoint(String raw) {
  try {
    final Map<String, dynamic> item = jsonDecode(raw) as Map<String, dynamic>;
    if (item['endpoint'] == '/training/session') {
      item['endpoint'] = '/training/sessions';
    }
    return jsonEncode(item);
  } on FormatException {
    return raw;
  }
}

Future<List<int>> _readOrCreateQueueKey(FlutterSecureStorage storage) async {
  final String? existing = await storage.read(key: StorageKeys.syncQueueKey);
  if (existing != null) return base64Decode(existing);

  final List<int> key = Hive.generateSecureKey();
  await storage.write(key: StorageKeys.syncQueueKey, value: base64Encode(key));
  return key;
}
