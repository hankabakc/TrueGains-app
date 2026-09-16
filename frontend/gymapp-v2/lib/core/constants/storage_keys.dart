class StorageKeys {
  static const String accessToken = 'accessToken';
  static const String refreshToken = 'refreshToken';
  static const String defaultRestSeconds = 'defaultRestSeconds';

  /// Çevrimdışı okuma önbelleğinin (Hive) AES anahtarı.
  static const String offlineCacheKey = 'offlineCacheKey';

  /// Çevrimdışı yazma kuyruğunun (Hive) AES anahtarı.
  static const String syncQueueKey = 'syncQueueKey';

  /// Son giriş yapan kullanıcının kimliği/e-postası/rolü (JSON). İnternetsiz açılışta oturum bununla
  /// açılır (KR15); çıkışta silinir.
  static const String sessionUser = 'sessionUser';
}
