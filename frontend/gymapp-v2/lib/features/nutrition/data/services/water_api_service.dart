import 'package:dio/dio.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import '../models/water_intake_model.dart';
import '../models/client_water_tracking_model.dart';
import 'base_nutrition_service.dart';

class WaterApiService extends BaseNutritionService {
  static const String waterPath = '/nutrition/water';

  WaterApiService(super.dioClient);

  /// Kuyruğa giren su kaydının adresi (G-86): cihaz kimliği tekrar korumasına, gün kaydın eklendiği güne yarar.
  static String addWaterEndpoint(int amountMl, String localId, String intakeDate) {
    return Uri(path: waterPath, queryParameters: <String, dynamic>{
      'amountMl': '$amountMl',
      'localId': localId,
      'intakeDate': intakeDate,
    }).toString();
  }

  Future<ApiResponse<WaterIntakeModel>> addWater(int amountMl, {String? localId}) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        waterPath,
        queryParameters: <String, dynamic>{'amountMl': amountMl, if (localId != null) 'localId': localId},
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => WaterIntakeModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<WaterDailySummaryModel>> getDailyWaterSummary([DateTime? date]) async {
    try {
      final queryDate = date ?? DateTime.now();
      final dateStr = queryDate.toIso8601String().split('T')[0];
      final response = await dioClient.dio.get<Map<String, dynamic>>(
        '/nutrition/water/summary',
        queryParameters: {'date': dateStr},
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => WaterDailySummaryModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<List<WaterDailyTotalModel>>> getWaterRangeSummary(DateTime start, DateTime end) async {
    try {
      final startStr = start.toIso8601String().split('T')[0];
      final endStr = end.toIso8601String().split('T')[0];
      final response = await dioClient.dio.get<Map<String, dynamic>>(
        '/nutrition/water/range',
        queryParameters: {'start': startStr, 'end': endStr},
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => (json as List).map((e) => WaterDailyTotalModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<void>> updateWaterTarget(int targetMl) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/nutrition/water/target',
        queryParameters: {'targetMl': targetMl},
      );
      return ApiResponse.fromJson(response.data ?? <String, dynamic>{}, (_) {});
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<CustomGlassModel>> addCustomGlass(String name, int sizeMl) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/nutrition/water/glass',
        queryParameters: {'name': name, 'sizeMl': sizeMl},
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => CustomGlassModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<void>> deleteCustomGlass(int id) async {
    try {
      final response = await dioClient.dio.delete<Map<String, dynamic>>(
        '/nutrition/water/glass/$id',
      );
      return ApiResponse.fromJson(response.data ?? <String, dynamic>{}, (_) {});
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<void>> deleteWaterIntake(int id) async {
    try {
      final response = await dioClient.dio.delete<Map<String, dynamic>>(
        '$waterPath/$id',
      );
      return ApiResponse.fromJson(response.data ?? <String, dynamic>{}, (_) {});
    } on DioException catch (e) {
      // G-86: kayıt sunucuda zaten yoksa (başka cihazdan ya da kuyruktan silinmiş) silme amacına ulaşmıştır.
      if (e.response?.statusCode == 404) {
        return ApiResponse(success: true, message: 'Silindi', timestamp: '');
      }
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<List<ClientWaterTrackingModel>>> getCoachStudentsWaterIntake() async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>('/coach/students/water-intake');
      return ApiResponse<List<ClientWaterTrackingModel>>.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => (json as List).map((e) => ClientWaterTrackingModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }
}
