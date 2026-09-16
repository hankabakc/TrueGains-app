import 'user_role.dart';

class AuthModel {
  final UserModel user;
  final String accessToken;
  final String tokenType;
  final int expiresIn;

  AuthModel({
    required this.user,
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  // Getter'lar sayesinde eski kodlar (auth.id, auth.email) kırılmadan çalışır.
  // role artık tip güvenli (UserRole) döner.
  int get id => user.id;
  String get email => user.email;
  UserRole get role => user.role;

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      accessToken: json['access_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresIn: json['expires_in'] as int? ?? 0,
    );
  }
}

class UserModel {
  final int id;
  final String email;
  final UserRole role;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _toInt(json['id']),
      email: json['email'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String?),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'email': email,
        'role': role.toJsonString(),
      };

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    return 0;
  }
}
