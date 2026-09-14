import 'coach_gallery_model.dart';
import 'coach_student_progress_model.dart';

class CoachProfileModel {
  final int coachId;
  final String fullName;
  final String? profilePhotoUrl;
  final String? bio;
  final String? specialization;
  final double? weeklyFee;
  final String? currency;
  final String? subscriberCountTier;
  final bool? isSubscribed;
  final String? instagramUrl;
  final String? tiktokUrl;
  final int? heightCm;
  final double? weightKg;
  final List<CoachGalleryModel> portfolioImages;
  final List<CoachGalleryModel> studentProgressImages;
  final List<CoachStudentProgressModel> authorizedStudentProgress;
  final double? averageRating;
  final int reviewCount;
  final int activeStudentCount;
  final DateTime? memberSince;
  final int? experienceYears;
  final String? province;
  final String? district;

  CoachProfileModel({
    required this.coachId,
    required this.fullName,
    this.profilePhotoUrl,
    this.bio,
    this.specialization,
    this.weeklyFee,
    this.currency,
    this.subscriberCountTier,
    this.isSubscribed,
    this.instagramUrl,
    this.tiktokUrl,
    this.heightCm,
    this.weightKg,
    required this.portfolioImages,
    required this.studentProgressImages,
    required this.authorizedStudentProgress,
    this.averageRating,
    this.reviewCount = 0,
    this.activeStudentCount = 0,
    this.memberSince,
    this.experienceYears,
    this.province,
    this.district,
  });

  factory CoachProfileModel.fromJson(Map<String, dynamic> json) {
    return CoachProfileModel(
      coachId: (json['coachId'] ?? json['id']) as int,
      fullName: (json['fullName'] ?? json['name'] ?? 'Antrenör') as String,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      bio: json['bio'] as String?,
      specialization: json['specialization'] as String?,
      weeklyFee: (json['weeklyFee'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      subscriberCountTier: json['subscriberCountTier'] as String?,
      isSubscribed: json['isSubscribed'] as bool?,
      instagramUrl: json['instagramUrl'] as String?,
      tiktokUrl: json['tiktokUrl'] as String?,
      heightCm: json['heightCm'] as int?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      portfolioImages:
          (json['portfolioImages'] as List<dynamic>?)
              ?.map(
                (e) => CoachGalleryModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      studentProgressImages:
          (json['studentProgressImages'] as List<dynamic>?)
              ?.map(
                (e) => CoachGalleryModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      authorizedStudentProgress:
          (json['authorizedStudentProgress'] as List<dynamic>?)
              ?.map(
                (e) => CoachStudentProgressModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      activeStudentCount: (json['activeStudentCount'] as num?)?.toInt() ?? 0,
      memberSince: json['memberSince'] != null ? DateTime.tryParse(json['memberSince'] as String) : null,
      experienceYears: (json['experienceYears'] as num?)?.toInt(),
      province: json['province'] as String?,
      district: json['district'] as String?,
    );
  }
}
