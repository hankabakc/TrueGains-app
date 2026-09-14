class ClientWaterTrackingModel {
  final int clientId;
  final String firstName;
  final String lastName;
  final String? profilePhotoUrl;
  final int targetWaterMl;
  final int consumedWaterMl;

  ClientWaterTrackingModel({
    required this.clientId,
    required this.firstName,
    required this.lastName,
    this.profilePhotoUrl,
    required this.targetWaterMl,
    required this.consumedWaterMl,
  });

  String get fullName => '$firstName $lastName'.trim();

  double get ratio {
    if (targetWaterMl <= 0) return 0.0;
    return (consumedWaterMl / targetWaterMl).clamp(0.0, 1.0);
  }

  factory ClientWaterTrackingModel.fromJson(Map<String, dynamic> json) {
    return ClientWaterTrackingModel(
      clientId: json['clientId'] as int,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      targetWaterMl: json['targetWaterMl'] as int? ?? 2500,
      consumedWaterMl: (json['consumedMl'] ?? json['consumedWaterMl'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'firstName': firstName,
      'lastName': lastName,
      'profilePhotoUrl': profilePhotoUrl,
      'targetWaterMl': targetWaterMl,
      'consumedWaterMl': consumedWaterMl,
    };
  }
}
