import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/client_profile_response_model.dart';
import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';
import 'package:gymapp_v2/features/auth/data/models/goal.dart';
import 'profile_form_state.dart';

class ProfileFormCubit extends Cubit<ProfileFormState> {
  ProfileFormCubit(ClientProfileResponseModel profile)
      : super(ProfileFormState(
          fullName: profile.fullName,
          birthDate: profile.dateOfBirth != null
              ? DateTime.tryParse(profile.dateOfBirth!)
              : null,
          gender: profile.gender,
          goal: profile.goal,
          activityLevel: profile.activityLevel,
          bio: profile.bio ?? '',
          instagramUrl: profile.instagramUrl ?? '',
          websiteUrl: profile.websiteUrl ?? '',
          tiktokUrl: profile.tiktokUrl ?? '',
          heightCm: profile.heightCm,
          weightKg: profile.weightKg,
          showAge: profile.showAge,
          showHeight: profile.showHeight,
          showWeight: profile.showWeight,
          profilePhotoUrl: profile.profilePhotoUrl,
        ));

  void updateFullName(String val) => emit(state.copyWith(fullName: val));
  void updateBirthDate(DateTime date) => emit(state.copyWith(birthDate: date));
  void updateGender(Gender? gender) => emit(state.copyWith(gender: gender));
  void updateGoal(Goal? goal) => emit(state.copyWith(goal: goal));
  void updateActivityLevel(ActivityLevel? level) =>
      emit(state.copyWith(activityLevel: level));
  void updateBio(String val) => emit(state.copyWith(bio: val));
  void updateInstagramUrl(String val) => emit(state.copyWith(instagramUrl: val));
  void updateWebsiteUrl(String val) => emit(state.copyWith(websiteUrl: val));
  void updateTiktokUrl(String val) => emit(state.copyWith(tiktokUrl: val));
  void updateHeightCm(int? val) => emit(state.copyWith(heightCm: val));
  void updateWeightKg(double? val) => emit(state.copyWith(weightKg: val));
  void toggleShowAge(bool val) => emit(state.copyWith(showAge: val));
  void toggleShowHeight(bool val) => emit(state.copyWith(showHeight: val));
  void toggleShowWeight(bool val) => emit(state.copyWith(showWeight: val));
  void updateProfilePhoto(String? url) => emit(state.copyWith(profilePhotoUrl: url));

  /// Kaydetme isteğinin gövdesini üretir.
  ///
  /// Sunucu bu alanların tamamını koşulsuz yazar: gönderilmeyen bir alan `null`
  /// olarak gider ve mevcut değeri siler. Bu yüzden gövde ekranda tek tek elle
  /// kurulmaz, formun kendi durumundan üretilir.
  ///
  /// Instagram ve TikTok değerleri kullanıcı kısa yazabildiği için (`@kullanici`)
  /// burada tam adrese çevrilir.
  Map<String, dynamic> buildUpdatePayload({
    required String instagramInput,
    required String tiktokInput,
  }) {
    return {
      'fullName': state.fullName.trim(),
      'dateOfBirth': state.birthDate != null
          ? '${state.birthDate!.year.toString().padLeft(4, '0')}-'
              '${state.birthDate!.month.toString().padLeft(2, '0')}-'
              '${state.birthDate!.day.toString().padLeft(2, '0')}'
          : null,
      'gender': state.gender?.toJsonString(),
      'heightCm': state.heightCm,
      'weightKg': state.weightKg,
      'goal': state.goal?.toJsonString(),
      'activityLevel': state.activityLevel?.toJsonString(),
      'bio': state.bio,
      'profilePhotoUrl': state.profilePhotoUrl,
      'instagramUrl': normalizeInstagram(instagramInput),
      // Ekranda web sitesi alanı yok; kayıt sırasında girilen değer korunmalı.
      'websiteUrl': state.websiteUrl.isEmpty ? null : state.websiteUrl,
      'tiktokUrl': normalizeTiktok(tiktokInput),
      'showAge': state.showAge,
      'showHeight': state.showHeight,
      'showWeight': state.showWeight,
    };
  }

  static String? normalizeInstagram(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    return value.contains('instagram.com') ? value : 'www.instagram.com/$value';
  }

  static String? normalizeTiktok(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final clean = value.startsWith('@') ? value.substring(1) : value;
    return clean.contains('tiktok.com') ? clean : 'www.tiktok.com/@$clean';
  }
}
