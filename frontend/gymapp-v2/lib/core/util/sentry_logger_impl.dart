import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'app_logger.dart';

/// Sentry tabanlı AppLogger gerçeklemesi.
class SentryLoggerImpl implements AppLogger {
  bool _isInitialized = false;

  @override
  Future<void> init({required Future<void> Function() appRunner}) async {
    // Çift ilklendirmeyi engelle (Mimari v6 Hardening). DSN verilmemişse (yerel geliştirme,
    // test) Sentry hiç başlatılmaz; DSN kaynakta tutulmuyor, bkz. AppConfig.sentryDsn.
    if (_isInitialized || Sentry.isEnabled || AppConfig.sentryDsn.isEmpty) {
      await appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.tracesSampleRate = 1.0;
        options.attachStacktrace = true;
        options.sendDefaultPii = false; // Güvenlik anayasası gereği
        options.debug = false; // Terminal kirliliğini engelle
      },
      appRunner: () async {
        _isInitialized = true;
        await appRunner();
      },
    );
  }

  @override
  Future<void> maintenance() async {
    // Sentry cache ve scope temizliği
    await Sentry.configureScope((scope) => scope.clear());
  }

  @override
  void error(
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, String>? tags,
  }) {
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (tags != null) {
          tags.forEach((key, value) {
            scope.setTag(key, value);
          });
        }
      },
    );
  }

  @override
  void info(String message, {Map<String, dynamic>? data}) {
    // Terminal debug akışı için yerel konsola yazdır
    // ignore: avoid_print
    print('[INFO] $message ${data ?? ""}');

    // Sentry panel kirliliğini önlemek için Message yerine Breadcrumb olarak ekle
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        data: data,
        level: SentryLevel.info,
        category: 'app.info',
      ),
    );
  }

  @override
  void breadcrumb(
    String message, {
    String? category,
    Map<String, dynamic>? data,
  }) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        data: data,
        level: SentryLevel.info,
      ),
    );
  }

  @override
  void setUser(String id, {String? email, String? username}) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(id: id, email: email, username: username));
    });
  }

  @override
  void clearUser() {
    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  @override
  void attachToDio(dynamic dio) {
    if (dio is Dio) {
      dio.addSentry();
    }
  }

  @override
  dynamic getNavigatorObserver() {
    return SentryNavigatorObserver();
  }
}
