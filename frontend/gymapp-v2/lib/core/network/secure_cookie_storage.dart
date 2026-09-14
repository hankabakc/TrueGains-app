import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// cookie_jar `Storage`'ını flutter_secure_storage üzerinde kalıcı ve şifreli tutar.
///
/// Refresh-token cookie'si uygulama yeniden açılışında hayatta kalır; böylece
/// açılış (splash) ekranı `/auth/refresh` ile oturumu sessizce geri yükleyebilir
/// ("oturumda kal"). Erişim token'ı zaten secure storage'da tutuluyor; refresh
/// cookie'sini de aynı şifreli katmanda saklamak tutarlıdır.
class SecureCookieStorage implements Storage {
  SecureCookieStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _prefix = 'cookie_';

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) => _storage.read(key: '$_prefix$key');

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: '$_prefix$key', value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: '$_prefix$key');

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      await _storage.delete(key: '$_prefix$key');
    }
  }
}
