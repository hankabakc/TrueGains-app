class CoachDiscoveryModel {
  final int userId;
  final String? fullName;
  final String? bio;
  final String? specialization;
  final String? currency;
  final String? profilePhotoUrl;
  final String? instagramUrl;
  final double? averageRating;
  final int reviewCount;
  final int activeStudentCount;
  final String? province;
  final String? district;
  final int? experienceYears;
  final double? minPackagePrice;

  CoachDiscoveryModel({
    required this.userId,
    this.fullName,
    this.bio,
    this.specialization,
    this.currency,
    this.profilePhotoUrl,
    this.instagramUrl,
    this.averageRating,
    this.reviewCount = 0,
    this.activeStudentCount = 0,
    this.province,
    this.district,
    this.experienceYears,
    this.minPackagePrice,
  });

  factory CoachDiscoveryModel.fromJson(Map<String, dynamic> json) {
    return CoachDiscoveryModel(
      userId: json['userId'] as int,
      fullName: json['fullName'] as String?,
      bio: json['bio'] as String?,
      specialization: json['specialization'] as String?,
      currency: json['currency'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      instagramUrl: json['instagramUrl'] as String?,
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
