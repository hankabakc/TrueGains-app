import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';

/// Firebase Cloud Messaging (FCM) işlemlerini yöneten merkezi servis.
/// Uygulama içi (foreground) ve arka plan bildirimlerini dinler, cihaz token'ını yönetir.
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final DioClient _dioClient;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationService(this._dioClient);

  /// Servisi başlatır, izinleri ister ve token yönetimini kurar.
  Future<void> initialize() async {
    // 1. Yerel Bildirimleri Başlat (Foreground gösterimi için)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Bildirime tıklandığında yapılacak işlemler buraya eklenebilir
      },
    );

    // 2. Bildirim İzinlerini İste (iOS ve Android 13+ için kritik)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('🔔 FCM İzin Durumu: ${settings.authorizationStatus}');
    }

    // 3. Mevcut Cihaz Token'ını Al
    String? token = await _fcm.getToken();
    if (token != null) {
      await updateTokenOnBackend(token);
    }

    // 4. Token Yenilendiğinde Backend'i Güncelle
    _fcm.onTokenRefresh.listen((newToken) {
      updateTokenOnBackend(newToken);
    });

    // 5. Ön Plandayken (Foreground) Gelen Mesajları Dinle
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('🔔 Ön planda bildirim alındı!');
      }

      final notification = message.notification;
      if (notification != null) {
        _showLocalNotification(
          notification.title ?? 'Yeni Mesaj',
          notification.body ?? '',
        );
      }
    });
  }

  /// Uygulama ön plandayken bildirimi native popup olarak gösterir.
  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'chat_notifications', // Kanal ID
          'Sohbet Bildirimleri', // Kanal Adı
          channelDescription: 'Yeni mesaj bildirimleri için kullanılır.',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    await _localNotifications.show(
      id: DateTime.now().millisecond, // Benzersiz ID
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  /// Cihazın FCM token'ı backend'e gönderilerek kullanıcı ile eşleştirilir.
  Future<void> updateTokenOnBackend(String token) async {
    try {
      // Backend'deki /api/v1/users/device-token endpoint'ine POST isteği atar.
      // Veri formatı hizalaması: Backend ham string beklediği için 'text/plain' olarak zorlanır.
      await _dioClient.dio.post<Map<String, dynamic>>(
        '/users/device-token',
        data: token,
        options: Options(contentType: 'text/plain'),
      );
      if (kDebugMode) {
        print('✅ FCM Token backend üzerinde güncellendi.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM Token güncellenirken hata oluştu: $e');
      }
    }
  }
}
