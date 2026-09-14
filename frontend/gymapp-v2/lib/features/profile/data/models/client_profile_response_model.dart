import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';
import 'package:gymapp_v2/features/auth/data/models/goal.dart';
import 'package:gymapp_v2/features/auth/data/models/experience_level.dart';

class ClientProfileResponseModel {
  final int userId;
  final String fullName;
  final String email;
  final String? profilePhotoUrl;
  final String? dateOfBirth;
  final Gender? gender;
  final int? heightCm;
  final double? weightKg;
  final Goal? goal;
  final ActivityLevel? activityLevel;
  final String? bio;
  final String? instagramUrl;
  final String? websiteUrl;
  final String? tiktokUrl;
  final List<String> publicPhotos;
  final bool showAge;
  final bool showHeight;
  final bool showWeight;
  final String? province;
  final String? district;
  final ExperienceLevel? experienceLevel;

  ClientProfileResponseModel({
    required this.userId,
    required this.fullName,
    required this.email,
    this.profilePhotoUrl,
    this.dateOfBirth,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.goal,
    this.activityLevel,
    this.bio,
    this.instagramUrl,
    this.websiteUrl,
    this.tiktokUrl,
    this.publicPhotos = const [],
    required this.showAge,
    required this.showHeight,
    required this.showWeight,
    this.province,
    this.district,
    this.experienceLevel,
  });

  factory ClientProfileResponseModel.fromJson(Map<String, dynamic> json) {
    return ClientProfileResponseModel(
      userId: (json['userId'] as int?) ?? 0,
      fullName: (json['fullName'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: json['gender'] != null ? Gender.fromString(json['gender'] as String) : null,
      heightCm: json['heightCm'] as int?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      goal: json['goal'] != null ? Goal.fromString(json['goal'] as String) : null,
      activityLevel: json['activityLevel'] != null ? ActivityLevel.fromString(json['activityLevel'] as String) : null,
      bio: json['bio'] as String?,
      instagramUrl: json['instagramUrl'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      tiktokUrl: json['tiktokUrl'] as String?,
      publicPhotos: (json['publicPhotos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      showAge: (json['showAge'] as bool?) ?? true,
      showHeight: (json['showHeight'] as bool?) ?? true,
      showWeight: (json['showWeight'] as bool?) ?? true,
      province: json['province'] as String?,
      district: json['district'] as String?,
      experienceLevel: json['experienceLevel'] != null ? ExperienceLevel.fromString(json['experienceLevel'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'profilePhotoUrl': profilePhotoUrl,
      'dateOfBirth': dateOfBirth,
      'gender': gender?.toJsonString(),
      'heightCm': heightCm,
      'weightKg': weightKg,
      'goal': goal?.toJsonString(),
      'activityLevel': activityLevel?.toJsonString(),
      'bio': bio,
      'instagramUrl': instagramUrl,
      'websiteUrl': websiteUrl,
      'tiktokUrl': tiktokUrl,
      'publicPhotos': publicPhotos,
      'showAge': showAge,
      'showHeight': showHeight,
      'showWeight': showWeight,
      'province': province,
      'district': district,
      'experienceLevel': experienceLevel?.toJsonString(),
    };
  }
}
