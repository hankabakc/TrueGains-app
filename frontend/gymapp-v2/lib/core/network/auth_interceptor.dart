import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'device_service.dart';
import '../constants/network_constants.dart';
import '../constants/storage_keys.dart';
import '../di/injection_container.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

/// GYMAPP-V2 Elite Auth Interceptor.
/// 1. Access Token ekler.
/// 2. Device Binding (Cihaz Kimliği) ekler.
/// 3. Otomatik Refresh Token yönetimi yapar.
class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final DeviceService _deviceService = DeviceService();

  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshQueue = [];

  AuthInterceptor(this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. Cihaz Kimliğini Ekle
    final deviceId = await _deviceService.getDeviceId();
    options.headers[NetworkConstants.deviceIdHeader] = deviceId;

    // 2. Access Token Ekle (Eğer Login/Register değilse)
    final bool isAuthRoute =
        options.path.contains('/auth/login') ||
        options.path.contains('/auth/register');
    if (!isAuthRoute) {
      final token = await _storage.read(key: StorageKeys.accessToken);
      if (token != null) {
        options.headers[NetworkConstants.authorizationHeader] =
            '${NetworkConstants.bearerPrefix}$token';
      }
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Refresh ucunun KENDİSİ 401 dönerse tekrar refresh deneme. Aksi halde
      // iç içe /auth/refresh çağrıları deadlock/sonsuz döngü yapar (geçersiz
      // refresh cookie'de, ör. cold start / süresi dolmuş oturum).
      if (err.requestOptions.path.contains('/auth/refresh')) {
        return handler.next(err);
      }

      // Eğer zaten bir refresh işlemi devam ediyorsa kuyruğa ekle ve bekle
      if (_isRefreshing) {
        final completer = Completer<String?>();
        _refreshQueue.add(completer);

        try {
          final newAccessToken = await completer.future;
          if (newAccessToken != null) {
            // Yeni token ile isteği tekrarla
            final retryResponse = await _retry(err.requestOptions, newAccessToken);
            return handler.resolve(retryResponse);
          }
        } catch (e) {
          return handler.next(err);
        }
        return handler.next(err);
      }

      // Refresh sürecini başlat
      _isRefreshing = true;
      final deviceId = await _deviceService.getDeviceId();

      try {
        final refreshResponse = await _dio.post<Map<String, dynamic>>(
          '/auth/refresh',
          data: {'deviceId': deviceId},
        );

        if (refreshResponse.statusCode == 200) {
          final Map<String, dynamic>? responseData = refreshResponse.data;
          final String? newAccessToken =
              (responseData?['data'] as Map<String, dynamic>?)?['accessToken']
                  as String?;

          if (newAccessToken != null) {
            await _storage.write(
              key: StorageKeys.accessToken,
              value: newAccessToken,
            );

            // Kuyruktaki bekleyen tüm isteklere yeni token'ı dağıt
            for (var completer in _refreshQueue) {
              completer.complete(newAccessToken);
            }
            _refreshQueue.clear();
            _isRefreshing = false;

            // Mevcut (ilk hata alan) isteği yeni token ile tekrarla
            final retryResponse = await _retry(err.requestOptions, newAccessToken);
            return handler.resolve(retryResponse);
          }
        }
      } catch (e) {
        // Refresh başarısızsa kuyruğu null ile serbest bırak ve token'ı sil
        for (var completer in _refreshQueue) {
          completer.complete(null);
        }
        _refreshQueue.clear();
        _isRefreshing = false;
        await _storage.delete(key: StorageKeys.accessToken);

        // Oturumu kapat ve login sayfasına yönlendirilmeyi tetikle
        sl<AuthBloc>().add(LogoutRequested());
      }
    }
    return handler.next(err);
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions, String token) {
    requestOptions.headers[NetworkConstants.authorizationHeader] =
        '${NetworkConstants.bearerPrefix}$token';

    return _dio.request<dynamic>(
      requestOptions.path,
      options: Options(
        method: requestOptions.method,
        headers: requestOptions.headers,
      ),
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
    );
  }
}
