import 'package:dio/dio.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/core/network/api_error_handler.dart';
import 'package:gymapp_v2/core/network/page_response.dart';
import 'package:gymapp_v2/features/social/data/models/coach_discovery_model.dart';
import 'package:gymapp_v2/features/social/data/models/discovery_user_model.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/social/data/models/pairing_request_model.dart';

class SocialApiService with ApiErrorHandler {
  final DioClient _dioClient;

  SocialApiService(this._dioClient);

  Dio get _dio => _dioClient.dio;

  Future<ApiResponse<PageResponse<CoachDiscoveryModel>>> discoverCoaches({
    String? specialization,
    String? name,
    double? minRating,
    String sort = 'rating',
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/social/coaches',
        queryParameters: {
          if (specialization != null && specialization.isNotEmpty)
            'specialization': specialization,
          if (name != null && name.isNotEmpty) 'name': name,
          if (minRating != null) 'minRating': minRating,
          'sort': sort,
          'page': page,
          'size': size,
        },
      );

      return ApiResponse<PageResponse<CoachDiscoveryModel>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => PageResponse<CoachDiscoveryModel>.fromJson(
          json as Map<String, dynamic>,
          (e) => CoachDiscoveryModel.fromJson(e as Map<String, dynamic>),
        ),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<PageResponse<DiscoveryUserModel>>> discoverUsers({
    required UserRole role,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/social/discover',
        queryParameters: {
          'role': role.toJsonString(),
          'page': page,
          'size': size,
        },
      );

      return ApiResponse<PageResponse<DiscoveryUserModel>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => PageResponse<DiscoveryUserModel>.fromJson(
          json as Map<String, dynamic>,
          (e) => DiscoveryUserModel.fromJson(e as Map<String, dynamic>),
        ),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<PairingRequestModel>> sendPairingRequest(
    int coachId,
    String message,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/social/pairing/request',
        data: {'coachId': coachId, 'message': message},
      );

      return ApiResponse<PairingRequestModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => PairingRequestModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
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
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<List<PairingRequestModel>>> getPendingRequests() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/social/pairing/pending');
      return ApiResponse<List<PairingRequestModel>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) =>
            (json as List)
                .map(
                  (e) =>
                      PairingRequestModel.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<void>> respondToRequest(
    int requestId,
    bool accepted,
  ) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/social/pairing/respond/$requestId',
        queryParameters: {'accepted': accepted},
      );
      return ApiResponse(
        success: true,
        message: 'İşlem başarılı',
        timestamp: DateTime.now().toString(),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<List<DiscoveryUserModel>>> getMyClients() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/social/pairing/clients');
      return ApiResponse<List<DiscoveryUserModel>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) =>
            (json as List)
                .map((e) => DiscoveryUserModel.fromJson(e as Map<String, dynamic>))
                .toList(),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }
  /// Kullanici sikayeti. Sikayet EDEN kendi kaydini geri okuyamaz; kimin kimi
  /// sikayet ettigi yalnizca yonetimde gorulur.
  Future<ApiResponse<void>> reportUser({
    required int reportedUserId,
    required String reason,
    String? description,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/social/reports',
        data: {
          'reportedUserId': reportedUserId,
          'reason': reason,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );

      return ApiResponse<void>.fromJson(
        response.data as Map<String, dynamic>,
        (_) {},
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

}
