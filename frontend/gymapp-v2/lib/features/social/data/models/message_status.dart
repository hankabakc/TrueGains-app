enum MessageStatus {
  sent,
  delivered,
  read;

  String get apiValue {
    return switch (this) {
      MessageStatus.sent => 'SENT',
      MessageStatus.delivered => 'DELIVERED',
      MessageStatus.read => 'READ',
    };
  }

  static MessageStatus fromApiValue(String? value) {
    return switch (value?.toUpperCase()) {
      'SENT' => MessageStatus.sent,
      'DELIVERED' => MessageStatus.delivered,
      'READ' => MessageStatus.read,
      _ => MessageStatus.sent,
    };
  }
}
