import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
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

class MockDioClient extends Mock implements DioClient {}

class MockDio extends Mock implements Dio {}

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
    when(() => api.sendMessage(any(), any(), any(), any(), localId: any(named: 'localId'))).thenAnswer(
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

    verifyNever(() => api.sendMessage(any(), any(), any(), any(), localId: any(named: 'localId')));

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

  test('çevrimiçi mesaj yerel kimlik taşır', () async {
    final uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => api.sendMessage(any(), any(), any(), any(), localId: any(named: 'localId')))
        .thenAnswer((_) async => ApiResponse<MessageModel>(
              success: true,
              message: '',
              data: sentMessage(),
              timestamp: '2026-01-01T00:00:00Z',
            ));

    await repository.sendMessage(10, 'selam', null, null);

    final captured = verify(() => api.sendMessage(10, 'selam', null, null, localId: captureAny(named: 'localId')))
        .captured
        .single as String;
    expect(captured, matches(uuidPattern));
  });

  test('kuyruğa alınan mesaj yerel kimlik taşır', () async {
    final uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);

    await repository.sendMessage(10, 'selam', null, null);

    final payload = verify(() => syncManager.addToQueue(any(), captureAny())).captured.single as Map<String, dynamic>;
    expect(payload['localId'], matches(uuidPattern));
  });

  test('api servisi yerel kimliği gövdeye koyar', () async {
    final dioClient = MockDioClient();
    final dio = MockDio();
    when(() => dioClient.dio).thenReturn(dio);
    when(() => dio.post<Map<String, dynamic>>('/social/chat/send', data: any(named: 'data')))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/social/chat/send'),
              statusCode: 200,
              data: {'success': true, 'message': '', 'timestamp': '2026-01-01T00:00:00Z'},
            ));

    await ChatApiService(dioClient).sendMessage(10, 'selam', null, null, localId: 'yerel-1');

    final captured = (verify(() => dio.post<Map<String, dynamic>>('/social/chat/send', data: captureAny(named: 'data')))
        .captured
        .single as Map<String, dynamic>)['localId'];
    expect(captured, equals('yerel-1'));
  });

  test('kuyruğa alınan geçici balon kuyruk kaydıyla aynı yerel kimliği taşır', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);

    final result = await repository.sendMessage(10, 'selam', null, null, senderId: 5);

    final payload = verify(() => syncManager.addToQueue(any(), captureAny())).captured.single as Map<String, dynamic>;

    expect(result.data!.id, isNegative);
    expect(result.data!.localId, isNotNull);
    expect(result.data!.localId, equals(payload['localId']));
  });

  test('geçici balon durum güncellemesinde yerel kimliğini kaybetmez', () {
    final MessageModel pending = sentMessage().copyWith(id: -1, localId: 'L1');
    expect(pending.copyWith(status: MessageStatus.read).localId, equals('L1'));
  });
}

