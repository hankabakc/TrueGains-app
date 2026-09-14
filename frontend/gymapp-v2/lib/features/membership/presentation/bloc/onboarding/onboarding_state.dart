import 'package:equatable/equatable.dart';

class OnboardingState extends Equatable {
  final int currentPage;

  final String? profilePhotoUrl;
  final bool isUploading;

  final String? province;
  final String? district;
  final Set<String> specializations;

  /// Doğrulama hataları ilgili alanın altında gösterilir. SnackBar yalnızca
  /// sunucu/ağ hatası için kullanılır: geçici bir şerit hangi alanın hatalı
  /// olduğunu göstermez ve odak taşımaz.
  final String? nameError;
  final String? bioError;
  final String? photoError;
  final String? locationError;
  final String? specializationError;
  final String? linkError;

  const OnboardingState({
    this.currentPage = 0,
    this.profilePhotoUrl,
    this.isUploading = false,
    this.province,
    this.district,
    this.specializations = const {},
    this.nameError,
    this.bioError,
    this.photoError,
    this.locationError,
    this.specializationError,
    this.linkError,
  });

  OnboardingState copyWith({
    int? currentPage,
    String? profilePhotoUrl,
    bool? isUploading,
    String? province,
    String? district,
    Set<String>? specializations,
    String? nameError,
    String? bioError,
    String? photoError,
    String? locationError,
    String? specializationError,
    String? linkError,
    // copyWith null'ı "değiştirme" saydığı için hataları temizlemenin ayrı bir
    // yolu olmak zorunda.
    bool clearErrors = false,
    bool clearDistrict = false,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      isUploading: isUploading ?? this.isUploading,
      province: province ?? this.province,
      district: clearDistrict ? null : (district ?? this.district),
      specializations: specializations ?? this.specializations,
      // clearErrors eskiyi siler ama bu çağrıda verilen yeni hatayı geçirir:
      // doğrulama her seferinde hata kümesini baştan yazar.
      nameError: clearErrors ? nameError : (nameError ?? this.nameError),
      bioError: clearErrors ? bioError : (bioError ?? this.bioError),
      photoError: clearErrors ? photoError : (photoError ?? this.photoError),
      locationError:
          clearErrors ? locationError : (locationError ?? this.locationError),
      specializationError: clearErrors
          ? specializationError
          : (specializationError ?? this.specializationError),
      linkError: clearErrors ? linkError : (linkError ?? this.linkError),
    );
  }

  @override
  List<Object?> get props => [
        currentPage,
        profilePhotoUrl,
        isUploading,
        province,
        district,
        specializations,
        nameError,
        bioError,
        photoError,
        locationError,
        specializationError,
        linkError,
      ];
}
