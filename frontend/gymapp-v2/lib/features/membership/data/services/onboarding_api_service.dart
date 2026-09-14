import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/config/app_config.dart';

class OnboardingApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: '${AppConfig.apiBaseUrl}/profile',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  Future<ApiResponse<void>> updateClientProfile(
    int userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>('/client/$userId', data: data);
      return ApiResponse<void>.fromJson(response.data!, (json) {});
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> updateCoachProfile(
    int userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>('/coach/$userId', data: data);
      return ApiResponse<void>.fromJson(response.data!, (json) {});
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  ApiResponse<void> _handleError(DioException e) {
    final message =
        e.response?.data is Map<String, dynamic>
            ? (e.response?.data as Map<String, dynamic>)['message'] as String? ?? 'Profil güncellenemedi'
            : 'Sunucuya bağlanılamadı';
    return ApiResponse<void>(
      success: false,
      message: message,
      timestamp: DateTime.now().toString(),
    );
  }
}
