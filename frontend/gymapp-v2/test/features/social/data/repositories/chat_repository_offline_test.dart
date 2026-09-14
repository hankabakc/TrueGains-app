import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/network_info.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:gymapp_v2/features/social/data/models/message_model.dart';
import 'package:gymapp_v2/features/social/data/models/message_status.dart';
import 'package:gymapp_v2/features/social/data/repositories/chat_repository.dart';
import 'package:gymapp_v2/features/social/data/services/chat_api_service.dart';
import 'package:gymapp_v2/features/social/data/services/file_api_service.dart';
import 'package:mocktail/mocktail.dart';

class MockChatApiService extends Mock implements ChatApiService {}

class MockFileApiService extends Mock implements FileApiService {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockSyncManager extends Mock implements SyncManager {}

/// Çevrimdışı mesaj gönderimi (E2).
///
/// Buradaki kritik nokta: bağlantı yokken mesaj **kaybolmamalı**. Kullanıcı
/// gönder'e bastığı anda yazdığı metin giriş kutusundan siliniyor; kuyruğa
/// alınmazsa metin hiçbir yerde kalmaz.
void main() {
  late MockChatApiService api;
  late MockFileApiService fileApi;
  late MockNetworkInfo networkInfo;
  late MockSyncManager syncManager;
  late ChatRepository repository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    api = MockChatApiService();
    fileApi = MockFileApiService();
    networkInfo = MockNetworkInfo();
    syncManager = MockSyncManager();
    repository = ChatRepository(api, fileApi, networkInfo, syncManager);

    when(() => syncManager.addToQueue(any(), any())).thenAnswer((_) async {});
  });

  MessageModel sentMessage() => MessageModel(
        id: 1,
        conversationId: 10,
        senderId: 5,
        senderFullName: 'Ahmet',
        content: 'selam',
        status: MessageStatus.sent,
        sentAt: DateTime(2026, 1, 1),
      );

  test('bağlantı varken mesaj doğrudan gönderiliyor, kuyruğa dokunulmuyor', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => api.sendMessage(any(), any(), any(), any())).thenAnswer(
      (_) async => ApiResponse<MessageModel>(
        success: true,
        message: '',
        data: sentMessage(),
        timestamp: '2026-01-01T00:00:00Z',
      ),
    );

    final result = await repository.sendMessage(10, 'selam', null, null);

    expect(result.success, isTrue);
    expect(result.data, isNotNull);
    verifyNever(() => syncManager.addToQueue(any(), any()));
  });

  test('bağlantı yokken mesaj kuyruğa alınıyor ve sunucuya gidilmiyor', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);

    await repository.sendMessage(10, 'selam', null, 7);

    verifyNever(() => api.sendMessage(any(), any(), any(), any()));

    final captured = verify(
      () => syncManager.addToQueue(captureAny(), captureAny()),
    ).captured;

    expect(captured[0], '/social/chat/send');
    final payload = captured[1] as Map<String, dynamic>;
    expect(payload['conversationId'], 10);
    expect(payload['content'], 'selam');
    expect(payload['packageId'], 7);
  });

  test('kuyruğa alınan gönderim kullanıcıya bildiriliyor', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);

    final result = await repository.sendMessage(10, 'selam', null, null);

    // Mesaj henüz karşı tarafa ulaşmadı: sohbet listesine eklenmemeli.
    expect(result.data, isNull);
    // Kullanıcı "gönderilemedi" değil "sonra gönderilecek" bilgisini görmeli.
    expect(result.message, contains('internet'));
  });
}
