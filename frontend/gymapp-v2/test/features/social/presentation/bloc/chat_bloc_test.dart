import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/features/social/data/models/conversation_model.dart';
import 'package:gymapp_v2/features/social/data/models/message_model.dart';
import 'package:gymapp_v2/features/social/data/models/message_status.dart';
import 'package:gymapp_v2/features/social/data/repositories/chat_repository.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/chat_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRepository extends Mock implements ChatRepository {}

ApiResponse<T> ok<T>(T? data) =>
    ApiResponse<T>(success: true, message: '', data: data, timestamp: '2026-01-01T00:00:00Z');

ApiResponse<T> fail<T>(String message) =>
    ApiResponse<T>(success: false, message: message, data: null, timestamp: '2026-01-01T00:00:00Z');

/// Sohbet ekranının veri davranışı.
///
/// Buradaki en pahalı hata mesajın gitmemesi değil, **ekrandaki yazışmanın
/// kaybolmasıdır**: geçici bir ağ hatası yüzünden kullanıcı tüm sohbeti
/// göremez hâle gelirse, kaybolan şey tek bir mesaj değil geçmişin tamamıdır.
void main() {
  late MockChatRepository repository;

  MessageModel message(int id, {MessageStatus status = MessageStatus.sent, int senderId = 1}) {
    return MessageModel(
      id: id,
      conversationId: 10,
      senderId: senderId,
      senderFullName: 'Ahmet',
      content: 'Mesaj $id',
      status: status,
      sentAt: DateTime(2026, 1, 1, 12, id),
    );
  }

  ConversationModel conversation(int id) {
    return ConversationModel(
      id: id,
      clientId: 1,
      clientFullName: 'Ahmet',
      coachId: 2,
      coachFullName: 'Koç Ali',
      lastMessageAt: DateTime(2026, 1, 1, 12),
      lastMessagePreview: 'Selam',
      unreadCount: 0,
      isActive: true,
    );
  }

  setUp(() {
    repository = MockChatRepository();
    when(() => repository.markAsRead(any())).thenAnswer((_) async => ok<void>(null));
    when(() => repository.unsubscribeFromConversation()).thenReturn(null);
    when(() => repository.subscribeToConversation(
          conversationId: any(named: 'conversationId'),
          wsUrl: any(named: 'wsUrl'),
          onMessageReceived: any(named: 'onMessageReceived'),
          onBulkReadReceived: any(named: 'onBulkReadReceived'),
        )).thenAnswer((_) async {});
  });

  /// Sohbeti açılmış duruma getirir; gönderim testleri bunun üstüne kurulur.
  Future<void> openConversation(ChatBloc bloc, List<MessageModel> messages) async {
    when(() => repository.getMessages(10)).thenAnswer((_) async => ok(messages));
    bloc.add(const MessagesRequested(10, 1));
    await Future<void>.delayed(Duration.zero);
  }

  group('mesaj gönderimi başarısız olduğunda', () {
    test('açık sohbet ekranda kalır', () async {
      final bloc = ChatBloc(repository);
      await openConversation(bloc, [message(1), message(2)]);

      when(() => repository.sendMessage(any(), any(), any(), any(), senderId: any(named: 'senderId')))
          .thenAnswer((_) async => fail<MessageModel>('Bağlantı hatası'));

      bloc.add(const MessageSubmitted(conversationId: 10, content: 'yeni'));
      await Future<void>.delayed(Duration.zero);

      // Kritik: durum ChatError'a düşerse ekran yazışmayı silip hata metni basar.
      expect(bloc.state, isA<MessagesLoaded>());
      expect((bloc.state as MessagesLoaded).messages, hasLength(2));
      await bloc.close();
    });

    test('kullanıcıya hata bildirilir', () async {
      final bloc = ChatBloc(repository);
      await openConversation(bloc, [message(1)]);

      when(() => repository.sendMessage(any(), any(), any(), any(), senderId: any(named: 'senderId')))
          .thenAnswer((_) async => fail<MessageModel>('Bağlantı hatası'));

      bloc.add(const MessageSubmitted(conversationId: 10, content: 'yeni'));
      await Future<void>.delayed(Duration.zero);

      // Sessizce yutulmamalı: mesaj gitmediyse kullanıcı bunu bilmeli.
      expect((bloc.state as MessagesLoaded).sendError, 'Bağlantı hatası');
      await bloc.close();
    });

    test('hiç mesaj yüklenmemişken hata ekranı gösterilir', () async {
      final bloc = ChatBloc(repository);

      when(() => repository.sendMessage(any(), any(), any(), any(), senderId: any(named: 'senderId')))
          .thenAnswer((_) async => fail<MessageModel>('Hata'));

      bloc.add(const MessageSubmitted(conversationId: 10, content: 'yeni'));
      await Future<void>.delayed(Duration.zero);

      // Gösterilecek yazışma yoksa hata ekranı doğru davranıştır.
      expect(bloc.state, isA<ChatError>());
      await bloc.close();
    });
  });

  group('çevrimdışı mesaj gönderimi', () {
    test('çevrimdışı gönderimde geçici balon listeye ekleniyor', () async {
      final bloc = ChatBloc(repository);
      await openConversation(bloc, []);

      final pendingMessage = MessageModel(
        id: -12345,
        conversationId: 10,
        senderId: 1,
        senderFullName: '',
        content: 'çevrimdışı mesaj',
        status: MessageStatus.sent,
        sentAt: DateTime(2026, 1, 1, 12, 0),
      );

      when(() => repository.sendMessage(
            any(),
            any(),
            any(),
            any(),
            senderId: any(named: 'senderId'),
          )).thenAnswer((_) async => ok(pendingMessage));

      bloc.add(const MessageSubmitted(conversationId: 10, content: 'çevrimdışı mesaj'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<MessagesLoaded>());
      final loaded = bloc.state as MessagesLoaded;
      expect(loaded.messages, hasLength(1));
      expect(loaded.messages.single.id, isNegative);
      await bloc.close();
    });

    test('gerçek mesaj gelince geçici balon değişiyor, kopya oluşmuyor', () async {
      final bloc = ChatBloc(repository);
      await openConversation(bloc, []);

      final pendingMessage = MessageModel(
        id: -12345,
        conversationId: 10,
        senderId: 1,
        senderFullName: '',
        content: 'çevrimdışı mesaj',
        status: MessageStatus.sent,
        sentAt: DateTime(2026, 1, 1, 12, 0),
      );

      when(() => repository.sendMessage(
            any(),
            any(),
            any(),
            any(),
            senderId: any(named: 'senderId'),
          )).thenAnswer((_) async => ok(pendingMessage));

      bloc.add(const MessageSubmitted(conversationId: 10, content: 'çevrimdışı mesaj'));
      await Future<void>.delayed(Duration.zero);

      final realMessage = MessageModel(
        id: 999,
        conversationId: 10,
        senderId: 1,
        senderFullName: 'Ahmet',
        content: 'çevrimdışı mesaj',
        status: MessageStatus.sent,
        sentAt: DateTime(2026, 1, 1, 12, 1),
      );

      bloc.add(NewMessageReceived(realMessage, currentUserId: 1));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<MessagesLoaded>());
      final loaded = bloc.state as MessagesLoaded;
      expect(loaded.messages, hasLength(1));
      expect(loaded.messages.single.id, 999);
      expect(loaded.messages.single.id, isPositive);
      await bloc.close();
    });
  });

  group('gelen mesajlar', () {
    test('aynı mesaj iki kez gelirse listeye iki kez eklenmez', () async {
      final bloc = ChatBloc(repository);
      await openConversation(bloc, [message(1)]);

      bloc.add(NewMessageReceived(message(2), currentUserId: 1));
      bloc.add(NewMessageReceived(message(2), currentUserId: 1));
      await Future<void>.delayed(Duration.zero);

      expect((bloc.state as MessagesLoaded).messages, hasLength(2));
      await bloc.close();
    });

    test('okundu bilgisi geri alınmaz', () async {
      final bloc = ChatBloc(repository);
      await openConversation(bloc, [message(1, status: MessageStatus.read)]);

      // Sunucudan gecikmiş bir kopya gelirse tik geri gitmemeli.
      bloc.add(NewMessageReceived(message(1, status: MessageStatus.sent), currentUserId: 1));
      await Future<void>.delayed(Duration.zero);

      expect((bloc.state as MessagesLoaded).messages.first.status, MessageStatus.read);
      await bloc.close();
    });
  });

  group('sohbet listesi', () {
    blocTest<ChatBloc, ChatState>(
      'yenileme başarısız olursa eski liste ekranda kalır',
      build: () {
        when(() => repository.getMyConversations())
            .thenAnswer((_) async => ok([conversation(1)]));
        return ChatBloc(repository);
      },
      act: (bloc) async {
        bloc.add(ConversationsRequested());
        await Future<void>.delayed(Duration.zero);

        when(() => repository.getMyConversations())
            .thenAnswer((_) async => fail<List<ConversationModel>>('Sunucuya ulaşılamadı'));
        bloc.add(ConversationsRequested());
      },
      verify: (bloc) {
        expect(bloc.state, isA<ConversationsLoaded>());
        expect((bloc.state as ConversationsLoaded).conversations, hasLength(1));
      },
    );
  });
}
