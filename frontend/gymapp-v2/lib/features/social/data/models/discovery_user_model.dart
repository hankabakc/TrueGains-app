import 'package:gymapp_v2/features/auth/data/models/user_role.dart';

class DiscoveryUserModel {
  final int userId;
  final String? fullName;
  final String? bio;
  final String? profilePhotoUrl;
  final UserRole role;
  final String? specialization;
  final String? currency;
  final bool canSendRequest;
  final double? averageRating;
  final int reviewCount;
  final int activeStudentCount;
  final String? province;
  final String? district;
  final int? experienceYears;
  final double? minPackagePrice;

  DiscoveryUserModel({
    required this.userId,
    this.fullName,
    this.bio,
    this.profilePhotoUrl,
    required this.role,
    this.specialization,
    this.currency,
    this.canSendRequest = false,
    this.averageRating,
    this.reviewCount = 0,
    this.activeStudentCount = 0,
    this.province,
    this.district,
    this.experienceYears,
    this.minPackagePrice,
  });

  factory DiscoveryUserModel.fromJson(Map<String, dynamic> json) {
    return DiscoveryUserModel(
      userId: json['userId'] as int,
      fullName: json['fullName'] as String?,
      bio: json['bio'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      role: UserRole.fromString(json['role'] as String?),
      specialization: json['specialization'] as String?,
      currency: json['currency'] as String?,
      canSendRequest: json['canSendRequest'] as bool? ?? false,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      activeStudentCount: (json['activeStudentCount'] as num?)?.toInt() ?? 0,
      province: json['province'] as String?,
      district: json['district'] as String?,
      experienceYears: (json['experienceYears'] as num?)?.toInt(),
      minPackagePrice: (json['minPackagePrice'] as num?)?.toDouble(),
    );
  }
}
