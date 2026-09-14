import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_error_handler.dart';

class FileApiService with ApiErrorHandler {
  final DioClient _dioClient;

  FileApiService(this._dioClient);

  Dio get _dio => _dioClient.dio;

  Future<ApiResponse<Map<String, String>>> uploadFile(
    String filePath,
    String fileName,
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/files/upload',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      return ApiResponse<Map<String, String>>.fromJson(response.data!, (json) {
        final map = json as Map<String, dynamic>;
        return {'url': map['url'] as String};
      });
    } on DioException catch (e) {
      return handleError(e, defaultMessage: 'Dosya yüklenemedi');
    }
  }
}
