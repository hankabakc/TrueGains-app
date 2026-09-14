import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/api_error_handler.dart';
import '../models/coach_profile_model.dart';
import '../models/coach_review_model.dart';
import '../models/coach_gallery_model.dart';

class CoachProfileApiService with ApiErrorHandler {
  final DioClient _dioClient;
  
  CoachProfileApiService(this._dioClient);

  Dio get _dio => _dioClient.dio;

  Future<ApiResponse<CoachProfileModel>> getCoachProfile(int coachId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/coaches/$coachId/profile',
      );
      return ApiResponse<CoachProfileModel>.fromJson(
        response.data!,
        (json) => CoachProfileModel.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<List<CoachReviewModel>>> getCoachReviews(
    int coachId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/coaches/$coachId/reviews',
        queryParameters: {'page': page, 'size': size, 'sort': 'createdAt,desc'},
      );

      return ApiResponse<List<CoachReviewModel>>.fromJson(response.data!, (
        json,
      ) {
        // Spring Boot Page<T> response wraps content in a 'content' field
        final content =
            (json as Map<String, dynamic>)['content'] as List<dynamic>?;
        if (content == null) return [];
        return content
            .map((e) => CoachReviewModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<CoachReviewModel>> addReview(
    int coachId,
    int rating,
    String? comment,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/coaches/$coachId/reviews',
        data: {
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );
      return ApiResponse<CoachReviewModel>.fromJson(
        response.data!,
        (json) => CoachReviewModel.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<void>> sendCoachRequest(int coachId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/clients/requests/coach/$coachId',
      );
      return ApiResponse<void>(
        success: true,
        message: (response.data?['message'] as String?) ??
            'Koçluk isteği başarıyla gönderildi.',
        timestamp: DateTime.now().toString(),
      );
    } catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<CoachGalleryModel>> addGalleryItem(
    String imageUrl,
    bool isStudentProgress,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/coaches/gallery',
        data: {
          'imageUrl': imageUrl,
          'isStudentProgress': isStudentProgress,
        },
      );
      return ApiResponse<CoachGalleryModel>.fromJson(
        response.data!,
        (json) => CoachGalleryModel.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<void>> deleteGalleryItem(int itemId) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/coaches/gallery/$itemId',
      );
      return ApiResponse<void>.fromJson(
        response.data!,
        (json) {},
      );
    } catch (e) {
      return handleError(e);
    }
  }
}
