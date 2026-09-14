class CoachProfileResponseModel {
  final int userId;
  final String fullName;
  final String email;
  final String? profilePhotoUrl;
  final String? bio;
  final String? specialization;
  final String? instagramUrl;
  final String? websiteUrl;
  final String? tiktokUrl;
  final int? heightCm;
  final double? weightKg;
  final int? maxClients;

  CoachProfileResponseModel({
    required this.userId,
    required this.fullName,
    required this.email,
    this.profilePhotoUrl,
    this.bio,
    this.specialization,
    this.instagramUrl,
    this.websiteUrl,
    this.tiktokUrl,
    this.heightCm,
    this.weightKg,
    this.maxClients,
  });

  factory CoachProfileResponseModel.fromJson(Map<String, dynamic> json) {
    return CoachProfileResponseModel(
      userId: (json['userId'] as int?) ?? 0,
      fullName: (json['fullName'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      bio: json['bio'] as String?,
      specialization: json['specialization'] as String?,
      instagramUrl: json['instagramUrl'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      tiktokUrl: json['tiktokUrl'] as String?,
      heightCm: json['heightCm'] as int?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      maxClients: json['maxClients'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'profilePhotoUrl': profilePhotoUrl,
      'bio': bio,
      'specialization': specialization,
      'instagramUrl': instagramUrl,
      'websiteUrl': websiteUrl,
      'tiktokUrl': tiktokUrl,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'maxClients': maxClients,
    };
  }
}
