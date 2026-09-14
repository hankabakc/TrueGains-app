import 'package:dio/dio.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';

abstract class BaseNutritionService {
  final DioClient dioClient;

  BaseNutritionService(this.dioClient);

  ApiResponse<T> handleError<T>(DioException e) {
    String message = 'Beslenme servisi hatası';
    if (e.response?.statusCode == 409) {
      message = 'Eş zamanlı güncelleme çakışması: Veri başka bir yerde güncellenmiş. Lütfen sayfayı yenileyip tekrar deneyin.';
    } else if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        message = (data['message'] as String?) ?? 'İşlem başarısız';
      }
    }
    return ApiResponse<T>.error(message);
  }
}
