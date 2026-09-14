import 'app_logger.dart';

/// Hiçbir işlem yapmayan (No-Operation) Logger gerçeklemesi.
/// Sentry kapalıyken veya testlerde kullanılabilir.
class NoOpLoggerImpl implements AppLogger {
  @override
  Future<void> init({required Future<void> Function() appRunner}) async {
    await appRunner();
  }

  @override
  void error(dynamic error, {StackTrace? stackTrace, Map<String, String>? tags}) {
    // İşlem yapma
  }

  @override
  void info(String message, {Map<String, dynamic>? data}) {
    // İşlem yapma
  }

  @override
  void breadcrumb(String message, {String? category, Map<String, dynamic>? data}) {
    // İşlem yapma
  }

  @override
  void setUser(String id, {String? email, String? username}) {
    // İşlem yapma
  }

  @override
  void clearUser() {
    // İşlem yapma
  }

  @override
  void attachToDio(dynamic dio) {
    // İşlem yapma
  }

  @override
  dynamic getNavigatorObserver() {
    return null; // Observer yok
  }

  @override
  Future<void> maintenance() async {
    // İşlem yapma
  }
}
