import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_error_handler.dart';
import '../models/client_gallery_model.dart';

class ClientGalleryApiService with ApiErrorHandler {
  final DioClient _dioClient;

  ClientGalleryApiService(this._dioClient);

  Future<ApiResponse<List<ClientGalleryModel>>> getMyGallery() async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>('/clients/gallery');
      final responseData = response.data;
      if (responseData != null && responseData['success'] == true) {
        final List<dynamic> data = responseData['data'] as List<dynamic>;
        return ApiResponse<List<ClientGalleryModel>>(
          success: true,
          message: responseData['message'] as String? ?? 'Galeri başarıyla yüklendi.',
          data: data.map((json) => ClientGalleryModel.fromJson(json as Map<String, dynamic>)).toList(),
          timestamp: responseData['timestamp'] as String? ?? '',
        );
      }
      return ApiResponse<List<ClientGalleryModel>>(
        success: false,
        message: responseData?['message'] as String? ?? 'Galeri yüklenemedi.',
        timestamp: responseData?['timestamp'] as String? ?? '',
      );
    } catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<ClientGalleryModel>> addToGallery(String imageUrl) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/clients/gallery',
        data: {'imageUrl': imageUrl},
      );
      final responseData = response.data;
      if (responseData != null && responseData['success'] == true) {
        return ApiResponse<ClientGalleryModel>(
          success: true,
          message: responseData['message'] as String? ?? 'Resim galeriye eklendi.',
          data: ClientGalleryModel.fromJson(responseData['data'] as Map<String, dynamic>),
          timestamp: responseData['timestamp'] as String? ?? '',
        );
      }
      return ApiResponse<ClientGalleryModel>(
        success: false,
        message: responseData?['message'] as String? ?? 'Resim eklenemedi.',
        timestamp: responseData?['timestamp'] as String? ?? '',
      );
    } catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<void>> deleteGalleryItem(int id) async {
    try {
      final response = await _dioClient.dio.delete<Map<String, dynamic>>('/clients/gallery/$id');
      final responseData = response.data;
      if (responseData != null && responseData['success'] == true) {
        return ApiResponse<void>(
          success: true,
          message: responseData['message'] as String? ?? 'Resim galeriden silindi.',
          timestamp: responseData['timestamp'] as String? ?? '',
        );
      }
      return ApiResponse<void>(
        success: false,
        message: responseData?['message'] as String? ?? 'Resim silinemedi.',
        timestamp: responseData?['timestamp'] as String? ?? '',
      );
    } catch (e) {
      return handleError(e);
    }
  }
}
