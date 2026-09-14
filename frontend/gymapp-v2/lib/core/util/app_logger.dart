/// GYMAPP-V2 Merkezi Loglama Arayüzü.
/// Gelecekte Sentry yerine başka bir araç (Firebase Crashlytics vb.)
/// kullanılmak istendiğinde sadece implementation sınıfı değiştirilir.
abstract class AppLogger {
  /// Logger'ı harici servislerle (Örn: Sentry) başlatır.
  Future<void> init({required Future<void> Function() appRunner});

  /// Bir istisnayı (Exception) harici servise raporlar.
  void error(dynamic error, {StackTrace? stackTrace, Map<String, String>? tags});

  /// Bilgilendirme mesajı kaydeder.
  void info(String message, {Map<String, dynamic>? data});

  /// Hata anında bağlam sağlamak için breadcrumb (ekmek kırıntısı) ekler.
  void breadcrumb(String message, {String? category, Map<String, dynamic>? data});

  /// Kullanıcı kimliğini logger'a bağlar.
  void setUser(String id, {String? email, String? username});

  /// Kullanıcıyı logger'dan temizler.
  void clearUser();

  /// Logger'ı ağ istemcisine (Dio) bağlar.
  void attachToDio(dynamic dio);

  /// Navigasyon hareketlerini izlemek için observer döner.
  dynamic getNavigatorObserver();

  /// Uygulama başlangıcında cache temizliği ve bakım işlemlerini yürütür.
  Future<void> maintenance();
  }
