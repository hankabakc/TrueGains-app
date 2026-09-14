import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import 'package:gymapp_v2/core/config/app_config.dart';
import 'package:gymapp_v2/features/social/data/repositories/chat_repository.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/message_status.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;
  List<MessageModel> _currentMessages = [];
  List<ConversationModel> _cachedConversations = [];
  int? _currentUserId;

  ChatBloc(this._repository) : super(ChatInitial()) {
    on<ConversationsRequested>((event, emit) async {
      try {
        if (_cachedConversations.isEmpty) {
          emit(ChatLoading());
        }

        final result = await _repository.getMyConversations();
        if (result.success && result.data != null) {
          _cachedConversations = result.data!;
          emit(ConversationsLoaded(_cachedConversations, lastUpdated: DateTime.now()));
        } else {
          if (_cachedConversations.isEmpty) {
            emit(ChatError(result.message));
          } else {
            emit(ConversationsLoaded(_cachedConversations, lastUpdated: DateTime.now()));
          }
        }
      } catch (e) {
        if (_cachedConversations.isEmpty) {
          emit(ChatError(friendlyError(e)));
        } else {
          emit(ConversationsLoaded(_cachedConversations, lastUpdated: DateTime.now()));
        }
      }
    });

    on<GlobalConversationSubscriptionRequested>((event, emit) {
      _repository.subscribeToConversationUpdates(
        userId: event.userId,
        wsUrl: AppConfig.wsUrl,
        onConversationUpdated: (conversation) {
          add(ConversationUpdated(conversation));
        },
      );
    });

    on<ConversationUpdated>((event, emit) {
      final index = _cachedConversations.indexWhere(
        (c) => c.id == event.conversation.id,
      );

      if (index != -1) {
        _cachedConversations[index] = event.conversation;
      } else {
        _cachedConversations.insert(0, event.conversation);
      }

      // Tarihe göre sırala (isteğe bağlı ama önerilir)
      _cachedConversations.sort((a, b) {
        if (a.lastMessageAt == null) return 1;
        if (b.lastMessageAt == null) return -1;
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      });

      if (state is ConversationsLoaded) {
        emit(ConversationsLoaded(List.from(_cachedConversations), lastUpdated: DateTime.now()));
      } else if (state is MessagesLoaded) {
        emit((state as MessagesLoaded).copyWith(conversations: List.from(_cachedConversations)));
      }
    });

    on<ChatInitiationRequested>((event, emit) async {
      try {
        emit(ChatLoading());
        final result = await _repository.initiateConversation(
          event.targetUserId,
        );
        if (result.success && result.data != null) {
          emit(ChatInitiated(result.data!));
        } else {
          emit(ChatError(result.message));
        }
      } catch (e) {
        emit(ChatError(friendlyError(e)));
      }
    });

    on<MessagesRequested>((event, emit) async {
      try {
        _repository.unsubscribeFromConversation();
        _currentMessages = [];
        _currentUserId = event.currentUserId;

        emit(ChatLoading());

        await _repository.markAsRead(event.conversationId);

        final result = await _repository.getMessages(event.conversationId);
        if (result.success && result.data != null) {
          _currentMessages = result.data!;
          emit(
            MessagesLoaded(
              List.from(_currentMessages),
              conversations: _cachedConversations,
            ),
          );
          _subscribeToConversation(event.conversationId);
        } else {
          emit(ChatError(result.message));
        }
      } catch (e) {
        emit(ChatError(friendlyError(e)));
      }
    });

    on<MessageSubmitted>((event, emit) async {
      try {
        final result = await _repository.sendMessage(
          event.conversationId,
          event.content,
          event.attachmentUrl,
          event.packageId,
          senderId: _currentUserId,
        );
        if (result.success && result.data != null) {
          add(NewMessageReceived(result.data!, currentUserId: _currentUserId));
        } else {
          _emitSendFailure(emit, result.message);
        }
      } catch (e) {
        _emitSendFailure(emit, friendlyError(e));
      }
    });

    on<NewMessageReceived>((event, emit) async {
      if (state is MessagesLoaded) {
        final conversationId = event.message.conversationId;
        final isIncoming = event.currentUserId != null && event.message.senderId != event.currentUserId;
        final isUnread = event.message.status != MessageStatus.read;
        
        if (isIncoming && isUnread) {
          _repository.markAsRead(conversationId);
        }
      }

      final index = _currentMessages.indexWhere(
        (m) => m.id == event.message.id,
      );
      if (index != -1) {
        final existing = _currentMessages[index];
        final keptStatus = existing.status.index > event.message.status.index ? existing.status : event.message.status;
        _currentMessages[index] = event.message.copyWith(status: keptStatus);
      } else {
        // Kuyruktaki mesaj sunucuya ulaşınca gerçek id ile geri geliyor. Geçici balonu
        // silmezsek aynı mesaj ekranda iki kez görünür.
        final int pendingIndex = _currentMessages.indexWhere(
          (m) =>
              m.id < 0 &&
              m.conversationId == event.message.conversationId &&
              m.senderId == event.message.senderId &&
              m.content == event.message.content,
        );
        if (pendingIndex != -1) {
          _currentMessages[pendingIndex] = event.message;
        } else {
          _currentMessages.add(event.message);
        }
      }

      final bool isUploading = state is MessagesLoaded ? (state as MessagesLoaded).isUploading : false;

      emit(
        MessagesLoaded(
          List.from(_currentMessages),
          conversations: _cachedConversations,
          isUploading: isUploading,
        ),
      );
    });

    on<BulkMessagesRead>((event, emit) {
      if (state is MessagesLoaded) {
        bool changed = false;
        for (final id in event.messageIds) {
          final index = _currentMessages.indexWhere((m) => m.id == id);
          if (index != -1 && _currentMessages[index].status != MessageStatus.read) {
            _currentMessages[index] = _currentMessages[index].copyWith(status: MessageStatus.read);
            changed = true;
          }
        }

        if (changed) {
          emit((state as MessagesLoaded).copyWith(messages: List.from(_currentMessages)));
        }
      }
    });

    on<FileUploadStatusChanged>((event, emit) {
      if (state is MessagesLoaded) {
        emit((state as MessagesLoaded).copyWith(isUploading: event.isUploading));
      }
    });

    on<ResetChatState>((event, emit) async {
      _repository.unsubscribeFromConversation();
      _currentMessages = [];
      // Sohbet listesine geri dönüşte güncel veriyi çek
      try {
        final result = await _repository.getMyConversations();
        if (result.success && result.data != null) {
          _cachedConversations = result.data!;
        }
      } catch (_) {
        // Hata durumunda cache'deki eski veriyi kullan
      }
      emit(ConversationsLoaded(List.from(_cachedConversations), lastUpdated: DateTime.now()));
    });
  }

  /// Gönderim hatasında açık sohbet ekranda kalmalı.
  ///
  /// `ChatError` yayınlamak, ekranın mesaj listesini hata metniyle değiştirmesine
  /// yol açıyordu: tek bir başarısız gönderim yüzünden kullanıcı tüm yazışmayı
  /// kaybediyor ve geri dönmenin yolunu bulamıyordu. Yüklenmiş mesaj varken
  /// liste korunur, hata yalnızca uyarı olarak taşınır. (Sohbet listesi tarafında
  /// aynı yaklaşım zaten uygulanıyordu.)
  void _emitSendFailure(Emitter<ChatState> emit, String message) {
    if (state is MessagesLoaded) {
      emit(
        MessagesLoaded(
          List.from(_currentMessages),
          conversations: _cachedConversations,
          sendError: message,
        ),
      );
    } else {
      emit(ChatError(message));
    }
  }

  void _subscribeToConversation(int conversationId) {
    _repository.subscribeToConversation(
      conversationId: conversationId,
      wsUrl: AppConfig.wsUrl,
      onMessageReceived: (message) {
        add(NewMessageReceived(message, currentUserId: _currentUserId));
      },
      onBulkReadReceived: (messageIds) {
        add(BulkMessagesRead(conversationId: conversationId, messageIds: messageIds));
      },
    );
  }

  @override
  Future<void> close() {
    _repository.dispose();
    return super.close();
  }
}
