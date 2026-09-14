import 'package:equatable/equatable.dart';

class ConversationModel extends Equatable {
  final int id;
  final int clientId;
  final String clientFullName;
  final int coachId;
  final String coachFullName;
  final DateTime? lastMessageAt;
  final String lastMessagePreview;
  final int unreadCount;
  final bool isActive;

  const ConversationModel({
    required this.id,
    required this.clientId,
    required this.clientFullName,
    required this.coachId,
    required this.coachFullName,
    this.lastMessageAt,
    required this.lastMessagePreview,
    required this.unreadCount,
    required this.isActive,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: _toInt(json['id']),
      clientId: _toInt(json['clientId']),
      clientFullName: (json['clientFullName'] as String?) ?? '',
      coachId: _toInt(json['coachId']),
      coachFullName: (json['coachFullName'] as String?) ?? '',
      lastMessageAt:
          json['lastMessageAt'] != null
              ? DateTime.parse(json['lastMessageAt'] as String).toLocal()
              : null,
      lastMessagePreview: (json['lastMessagePreview'] as String?) ?? '',
      unreadCount: _toInt(json['unreadCount']),
      isActive: (json['isActive'] as bool?) ?? true,
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
        clientId,
        clientFullName,
        coachId,
        coachFullName,
        lastMessageAt,
        lastMessagePreview,
        unreadCount,
        isActive,
      ];

  ConversationModel copyWith({
    int? id,
    int? clientId,
    String? clientFullName,
    int? coachId,
    String? coachFullName,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    int? unreadCount,
    bool? isActive,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientFullName: clientFullName ?? this.clientFullName,
      coachId: coachId ?? this.coachId,
      coachFullName: coachFullName ?? this.coachFullName,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
    );
  }
}
