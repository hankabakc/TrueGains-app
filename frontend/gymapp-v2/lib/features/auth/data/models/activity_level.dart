enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extraActive;

  /// Backend'den gelen string değeri Enum'a çevirir.
  static ActivityLevel fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'SEDENTARY':
        return ActivityLevel.sedentary;
      case 'LIGHTLY_ACTIVE':
        return ActivityLevel.lightlyActive;
      case 'MODERATELY_ACTIVE':
        return ActivityLevel.moderatelyActive;
      case 'VERY_ACTIVE':
        return ActivityLevel.veryActive;
      case 'EXTRA_ACTIVE':
        return ActivityLevel.extraActive;
      default:
        return ActivityLevel.sedentary; // Varsayılan değer
    }
  }

  /// Enum değerini backend'in beklediği string formatına çevirir.
  String toJsonString() {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'SEDENTARY';
      case ActivityLevel.lightlyActive:
        return 'LIGHTLY_ACTIVE';
      case ActivityLevel.moderatelyActive:
        return 'MODERATELY_ACTIVE';
      case ActivityLevel.veryActive:
        return 'VERY_ACTIVE';
      case ActivityLevel.extraActive:
        return 'EXTRA_ACTIVE';
    }
  }

  /// UI'da kullanıcıya gösterilecek metni döner.
  String toUIString() {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Hareketsiz (Ofis işi)';
      case ActivityLevel.lightlyActive:
        return 'Az Hareketli (Haftada 1-3 gün spor)';
      case ActivityLevel.moderatelyActive:
        return 'Orta Hareketli (Haftada 3-5 gün spor)';
      case ActivityLevel.veryActive:
        return 'Çok Hareketli (Haftada 6-7 gün spor)';
      case ActivityLevel.extraActive:
        return 'Ekstra Hareketli (Ağır idman / Fiziksel iş)';
    }
  }
}
