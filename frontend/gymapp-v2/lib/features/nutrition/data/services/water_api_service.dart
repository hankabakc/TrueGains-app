import 'package:dio/dio.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import '../models/water_intake_model.dart';
import '../models/client_water_tracking_model.dart';
import 'base_nutrition_service.dart';

class WaterApiService extends BaseNutritionService {
  WaterApiService(super.dioClient);

  Future<ApiResponse<WaterIntakeModel>> addWater(int amountMl) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/nutrition/water',
        queryParameters: {'amountMl': amountMl},
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
        '/nutrition/water/$id',
      );
      return ApiResponse.fromJson(response.data ?? <String, dynamic>{}, (_) {});
    } on DioException catch (e) {
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
