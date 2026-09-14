enum DietSource {
  coach,
  client,
  system;

  /// Backend'den gelen string değeri Enum'a çevirir.
  static DietSource fromString(String? source) {
    switch (source?.toUpperCase()) {
      case 'COACH':
        return DietSource.coach;
      case 'CLIENT':
        return DietSource.client;
      case 'SYSTEM':
        return DietSource.system;
      default:
        return DietSource.system; // Varsayılan olarak sistem
    }
  }

  /// Enum değerini backend'in beklediği string formatına çevirir.
  String toJsonString() {
    switch (this) {
      case DietSource.coach:
        return 'COACH';
      case DietSource.client:
        return 'CLIENT';
      case DietSource.system:
        return 'SYSTEM';
    }
  }

  /// UI'da kullanıcıya gösterilecek metni döner.
  String toUIString() {
    switch (this) {
      case DietSource.coach:
        return 'Antrenör Programı';
      case DietSource.client:
        return 'Kendi Programım';
      case DietSource.system:
        return 'Sistem Önerisi';
    }
  }
}
