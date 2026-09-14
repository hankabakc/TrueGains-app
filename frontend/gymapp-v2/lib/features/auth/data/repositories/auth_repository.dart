import 'package:gymapp_v2/core/network/api_response.dart';
import '../models/auth_model.dart';
import '../services/auth_api_service.dart';

class AuthRepository {
  final AuthApiService _apiService;

  AuthRepository(this._apiService);

  Future<ApiResponse<AuthModel>> login(String email, String password) {
    return _apiService.login(email, password);
  }

  Future<ApiResponse<AuthModel>> restoreSession() {
    return _apiService.restoreSession();
  }

  Future<ApiResponse<void>> register(Map<String, dynamic> data) {
    return _apiService.register(data);
  }

  Future<ApiResponse<AuthModel>> verifyOtp(String email, String code) {
    return _apiService.verifyOtp(email, code);
  }

  Future<ApiResponse<void>> resendOtp(String email) {
    return _apiService.resendOtp(email);
  }

  Future<ApiResponse<void>> forgotPassword(String email) {
    return _apiService.forgotPassword(email);
  }

  Future<ApiResponse<void>> resetPassword(
    String email,
    String code,
    String newPassword,
  ) {
    return _apiService.resetPassword(email, code, newPassword);
  }

  Future<void> logout() {
    return _apiService.logout();
  }
}
