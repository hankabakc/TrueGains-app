import 'package:dio/dio.dart';
import 'package:gymapp_v2/core/util/app_logger.dart';
import 'package:get_it/get_it.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import '../config/app_config.dart';
import 'auth_interceptor.dart';
import 'offline_cache.dart';
import 'cache_status.dart';
import 'secure_cookie_storage.dart';

/// Kurumsal Merkezi Ağ İstemcisi (Singleton).
/// Tüm API servisleri bu istemciyi kullanarak kod tekrarını önler.
class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;

  factory DioClient() {
    if (!_instance._initialized) {
      _instance._init();
    }
    return _instance;
  }

  bool _initialized = false;

  DioClient._internal();

  void _init() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Cookie desteği eklenir. Refresh-token cookie'si "oturumda kal" için
    // şifreli/kalıcı saklanır (uygulama yeniden açılışında hayatta kalır).
    dio.interceptors.add(CookieManager(PersistCookieJar(storage: SecureCookieStorage())));

    // Standart Auth/Security Katmanı
    dio.interceptors.add(AuthInterceptor(dio));

    // Çevrimdışı okuma: başarılı GET yanıtları saklanır, bağlantı yokken son bilinen
    // hâl döndürülür. AuthInterceptor'dan sonra eklenir; 401 yenileme akışına karışmaz.
    final sl = GetIt.instance;
    if (sl.isRegistered<OfflineCache>()) {
      final cacheStatus = sl.isRegistered<CacheStatusNotifier>() ? sl<CacheStatusNotifier>() : null;
      dio.interceptors.add(OfflineCacheInterceptor(sl<OfflineCache>(), cacheStatus));
    }

    // Merkezi Logger Ağ İzleme (Performans ve Hata İzleme)
    if (sl.isRegistered<AppLogger>()) {
      sl<AppLogger>().attachToDio(dio);
    }

    _initialized = true;
  }
}
