import 'package:dio/dio.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/features/measurement/models/client_measurements_summary.dart';
import 'package:gymapp_v2/features/measurement/models/measurement.dart';

/// GYMAPP-V2 Ölçüm Repository'si.
/// Backend ölçüm API'si ile iletişimi yönetir.
class MeasurementRepository {
  final DioClient _dioClient;

  MeasurementRepository(this._dioClient);

  /// Kullanıcının tüm ölçüm geçmişini getirir (en yeniden eskiye).
  Future<List<Measurement>> getMyMeasurements({int? clientId}) async {
    try {
      final path = clientId != null ? '/measurements/client/$clientId' : '/measurements';
      final response = await _dioClient.dio.get<Map<String, dynamic>>(path);
      final responseData = response.data;
      if (responseData == null) return [];

      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        responseData,
        (json) => (json as Map<String, dynamic>)['content'] as List<dynamic>,
      );
      return apiResponse.data
              ?.map((json) => Measurement.fromJson(json as Map<String, dynamic>))
              .toList() ??
          [];
    } on DioException catch (e) {
      _handleError(e);
      return [];
    }
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
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/measurements',
        data: measurement.toJson(),
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
    try {
      final response = await _dioClient.dio.delete<Map<String, dynamic>>(
        '/measurements/$id',
      );
      if (response.statusCode != 200) {
        final responseData = response.data;
        throw Exception(responseData?['message'] ?? 'Ölçüm silinemedi.');
      }
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
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
