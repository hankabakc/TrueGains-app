import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'device_service.dart';
import 'offline_cache.dart';
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

      String? newAccessToken;
      try {
        final refreshResponse = await _dio.post<Map<String, dynamic>>(
          '/auth/refresh',
          data: {'deviceId': deviceId},
        );
        // Sunucu jetonu `access_token` adıyla döndürür (AuthResponse); AuthModel.fromJson da bunu okur.
        newAccessToken = (refreshResponse.data?['data'] as Map<String, dynamic>?)?['access_token'] as String?;
        if (newAccessToken != null) {
          await _storage.write(key: StorageKeys.accessToken, value: newAccessToken);
        }
      } catch (e) {
        // KR15 (G-82): sunucuya ulaşılamadıysa oturum açık kalır, çağırana özgün 401 gider (kuyruk sonra
        // dener). Sunucu yenilemeyi reddettiyse jeton silinir ve çıkış yapılır.
        if (!(e is DioException && OfflineCacheInterceptor.isUnreachable(e))) {
          await _storage.delete(key: StorageKeys.accessToken);
          sl<AuthBloc>().add(const LogoutRequested(syncPending: false));
        }
      } finally {
        // Kilit her yolda açılır; açık kalırsa sonraki her 401 sonsuza kadar bekler.
        for (final completer in _refreshQueue) {
          completer.complete(newAccessToken);
        }
        _refreshQueue.clear();
        _isRefreshing = false;
      }

      if (newAccessToken != null) {
        // Tekrarlanan isteğin kendi hatası (409, 422, bağlantı) oturumu kapatmaz; çağırana o hata gider.
        try {
          return handler.resolve(await _retry(err.requestOptions, newAccessToken));
        } on DioException catch (retryError) {
          return handler.next(retryError);
        }
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
