enum ExperienceLevel {
  baslangic,
  orta,
  ileri;

  /// Backend'den gelen string değeri Enum'a çevirir.
  static ExperienceLevel? fromString(String? value) {
    if (value == null) return null;
    switch (value.toUpperCase()) {
      case 'BEGINNER':
        return ExperienceLevel.baslangic;
      case 'INTERMEDIATE':
        return ExperienceLevel.orta;
      case 'ADVANCED':
        return ExperienceLevel.ileri;
      default:
        return null;
    }
  }

  /// Enum değerini backend'in beklediği string formatına çevirir.
  String toJsonString() {
    switch (this) {
      case ExperienceLevel.baslangic:
        return 'BEGINNER';
      case ExperienceLevel.orta:
        return 'INTERMEDIATE';
      case ExperienceLevel.ileri:
        return 'ADVANCED';
    }
  }

  /// UI'da kullanıcıya gösterilecek metni döner.
  String toUIString() {
    switch (this) {
      case ExperienceLevel.baslangic:
        return 'Başlangıç';
      case ExperienceLevel.orta:
        return 'Orta';
      case ExperienceLevel.ileri:
        return 'İleri';
    }
  }
}
