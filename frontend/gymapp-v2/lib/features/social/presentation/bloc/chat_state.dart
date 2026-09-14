part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];

  int get totalUnreadCount => 0;
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ConversationsLoaded extends ChatState {
  final List<ConversationModel> conversations;
  final DateTime? lastUpdated;
  const ConversationsLoaded(this.conversations, {this.lastUpdated});

  @override
  int get totalUnreadCount => conversations.fold(0, (sum, c) => sum + c.unreadCount);

  @override
  List<Object?> get props => [conversations, lastUpdated];
}

class ChatInitiated extends ChatState {
  final ConversationModel conversation;
  const ChatInitiated(this.conversation);
  @override
  List<Object?> get props => [conversation];
}

class MessagesLoaded extends ChatState {
  final List<MessageModel> messages;
  final List<ConversationModel> conversations;
  final bool isUploading;

  /// Gönderim hatası. Yalnızca hatanın oluştuğu emit'te doludur; sonraki
  /// durumlara taşınmaz (`copyWith` bilerek devretmez) ki aynı uyarı tekrar
  /// tekrar gösterilmesin.
  final String? sendError;

  const MessagesLoaded(this.messages, {
    this.conversations = const [],
    this.isUploading = false,
    this.sendError,
  });

  @override
  int get totalUnreadCount => conversations.fold(0, (sum, c) => sum + c.unreadCount);

  @override
  List<Object?> get props => [messages, conversations, isUploading, sendError];

  MessagesLoaded copyWith({
    List<MessageModel>? messages,
    List<ConversationModel>? conversations,
    bool? isUploading,
  }) {
    return MessagesLoaded(
      messages ?? this.messages,
      conversations: conversations ?? this.conversations,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
  @override
  List<Object?> get props => [message];
}
