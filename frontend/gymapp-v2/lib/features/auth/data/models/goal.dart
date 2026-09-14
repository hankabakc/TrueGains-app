enum Goal {
  kiloVer,
  kasKazan,
  koru,
  performans,
  saglikliYasa;

  /// Backend'den gelen string değeri Enum'a çevirir.
  static Goal? fromString(String? value) {
    if (value == null) return null;
    switch (value.toUpperCase()) {
      case 'KILO_VER':
        return Goal.kiloVer;
      case 'KAS_KAZAN':
        return Goal.kasKazan;
      case 'KORU':
        return Goal.koru;
      case 'PERFORMANS':
        return Goal.performans;
      case 'SAGLIKLI_YASA':
        return Goal.saglikliYasa;
      default:
        return null;
    }
  }

  /// Enum değerini backend'in beklediği string formatına çevirir.
  String toJsonString() {
    switch (this) {
      case Goal.kiloVer:
        return 'KILO_VER';
      case Goal.kasKazan:
        return 'KAS_KAZAN';
      case Goal.koru:
        return 'KORU';
      case Goal.performans:
        return 'PERFORMANS';
      case Goal.saglikliYasa:
        return 'SAGLIKLI_YASA';
    }
  }

  /// UI'da kullanıcıya gösterilecek metni döner.
  String toUIString() {
    switch (this) {
      case Goal.kiloVer:
        return 'Kilo Ver';
      case Goal.kasKazan:
        return 'Kas Kazan';
      case Goal.koru:
        return 'Fit Kal / Koru';
      case Goal.performans:
        return 'Performans Artır';
      case Goal.saglikliYasa:
        return 'Sağlıklı Yaşa';
    }
  }
}
