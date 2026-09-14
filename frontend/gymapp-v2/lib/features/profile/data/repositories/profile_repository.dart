import 'package:gymapp_v2/core/network/api_error_handler.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import '../models/client_profile_response_model.dart';
import '../models/coach_profile_response_model.dart';

class ProfileRepository with ApiErrorHandler {
  final DioClient _dioClient;

  ProfileRepository(this._dioClient);

  Future<ApiResponse<ClientProfileResponseModel>> getMyProfile() async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>('/profile/client/me');
      return ApiResponse<ClientProfileResponseModel>.fromJson(
        response.data!,
        (json) => ClientProfileResponseModel.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      return handleError<ClientProfileResponseModel>(e);
    }
  }

  Future<ApiResponse<CoachProfileResponseModel>> getMyCoachProfile() async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>('/profile/coach/me');
      return ApiResponse<CoachProfileResponseModel>.fromJson(
        response.data!,
        (json) => CoachProfileResponseModel.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      return handleError<CoachProfileResponseModel>(e);
    }
  }

  Future<ApiResponse<ClientProfileResponseModel>> getClientProfile(int clientId) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>('/profile/client/$clientId');
      return ApiResponse<ClientProfileResponseModel>.fromJson(
        response.data!,
        (json) => ClientProfileResponseModel.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      return handleError<ClientProfileResponseModel>(e);
    }
  }

  Future<ApiResponse<void>> updateProfile(int userId, Map<String, dynamic> data, {bool isCoach = false}) async {
    try {
      final rolePath = isCoach ? 'coach' : 'client';
      final response = await _dioClient.dio.put<Map<String, dynamic>>(
        '/profile/$rolePath/$userId',
        data: data,
      );
      return ApiResponse<void>.fromJson(response.data!, (json) {});
    } catch (e) {
      return handleError<void>(e);
    }
  }

  Future<ApiResponse<void>> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/profile/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      return ApiResponse<void>.fromJson(response.data!, (json) {});
    } catch (e) {
      return handleError<void>(e);
    }
  }

  Future<ApiResponse<void>> deleteMyAccount() async {
    try {
      final response = await _dioClient.dio.delete<Map<String, dynamic>>('/profile/me');
      return ApiResponse<void>.fromJson(response.data!, (json) {});
    } catch (e) {
      return handleError<void>(e);
    }
  }
}
