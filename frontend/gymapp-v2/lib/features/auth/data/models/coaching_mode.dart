enum CoachingMode {
  online,
  yuzYuze,
  hibrit;

  /// Backend'den gelen string değeri Enum'a çevirir.
  static CoachingMode? fromString(String? value) {
    if (value == null) return null;
    switch (value.toUpperCase()) {
      case 'ONLINE':
        return CoachingMode.online;
      case 'YUZ_YUZE':
      case 'YÜZ YÜZE':
        return CoachingMode.yuzYuze;
      case 'HIBRIT':
        return CoachingMode.hibrit;
      default:
        return null;
    }
  }

  /// Enum değerini backend'in beklediği string formatına çevirir.
  String toJsonString() {
    switch (this) {
      case CoachingMode.online:
        return 'ONLINE';
      case CoachingMode.yuzYuze:
        return 'YUZ_YUZE';
      case CoachingMode.hibrit:
        return 'HIBRIT';
    }
  }

  /// UI'da kullanıcıya gösterilecek metni döner.
  String toUIString() {
    switch (this) {
      case CoachingMode.online:
        return 'Online';
      case CoachingMode.yuzYuze:
        return 'Yüz Yüze';
      case CoachingMode.hibrit:
        return 'Hibrit';
    }
  }
}
