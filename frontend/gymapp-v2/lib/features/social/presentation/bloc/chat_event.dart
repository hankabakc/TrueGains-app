part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class ConversationsRequested extends ChatEvent {}

class ResetChatState extends ChatEvent {}

class ChatInitiationRequested extends ChatEvent {
  final int targetUserId;
  const ChatInitiationRequested(this.targetUserId);
  @override
  List<Object?> get props => [targetUserId];
}

class MessagesRequested extends ChatEvent {
  final int conversationId;
  final int currentUserId;
  const MessagesRequested(this.conversationId, this.currentUserId);
  @override
  List<Object?> get props => [conversationId, currentUserId];
}

class MessageSubmitted extends ChatEvent {
  final int conversationId;
  final String? content;
  final String? attachmentUrl;
  final int? packageId;

  const MessageSubmitted({
    required this.conversationId,
    this.content,
    this.attachmentUrl,
    this.packageId,
  });

  @override
  List<Object?> get props => [conversationId, content, attachmentUrl, packageId];
}

class NewMessageReceived extends ChatEvent {
  final MessageModel message;
  final int? currentUserId;
  const NewMessageReceived(this.message, {this.currentUserId});
  @override
  List<Object?> get props => [message, currentUserId];
}

class FileUploadStatusChanged extends ChatEvent {
  final bool isUploading;
  const FileUploadStatusChanged(this.isUploading);
  @override
  List<Object?> get props => [isUploading];
}

class BulkMessagesRead extends ChatEvent {
  final int conversationId;
  final List<int> messageIds;
  const BulkMessagesRead({required this.conversationId, required this.messageIds});
  @override
  List<Object?> get props => [conversationId, messageIds];
}

class ConversationUpdated extends ChatEvent {
  final ConversationModel conversation;
  const ConversationUpdated(this.conversation);
  @override
  List<Object?> get props => [conversation];
}

class GlobalConversationSubscriptionRequested extends ChatEvent {
  final int userId;
  const GlobalConversationSubscriptionRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}
