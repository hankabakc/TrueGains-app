enum Gender {
  male,
  female,
  other;

  /// Backend'den gelen string değeri Enum'a çevirir.
  static Gender fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'MALE':
        return Gender.male;
      case 'FEMALE':
        return Gender.female;
      case 'OTHER':
        return Gender.other;
      default:
        return Gender.other; // Varsayılan değer
    }
  }

  /// Enum değerini backend'in beklediği string formatına çevirir.
  String toJsonString() {
    switch (this) {
      case Gender.male:
        return 'MALE';
      case Gender.female:
        return 'FEMALE';
      case Gender.other:
        return 'OTHER';
    }
  }

  /// UI'da kullanıcıya gösterilecek metni döner.
  String toUIString() {
    switch (this) {
      case Gender.male:
        return 'Erkek';
      case Gender.female:
        return 'Kadın';
      case Gender.other:
        return 'Diğer';
    }
  }
}
