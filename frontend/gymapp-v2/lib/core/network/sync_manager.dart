import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gymapp_v2/core/constants/storage_keys.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/core/network/network_info.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Çevrimdışı yazma kuyruğu: bağlantı yokken yapılan istekleri saklar, bağlantı gelince gönderir.
///
/// Kayıt kime aitse yalnızca o kullanıcının oturumunda gönderilir; başkasının kaydına
/// dokunulmaz. Gönderilen kayıt dışında hiçbir kayıt silinmez.
class SyncManager {
  /// Şifreli kuyruk kutusu.
  static const String boxName = 'sync_queue_secure';

  /// G-68 öncesi şifresiz kutu; açılışta [boxName]'e taşınır.
  static const String legacyBoxName = 'sync_queue';

  final NetworkInfo networkInfo;
  final DioClient dioClient;
  final Box<String> syncBox;

  /// O an oturum açmış kullanıcının kimliği; oturum yoksa null.
  final int? Function() currentUserId;

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

  /// Kuyrukta bekleyen, oturumdaki kullanıcıya ait kayıtları gönderir.
  Future<void> syncPendingData() async {
    if (syncBox.isEmpty) return;

    final int? owner = currentUserId();
    if (owner == null) return;

    final bool isConnected = await networkInfo.isConnected;
    if (!isConnected) return;

    final List<String> keys = syncBox.keys.cast<String>().toList();

    for (final key in keys) {
      final String? rawData = syncBox.get(key);
      if (rawData == null) continue;

      try {
        final Map<String, dynamic> item = jsonDecode(rawData) as Map<String, dynamic>;

        // ponytail: sahibi olmayan kayıt yalnızca G-68 öncesi kurulumdan taşınmış olabilir
        // (üretimde kurulum yok); oturumdaki kullanıcıyla gönderilir.
        final Object? itemOwner = item['ownerId'];
        if (itemOwner != null && itemOwner != owner) continue;

        final String endpoint = item['endpoint'] as String;
        final Map<String, dynamic> payload = item['payload'] as Map<String, dynamic>;

        final response = await dioClient.dio.post<Map<String, dynamic>>(endpoint, data: payload);

        if (response.statusCode == 200 || response.statusCode == 201) {
          await syncBox.delete(key);
        }
      } catch (e) {
        // Hata durumunda kayıt kuyrukta kalır (reddedilen kaydın gösterimi: G-69).
      }
    }
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
