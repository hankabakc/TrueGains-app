// ignore_for_file: constant_identifier_names

/// Kullanıcı rollerini temsil eden Enum yapısı.
///
/// [CLIENT]: Normal kullanıcı (Sporcu)
/// [COACH]: Antrenör
/// [ADMIN]: Yönetici
enum UserRole {
  CLIENT,
  COACH,
  ADMIN;

  /// Backend'den gelen String değeri [UserRole] enum yapısına çevirir.
  ///
  /// Eğer değer eşleşmezse varsayılan olarak [CLIENT] döner.
  static UserRole fromString(String? role) {
    switch (role?.toUpperCase()) {
      case 'CLIENT':
        return UserRole.CLIENT;
      case 'COACH':
        return UserRole.COACH;
      case 'ADMIN':
        return UserRole.ADMIN;
      default:
        return UserRole.CLIENT;
    }
  }

  /// Backend'e gönderilecek String değerini döner.
  String toJsonString() {
    switch (this) {
      case UserRole.CLIENT:
        return 'CLIENT';
      case UserRole.COACH:
        return 'COACH';
      case UserRole.ADMIN:
        return 'ADMIN';
    }
  }

  /// Kullanıcı arayüzünde (UI) gösterilecek Türkçe karşılığını döner.
  String toUIString() {
    switch (this) {
      case UserRole.CLIENT:
        return 'Sporcu';
      case UserRole.COACH:
        return 'Antrenör';
      case UserRole.ADMIN:
        return 'Yönetici';
    }
  }
}
