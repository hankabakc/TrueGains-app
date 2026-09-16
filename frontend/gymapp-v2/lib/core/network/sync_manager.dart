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

  const RejectedRecord({required this.key, required this.endpoint, required this.reason, this.createdAt});

  @override
  List<Object?> get props => [key, endpoint, reason, createdAt];
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
  Future<void> addToQueue(String endpoint, Map<String, dynamic> payload) async {
    final String id = const Uuid().v4();
    final Map<String, dynamic> queueItem = {
      'id': id,
      'endpoint': endpoint,
      'payload': payload,
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

      final List<String> keys = syncBox.keys.cast<String>().toList();

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

          final response = await dioClient.dio.post<Map<String, dynamic>>(endpoint, data: payload);

          if (response.statusCode == 200 || response.statusCode == 201) {
            await syncBox.delete(key);
          }
        } on DioException catch (e) {
          if (item != null && isPermanentRejection(e)) {
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

  /// Oturumdaki kullanıcının reddedilen kayıtları, eskiden yeniye.
  List<RejectedRecord> rejectedRecords() {
    final int? owner = currentUserId();
    if (owner == null) return const <RejectedRecord>[];

    final List<RejectedRecord> records = <RejectedRecord>[];
    for (final dynamic key in syncBox.keys) {
      final String? raw = syncBox.get(key);
      if (raw == null) continue;
      try {
        final Map<String, dynamic> item = jsonDecode(raw) as Map<String, dynamic>;
        if (item['status'] != _statusRejected) continue;
        final Object? itemOwner = item['ownerId'];
        if (itemOwner != null && itemOwner != owner) continue;
        records.add(RejectedRecord(
          key: key as String,
          endpoint: item['endpoint'] as String,
          reason: (item['reason'] as String?) ?? _defaultReason,
          createdAt: DateTime.tryParse((item['timestamp'] as String?) ?? ''),
        ));
      } on FormatException {
        continue;
      }
    }
    records.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
    return records;
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
