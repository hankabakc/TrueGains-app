import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/core/network/network_info.dart';
import 'package:uuid/uuid.dart';

class SyncManager {
  final NetworkInfo networkInfo;
  final DioClient dioClient;
  final Box<String> syncBox;

  SyncManager({
    required this.networkInfo,
    required this.dioClient,
    required this.syncBox,
  }) {
    // İnternet bağlantısı değiştiğinde eşitlemeyi tetikle
    networkInfo.onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        syncPendingData();
      }
    });
  }

  /// Çevrimdışı veriyi kuyruğa ekler
  Future<void> addToQueue(String endpoint, Map<String, dynamic> payload) async {
    final String id = const Uuid().v4();
    final Map<String, dynamic> queueItem = {
      'id': id,
      'endpoint': endpoint,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await syncBox.put(id, jsonEncode(queueItem));
  }

  /// Kuyrukta bekleyen tüm verileri senkronize eder
  Future<void> syncPendingData() async {
    if (syncBox.isEmpty) return;

    final bool isConnected = await networkInfo.isConnected;
    if (!isConnected) return;

    final List<String> keys = syncBox.keys.cast<String>().toList();

    for (final key in keys) {
      final String? rawData = syncBox.get(key);
      if (rawData == null) continue;

      try {
        final Map<String, dynamic> item = jsonDecode(rawData) as Map<String, dynamic>;
        final String endpoint = item['endpoint'] as String;
        final Map<String, dynamic> payload = item['payload'] as Map<String, dynamic>;

        // Backend'e gönder
        final response = await dioClient.dio.post<Map<String, dynamic>>(endpoint, data: payload);

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Başarılı ise lokalden sil
          await syncBox.delete(key);
        }
      } catch (e) {
        // Hata durumunda öğeyi kuyrukta tut
      }
    }
  }
}
