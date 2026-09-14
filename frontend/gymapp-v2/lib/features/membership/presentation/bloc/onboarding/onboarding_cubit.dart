import 'package:flutter_bloc/flutter_bloc.dart';
import 'onboarding_state.dart';

/// En fazla seçilebilecek uzmanlık alanı. Profil kartında okunabilir kalması
/// için sınırlı.
const int kMaxSpecializations = 5;

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(const OnboardingState());

  void updatePage(int page) {
    emit(state.copyWith(currentPage: page, clearErrors: true));
  }

  void setUploading(bool value) {
    emit(state.copyWith(isUploading: value));
  }

  void setPhoto(String url) {
    emit(state.copyWith(profilePhotoUrl: url));
  }

  void setProvince(String? value) {
    // İl değişince eski ilçe geçersiz kalır.
    emit(state.copyWith(
      province: value,
      clearDistrict: true,
      clearErrors: true,
    ));
  }

  void setDistrict(String? value) {
    emit(state.copyWith(district: value, clearErrors: true));
  }

  /// Seçili ise kaldırır, değilse ekler. Sınır aşılırsa hata döndürür ve
  /// seçim değişmez.
  void toggleSpecialization(String value) {
    final Set<String> next = Set<String>.of(state.specializations);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      if (next.length >= kMaxSpecializations) {
        emit(state.copyWith(
          specializationError:
              'En fazla $kMaxSpecializations uzmanlık seçebilirsin.',
        ));
        return;
      }
      next.add(value);
    }
    emit(state.copyWith(specializations: next, clearErrors: true));
  }

  void showErrors({
    String? name,
    String? bio,
    String? photo,
    String? location,
    String? specialization,
    String? link,
  }) {
    emit(state.copyWith(
      clearErrors: true,
      nameError: name,
      bioError: bio,
      photoError: photo,
      locationError: location,
      specializationError: specialization,
      linkError: link,
    ));
  }

  void clearErrors() {
    emit(state.copyWith(clearErrors: true));
  }
}
