import 'package:flutter/foundation.dart';

class AppConfig {
  /// API sunucusunun adresi.
  ///
  /// Varsayılan `10.0.2.2`: Android emülatöründen **host makineye** çıkan adres;
  /// bilgisayarın IP'si değiştiğinde bozulmaz. Aynı Wi-Fi'daki **gerçek cihaz** için
  /// bilgisayarın yerel IP'si verilir:
  ///   flutter run --dart-define=API_HOST=192.168.x.x
  /// Tam adresi vermek gerekirse `API_BASE_URL` her şeyi ezer (E2E komutu bunu kullanır).
  static const String _host = String.fromEnvironment('API_HOST', defaultValue: '10.0.2.2');

  /// Ortama ve platforma göre API URL'sini dinamik olarak belirler.
  static String get apiBaseUrl {
    const String envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) return 'http://localhost:8082/api/v1';

    // Hem emülatör hem gerçek cihaz için yerel IP kullanımı en güvenlisidir.
    return 'http://$_host:8082/api/v1';
  }

  /// WebSocket adresi **apiBaseUrl'den türetilir.** Ayrı bir sabit tutulursa
  /// `API_BASE_URL` ile adres değiştirildiğinde REST yeni sunucuya, WS eskisine gider
  /// ve canlı güncellemeler ekranda hata vermeden kopar.
  static String get wsUrl {
    final Uri api = Uri.parse(apiBaseUrl);
    final String scheme = api.scheme == 'https' ? 'wss' : 'ws';
    return '$scheme://${api.authority}/ws-raw';
  }

  /// Sunucudan gelen dosya adresini görüntülenebilir tam adrese çevirir.
  ///
  /// Ekler veritabanında yalnızca **yol** olarak tutuluyor (`/api/v1/files/...`);
  /// sunucu adı bilerek saklanmıyor, çünkü saklanan adres saldırganın sunucusunu
  /// gösterirse mesajı açan cihaz oraya istek atar ve IP'si sızar. Sunucu adını
  /// istemci kendi yapılandırmasından ekler.
  ///
  /// Eski kayıtlar mutlak adres taşıyabildiği için `http` ile başlayanlar olduğu gibi
  /// kullanılır.
  static String resolveFileUrl(String url) {
    final String origin = Uri.parse(apiBaseUrl).origin;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      final Uri saved = Uri.parse(url);
      // Eski kayıtlar mutlak adres taşıyor ve o adres dosyanın yüklendiği günkü
      // makinenin yerel ağ IP'si olabiliyor (veritabanında böyle kalıntılar var).
      // Yol bizim dosya ucumuzsa sunucu adını bugünküyle değiştir; yabancı adrese
      // (örn. tohum verisindeki pravatar) dokunma.
      if (saved.path.startsWith('/api/v1/files/')) return '$origin${saved.path}';
      return url;
    }
    return '$origin$url';
  }

  static const String appName = 'TrueGains';
  static const String apiVersion = 'v1';

  /// Mobil Sentry DSN'i. **Kaynakta tutulmaz**; derleme/çalıştırma komutunda verilir:
  ///   flutter build apk --dart-define=SENTRY_DSN=$SENTRY_DSN
  /// ya da `--dart-define-from-file=.env` (örnek: `.env.example`). Boşsa hata raporlama
  /// hiç başlatılmaz (bkz. `SentryLoggerImpl.init`).
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
}
