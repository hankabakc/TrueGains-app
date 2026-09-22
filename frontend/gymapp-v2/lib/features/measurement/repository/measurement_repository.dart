import 'package:dio/dio.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/network_info.dart';
import 'package:gymapp_v2/core/network/offline_cache.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:gymapp_v2/features/measurement/models/client_measurements_summary.dart';
import 'package:gymapp_v2/features/measurement/models/measurement.dart';
import 'package:uuid/uuid.dart';

/// GYMAPP-V2 Ölçüm Repository'si.
/// Backend ölçüm API'si ile iletişimi yönetir. Ekleme ve silme internetsiz kuyruğa girer (KR13, G-86).
class MeasurementRepository {
  static const String measurementsPath = '/measurements';

  final DioClient _dioClient;
  final NetworkInfo _networkInfo;
  final SyncManager _syncManager;

  MeasurementRepository(this._dioClient, this._networkInfo, this._syncManager);

  /// Kullanıcının tüm ölçüm geçmişini getirir (en yeniden eskiye). Kendi listesinde kuyruktaki ölçümler en üstte
  /// "bekliyor" olarak görünür, silinmeyi bekleyen ölçüm gizlenir (G-86).
  Future<List<Measurement>> getMyMeasurements({int? clientId}) async {
    try {
      final path = clientId != null ? '$measurementsPath/client/$clientId' : measurementsPath;
      final response = await _dioClient.dio.get<Map<String, dynamic>>(path);
      final responseData = response.data;
      if (responseData == null) return clientId == null ? _withQueued(const <Measurement>[]) : [];

      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        responseData,
        (json) => (json as Map<String, dynamic>)['content'] as List<dynamic>,
      );
      final List<Measurement> list = apiResponse.data
              ?.map((json) => Measurement.fromJson(json as Map<String, dynamic>))
              .toList() ??
          [];
      return clientId == null ? _withQueued(list) : list;
    } on DioException catch (e) {
      // İnternetsiz ve liste önbellekte yoksa en azından kuyruktaki ölçümler görünür.
      if (clientId == null && OfflineCacheInterceptor.isUnreachable(e)) {
        return _withQueued(const <Measurement>[]);
      }
      _handleError(e);
      return [];
    }
  }

  List<Measurement> _withQueued(List<Measurement> list) {
    final List<PendingRecord> queued = _syncManager.pendingRecords();
    const String deletePrefix = '$measurementsPath/';
    final Set<int> deletedIds = <int>{
      for (final PendingRecord r in queued)
        if (r.method == SyncManager.methodDelete && r.endpoint.startsWith(deletePrefix))
          int.tryParse(r.endpoint.substring(deletePrefix.length)) ?? -1,
    };
    // Kuyruk eklenme sırasıyla (eskiden yeniye) gelir; liste yeniden eskiye.
    final List<Measurement> pending = <Measurement>[
      for (final PendingRecord r in queued.reversed)
        if (r.method == SyncManager.methodPost && r.endpoint == measurementsPath)
          Measurement.fromJson(r.payload).copyWith(queueKey: r.key),
    ];
    return <Measurement>[
      ...pending,
      ...list.where((Measurement m) => !deletedIds.contains(m.id)),
    ];
  }

  /// Bugün girilmiş bir ölçüm varsa getirir.
  Future<Measurement?> getTodayMeasurement() async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/measurements/today',
      );
      final responseData = response.data;
      if (responseData == null) return null;

      final apiResponse = ApiResponse<dynamic>.fromJson(responseData, (json) => json);
      if (apiResponse.data == null) return null;
      return Measurement.fromJson(apiResponse.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  /// Yeni bir ölçüm kaydı ekler.
  Future<Measurement> addMeasurement(Measurement measurement) async {
    // Tekrar koruması (G-86): ölçüm cihazda kimlik alır; çevrimiçi ve kuyruk yolu aynı kimliği taşır.
    final String localId = const Uuid().v4();
    if (!await _networkInfo.isConnected) {
      // KR13 (G-86): bağlantı yoksa ölçüm kuyruğa girer; zamanı eklendiği an, gönderildiği an değil.
      final Map<String, dynamic> payload = <String, dynamic>{
        ...measurement.toJson(),
        'localId': localId,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      };
      await _syncManager.addToQueue(measurementsPath, payload);
      return Measurement.fromJson(payload);
    }

    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        measurementsPath,
        data: <String, dynamic>{...measurement.toJson(), 'localId': localId},
      );
      final responseData = response.data;
      if (responseData == null) throw Exception('Kayıt eklenemedi.');

      final apiResponse = ApiResponse<dynamic>.fromJson(responseData, (json) => json);
      if (apiResponse.success && apiResponse.data != null) {
        return Measurement.fromJson(apiResponse.data as Map<String, dynamic>);
      }
      throw Exception(apiResponse.message);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Belirli bir ölçüm kaydını siler.
  Future<void> deleteMeasurement(int id) async {
    if (!await _networkInfo.isConnected) {
      // KR13 (G-86): bağlantı yoksa silme kuyruğa girer; liste ölçümü hemen gizler.
      await _syncManager.addToQueue('$measurementsPath/$id', <String, dynamic>{}, method: SyncManager.methodDelete);
      return;
    }
    try {
      final response = await _dioClient.dio.delete<Map<String, dynamic>>(
        '$measurementsPath/$id',
      );
      // Sunucu silmede 204 döner (MeasurementController @ResponseStatus(NO_CONTENT)); yalnız 200 beklendiği için
      // her başarılı silme "Ölçüm silinemedi" gösteriyordu (G-86).
      if (response.statusCode != 200 && response.statusCode != 204) {
        final responseData = response.data;
        throw Exception(responseData?['message'] ?? 'Ölçüm silinemedi.');
      }
    } on DioException catch (e) {
      // Ölçüm sunucuda zaten yoksa (başka cihazdan ya da kuyruktan silinmiş) silme amacına ulaşmıştır.
      if (e.response?.statusCode == 404) return;
      _handleError(e);
      rethrow;
    }
  }

  /// Sunucuya henüz gitmemiş ölçümü kuyruktan çıkarır; kullanıcının silmesiyle çağrılır (G-86).
  Future<void> discardPending(String queueKey) {
    return _syncManager.discard(queueKey);
  }

  /// Seçilen ölçümleri antrenörle paylaşır.
  Future<void> shareMeasurements(List<int> measurementIds) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/measurements/share',
        data: measurementIds,
      );
      final responseData = response.data;
      if (responseData == null) throw Exception('Paylaşım işlemi başarısız.');

      final apiResponse = ApiResponse<dynamic>.fromJson(responseData, (json) => json);
      if (!apiResponse.success) {
        throw Exception(apiResponse.message);
      }
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Antrenör için belirli bir sporcunun paylaştığı ölçümleri (güncel) getirir.
  /// Öğrenci 360 panelinin her açılışta taze veri göstermesi için kullanılır.
  Future<ClientMeasurementsSummary?> getSharedMeasurementsForClient(int clientId) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/coaches/measurements/shared/$clientId',
      );
      final responseData = response.data;
      if (responseData == null) return null;

      final apiResponse = ApiResponse<dynamic>.fromJson(responseData, (json) => json);
      if (apiResponse.data == null) return null;
      return ClientMeasurementsSummary.fromJson(apiResponse.data as Map<String, dynamic>);
    } catch (_) {
      // Hata durumunda sessizce null dön; panel mevcut anlık görüntüye düşer.
      return null;
    }
  }

  /// Antrenör için paylaşılan ölçümleri getirir.
  Future<List<ClientMeasurementsSummary>> getSharedMeasurements() async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/coaches/measurements/shared',
      );
      final responseData = response.data;
      if (responseData == null) return [];

      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        responseData,
        (json) => json as List<dynamic>,
      );
      return apiResponse.data
              ?.map(
                (json) =>
                    ClientMeasurementsSummary.fromJson(json as Map<String, dynamic>),
              )
              .toList() ??
          [];
    } on DioException catch (e) {
      _handleError(e);
      return [];
    }
  }

  void _handleError(DioException e) {
    if (e.response?.statusCode == 409) {
      throw Exception(
        'Eş zamanlı güncelleme çakışması: Veri başka bir yerde güncellenmiş. Lütfen sayfayı yenileyip tekrar deneyin.',
      );
    }
    final message =
        e.response?.data is Map<String, dynamic>
            ? (e.response!.data as Map<String, dynamic>)['message'] as String?
            : null;
    throw Exception(message ?? 'Ölçüm işlemi sırasında hata oluştu.');
  }
}
