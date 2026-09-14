import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_error_handler.dart';
import '../models/coach_student_progress_model.dart';

class CoachStudentProgressApiService with ApiErrorHandler {
  final DioClient _dioClient;

  CoachStudentProgressApiService(this._dioClient);

  Future<ApiResponse<CoachStudentProgressModel>> createProgressRequest({
    required int clientId,
    required String studentNickname,
    required String beforeImageUrl,
    required String afterImageUrl,
    String? description,
  }) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/coaches/progress',
        data: {
          'clientId': clientId,
          'studentNickname': studentNickname,
          'beforeImageUrl': beforeImageUrl,
          'afterImageUrl': afterImageUrl,
          'description': description,
        },
      );
      final responseData = response.data;
      if (responseData != null && responseData['success'] == true) {
        return ApiResponse<CoachStudentProgressModel>(
          success: true,
          message: responseData['message'] as String? ?? 'Talep gönderildi.',
          data: CoachStudentProgressModel.fromJson(responseData['data'] as Map<String, dynamic>),
          timestamp: responseData['timestamp'] as String? ?? '',
        );
      }
      return ApiResponse<CoachStudentProgressModel>(
        success: false,
        message: responseData?['message'] as String? ?? 'Talep gönderilemedi.',
        timestamp: responseData?['timestamp'] as String? ?? '',
      );
    } catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<List<CoachStudentProgressModel>>> getPendingRequests() async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>('/coaches/progress/pending');
      final responseData = response.data;
      if (responseData != null && responseData['success'] == true) {
        final List<dynamic> data = responseData['data'] as List<dynamic>;
        return ApiResponse<List<CoachStudentProgressModel>>(
          success: true,
          message: responseData['message'] as String? ?? 'Talepler yüklendi.',
          data: data.map((json) => CoachStudentProgressModel.fromJson(json as Map<String, dynamic>)).toList(),
          timestamp: responseData['timestamp'] as String? ?? '',
        );
      }
      return ApiResponse<List<CoachStudentProgressModel>>(
        success: false,
        message: responseData?['message'] as String? ?? 'Talepler yüklenemedi.',
        timestamp: responseData?['timestamp'] as String? ?? '',
      );
    } catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<CoachStudentProgressModel>> respondToRequest(int requestId, bool approved) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/coaches/progress/$requestId/respond',
        data: {'approved': approved},
      );
      final responseData = response.data;
      if (responseData != null && responseData['success'] == true) {
        return ApiResponse<CoachStudentProgressModel>(
          success: true,
          message: responseData['message'] as String? ?? 'İşlem başarılı.',
          data: CoachStudentProgressModel.fromJson(responseData['data'] as Map<String, dynamic>),
          timestamp: responseData['timestamp'] as String? ?? '',
        );
      }
      return ApiResponse<CoachStudentProgressModel>(
        success: false,
        message: responseData?['message'] as String? ?? 'İşlem başarısız.',
        timestamp: responseData?['timestamp'] as String? ?? '',
      );
    } catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<List<CoachStudentProgressModel>>> getApprovedProgress(int coachId) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>('/coaches/progress/coach/$coachId/approved');
      final responseData = response.data;
      if (responseData != null && responseData['success'] == true) {
        final List<dynamic> data = responseData['data'] as List<dynamic>;
        return ApiResponse<List<CoachStudentProgressModel>>(
          success: true,
          message: responseData['message'] as String? ?? 'Gelişimler yüklendi.',
          data: data.map((json) => CoachStudentProgressModel.fromJson(json as Map<String, dynamic>)).toList(),
          timestamp: responseData['timestamp'] as String? ?? '',
        );
      }
      return ApiResponse<List<CoachStudentProgressModel>>(
        success: false,
        message: responseData?['message'] as String? ?? 'Gelişimler yüklenemedi.',
        timestamp: responseData?['timestamp'] as String? ?? '',
      );
    } catch (e) {
      return handleError(e);
    }
  }
}
