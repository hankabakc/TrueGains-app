import 'package:equatable/equatable.dart';
import 'message_status.dart';

class MessageModel extends Equatable {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderFullName;
  final String content;
  final MessageStatus status;
  final String? attachmentUrl;
  final DateTime sentAt;
  final int? packageId;
  final String? packageName;
  final double? packagePrice;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderFullName,
    required this.content,
    required this.status,
    this.attachmentUrl,
    required this.sentAt,
    this.packageId,
    this.packageName,
    this.packagePrice,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: _toInt(json['id']),
      conversationId: _toInt(json['conversationId']),
      senderId: _toInt(json['senderId']),
      senderFullName: (json['senderFullName'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      status: MessageStatus.fromApiValue(json['status'] as String?),
      attachmentUrl: json['attachmentUrl'] as String?,
      sentAt: DateTime.parse(json['sentAt'] as String).toLocal(),
      packageId: (json['packageId'] as num?)?.toInt(),
      packageName: json['packageName'] as String?,
      packagePrice: (json['packagePrice'] as num?)?.toDouble(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    return 0;
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        senderFullName,
        content,
        status,
        attachmentUrl,
        sentAt,
        packageId,
        packageName,
        packagePrice,
      ];

  MessageModel copyWith({
    int? id,
    int? conversationId,
    int? senderId,
    String? senderFullName,
    String? content,
    MessageStatus? status,
    String? attachmentUrl,
    DateTime? sentAt,
    int? packageId,
    String? packageName,
    double? packagePrice,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderFullName: senderFullName ?? this.senderFullName,
      content: content ?? this.content,
      status: status ?? this.status,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      sentAt: sentAt ?? this.sentAt,
      packageId: packageId ?? this.packageId,
      packageName: packageName ?? this.packageName,
      packagePrice: packagePrice ?? this.packagePrice,
    );
  }
}
