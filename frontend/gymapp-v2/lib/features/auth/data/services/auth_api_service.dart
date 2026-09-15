import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/device_service.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/constants/network_constants.dart';
import '../models/auth_model.dart';

class AuthApiService {
  final DioClient _dioClient;
  final FlutterSecureStorage _secureStorage;
  final DeviceService _deviceService = DeviceService();

  AuthApiService(this._dioClient, this._secureStorage);

  Future<ApiResponse<AuthModel>> login(String email, String password) async {
    try {
      final deviceId = await _deviceService.getDeviceId();
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password, 'deviceId': deviceId},
      );

      final responseData = response.data;
      if (responseData == null) throw Exception('Response data is null');

      if (responseData['success'] == true) {
        final authData = AuthModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
        if (authData.accessToken.isNotEmpty) {
          await _secureStorage.write(
            key: StorageKeys.accessToken,
            value: authData.accessToken,
          );
        }
      }

      return ApiResponse<AuthModel>.fromJson(
        responseData,
        (json) => AuthModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Açılışta oturumu sessizce geri yükler: kalıcı refresh cookie'si ile
  /// `/auth/refresh` çağrılır. Başarılıysa yeni erişim token'ı saklanır ve
  /// kullanıcı bilgisi döner. Cookie yok/geçersizse (yeni veya süresi dolmuş
  /// oturum) başarısız `ApiResponse` döner ve kullanıcı login'e yönlendirilir.
  Future<ApiResponse<AuthModel>> restoreSession() async {
    try {
      final deviceId = await _deviceService.getDeviceId();
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'deviceId': deviceId},
      );

      final responseData = response.data;
      if (responseData == null) throw Exception('Response data is null');

      if (responseData['success'] == true && responseData['data'] != null) {
        final authData = AuthModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
        if (authData.accessToken.isNotEmpty) {
          await _secureStorage.write(
            key: StorageKeys.accessToken,
            value: authData.accessToken,
          );
        }
      }

      return ApiResponse<AuthModel>.fromJson(
        responseData,
        (json) => AuthModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> register(Map<String, dynamic> data) async {
    try {
      // Güvenlik: Kayıt artık token döndürmez; oturum OTP doğrulamasından sonra açılır.
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: data,
      );
      final responseData = response.data ?? {};
      return ApiResponse<void>.fromJson(responseData, (json) {});
    } on DioException catch (e) {
      final err = _handleError(e);
      return ApiResponse<void>(
        success: false,
        message: err.message,
        statusCode: err.statusCode,
        timestamp: DateTime.now().toString(),
      );
    }
  }

  Future<ApiResponse<AuthModel>> verifyOtp(String email, String code) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/auth/verify-otp',
        // E-posta ve OTP kodu gövdede taşınır; sorgu dizesindeyken ikisi de
        // vekil erişim loglarına ham hâliyle düşüyordu.
        data: <String, dynamic>{'email': email, 'code': code},
      );
      final responseData = response.data ?? {};

      // Doğrulama başarılıysa oturum token'ı burada üretilir ve saklanır.
      if (responseData['success'] == true && responseData['data'] != null) {
        final authData = AuthModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
        if (authData.accessToken.isNotEmpty) {
          await _secureStorage.write(
            key: StorageKeys.accessToken,
            value: authData.accessToken,
          );
        }
      }

      return ApiResponse<AuthModel>.fromJson(
        responseData,
        (json) => AuthModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Doğrulanmamış kaydı iptal eder (OTP'den geri çıkış); sunucu hesabı ve verileri siler.
  Future<ApiResponse<void>> resendOtp(String email) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/auth/resend-otp',
        data: <String, dynamic>{'email': email},
      );
      final responseData = response.data ?? {};
      return ApiResponse<void>.fromJson(responseData, (json) {});
    } on DioException catch (e) {
      return ApiResponse<void>(
        success: false,
        message: _handleError(e).message,
        timestamp: DateTime.now().toString(),
      );
    }
  }

  Future<ApiResponse<void>> forgotPassword(String email) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: <String, dynamic>{'email': email},
      );
      final responseData = response.data ?? {};
      return ApiResponse<void>.fromJson(responseData, (json) {});
    } on DioException catch (e) {
      return ApiResponse<void>(
        success: false,
        message: _handleError(e).message,
        timestamp: DateTime.now().toString(),
      );
    }
  }

  Future<ApiResponse<void>> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/auth/reset-password',
        data: {
          'email': email,
          'code': code,
          'newPassword': newPassword,
        },
      );
      final responseData = response.data ?? {};
      return ApiResponse<void>.fromJson(responseData, (json) {});
    } on DioException catch (e) {
      return ApiResponse<void>(
        success: false,
        message: _handleError(e).message,
        timestamp: DateTime.now().toString(),
      );
    }
  }

  /// Cihazdaki oturumu kapatır ve sunucuya bildirir.
  ///
  /// Sıra bilinçli: jeton önce okunur, sonra cihazdan jeton ve yenileme çerezi silinir,
  /// sunucu çağrısı okunan jetonla yapılır. Silme ağı beklemez; sunucuya ulaşılamasa da
  /// uygulama yeniden açıldığında oturum geri gelmez. Başlık açıkça verilir, çünkü
  /// AuthInterceptor jetonu depodan okur ve o an depo boştur.
  Future<void> logout() async {
    final String? token = await _secureStorage.read(key: StorageKeys.accessToken);
    await _secureStorage.delete(key: StorageKeys.accessToken);
    await _dioClient.cookieJar.deleteAll();
    if (token == null) return;
    try {
      await _dioClient.dio.post<Map<String, dynamic>>(
        '/auth/logout',
        options: Options(
          headers: {NetworkConstants.authorizationHeader: '${NetworkConstants.bearerPrefix}$token'},
        ),
      );
    } catch (_) {
      // Sunucuya ulaşılamadı: cihazdaki oturum yine kapandı; sunucudaki yenileme jetonu
      // kendi süresi dolunca geçersizleşir.
    }
  }

  ApiResponse<AuthModel> _handleError(DioException e) {
    String message = 'Sunucuya bağlanılamadı';

    if (e.response?.statusCode == 409) {
      message =
          'Eş zamanlı güncelleme çakışması: Veri başka bir yerde güncellenmiş. Lütfen sayfayı yenileyip tekrar deneyin.';
    } else if (e.response?.data != null) {
      final dynamic data = e.response!.data;
      if (data is Map<String, dynamic>) {
        message = (data['message'] as String?) ?? 'İşlem başarısız';
      } else if (data is String && data.contains('<!doctype html>')) {
        message = 'Sunucu içi hata oluştu (Geçersiz İstek)';
      } else {
        message = data.toString();
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Bağlantı zaman aşımına uğradı, bağlantınızı kontrol edin.';
    }

    return ApiResponse<AuthModel>(
      success: false,
      message: message,
      statusCode: e.response?.statusCode,
      timestamp: DateTime.now().toString(),
    );
  }
}
