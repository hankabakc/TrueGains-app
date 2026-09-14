import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';
import 'package:gymapp_v2/features/auth/data/models/goal.dart';

class ProfileFormState extends Equatable {
  final String fullName;
  final DateTime? birthDate;
  final Gender? gender;
  final Goal? goal;
  final ActivityLevel? activityLevel;
  final String bio;
  final String instagramUrl;
  final String websiteUrl;
  final String tiktokUrl;
  final int? heightCm;
  final double? weightKg;
  final bool showAge;
  final bool showHeight;
  final bool showWeight;
  final String? profilePhotoUrl;

  const ProfileFormState({
    this.fullName = '',
    this.birthDate,
    this.gender,
    this.goal,
    this.activityLevel,
    this.bio = '',
    this.instagramUrl = '',
    this.websiteUrl = '',
    this.tiktokUrl = '',
    this.heightCm,
    this.weightKg,
    this.showAge = true,
    this.showHeight = true,
    this.showWeight = true,
    this.profilePhotoUrl,
  });

  ProfileFormState copyWith({
    String? fullName,
    DateTime? birthDate,
    Gender? gender,
    Goal? goal,
    ActivityLevel? activityLevel,
    String? bio,
    String? instagramUrl,
    String? websiteUrl,
    String? tiktokUrl,
    int? heightCm,
    double? weightKg,
    bool? showAge,
    bool? showHeight,
    bool? showWeight,
    String? profilePhotoUrl,
  }) {
    return ProfileFormState(
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
      bio: bio ?? this.bio,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      tiktokUrl: tiktokUrl ?? this.tiktokUrl,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      showAge: showAge ?? this.showAge,
      showHeight: showHeight ?? this.showHeight,
      showWeight: showWeight ?? this.showWeight,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    );
  }

  @override
  List<Object?> get props => [
        fullName,
        birthDate,
        gender,
        goal,
        activityLevel,
        bio,
        instagramUrl,
        websiteUrl,
        tiktokUrl,
        heightCm,
        weightKg,
        showAge,
        showHeight,
        showWeight,
        profilePhotoUrl,
      ];
}
