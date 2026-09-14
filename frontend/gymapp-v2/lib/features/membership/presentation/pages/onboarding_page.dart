import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/config/app_config.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/util/motion.dart';
import 'package:gymapp_v2/core/widgets/city_picker.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';
import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/goal.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/registration_flow/registration_flow_cubit.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/registration_flow/registration_flow_state.dart';
import 'package:gymapp_v2/features/auth/presentation/signup_steps.dart';
import 'package:gymapp_v2/features/auth/presentation/widgets/auth_input_field.dart';
import 'package:gymapp_v2/features/membership/presentation/bloc/onboarding/onboarding_cubit.dart';
import 'package:gymapp_v2/features/membership/presentation/bloc/onboarding/onboarding_state.dart';
import 'package:gymapp_v2/core/widgets/signup/intro_option_card.dart';
import 'package:gymapp_v2/core/widgets/signup/intro_progress_bar.dart';
import 'package:gymapp_v2/core/widgets/signup/intro_question_scaffold.dart';
import 'package:gymapp_v2/features/social/data/models/coach_specialization.dart';
import 'package:gymapp_v2/features/social/data/services/file_api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// Sunucu tarafındaki karşılıkları RegisterRequest.java'da; istemcide de
// kontrol edilmezse kullanıcı formu doldurup 400 yiyor.
final RegExp _kNamePattern = RegExp(r"^[\p{L}\s'\-\.]{2,100}$", unicode: true);
final RegExp _kInstagramPattern =
    RegExp(r'^https://www\.instagram\.com/[a-zA-Z0-9._-]+/?$');
final RegExp _kUrlPattern =
    RegExp(r'^(https?://)(?:[a-zA-Z0-9.-]+)(?::\d+)?(?:/[^<>\s]*)?$');

class OnboardingPage extends StatelessWidget {
  final String email;
  final String password;
  final String phoneNumber;
  final UserRole role;

  const OnboardingPage({
    super.key,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<OnboardingCubit>(),
      child: OnboardingView(
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        role: role,
      ),
    );
  }
}

class OnboardingView extends StatefulWidget {
  final String email;
  final String password;
  final String phoneNumber;
  final UserRole role;

  const OnboardingView({
    super.key,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.role,
  });

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _instagramController = TextEditingController();
  final _websiteController = TextEditingController();

  bool get _isCoach => widget.role == UserRole.COACH;

  /// Sporcu : kimlik → fotoğraf → konum
  /// Antrenör: kimlik → fotoğraf → konum → uzmanlık
  int get _stepCount => signupProfileSteps(widget.role);

  int get _lastStepIndex => _stepCount - 1;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _websiteController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- eylemler

  Future<void> _pickAndUploadPhoto() async {
    final OnboardingCubit cubit = context.read<OnboardingCubit>();
    if (cubit.state.isUploading) return;
    cubit.setUploading(true);

    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null) return;

      final result = await sl<FileApiService>().uploadFile(image.path, image.name);
      final Object? url = result.data?['url'];
      if (result.success && url is String) {
        cubit.setPhoto(url);
      } else if (mounted) {
        _showServerError('Fotoğraf yüklenemedi. Tekrar dene.');
      }
    } finally {
      if (!cubit.isClosed) cubit.setUploading(false);
    }
  }

  /// Yalnızca sunucu/ağ hataları için. Doğrulama hataları alanın altında.
  void _showServerError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  bool _validateStep(int step, OnboardingCubit cubit) {
    switch (step) {
      case 0:
        final String first = _firstNameController.text.trim();
        final String last = _lastNameController.text.trim();
        final String? nameError = (!_kNamePattern.hasMatch(first) ||
                !_kNamePattern.hasMatch(last))
            ? 'Ad ve soyad en az 2 harf olmalı; rakam veya simge içeremez.'
            : null;
        // Antrenörde bio backend'de zorunlu (CoachRegistrationValidator).
        final String? bioError = (_isCoach && _bioController.text.trim().isEmpty)
            ? 'Danışanların seni tanıyabilmesi için bu alan zorunlu.'
            : null;
        if (nameError != null || bioError != null) {
          cubit.showErrors(name: nameError, bio: bioError);
          return false;
        }
        return true;
      case 1:
        // Sporcuda opsiyonel; antrenörde backend zorunlu tutuyor.
        if (_isCoach && cubit.state.profilePhotoUrl == null) {
          cubit.showErrors(photo: 'Antrenör profili için fotoğraf zorunlu.');
          return false;
        }
        return true;
      case 2:
        if (cubit.state.province == null || cubit.state.district == null) {
          cubit.showErrors(location: 'İl ve ilçe seçmelisin.');
          return false;
        }
        return true;
      case 3:
        final String instagram = _instagramController.text.trim();
        final String website = _websiteController.text.trim();
        final String? specError = cubit.state.specializations.isEmpty
            ? 'En az bir uzmanlık alanı seç.'
            : null;
        String? linkError;
        if (instagram.isNotEmpty && !_kInstagramPattern.hasMatch(instagram)) {
          linkError = 'Instagram bağlantısı https://www.instagram.com/kullanici '
              'biçiminde olmalı.';
        } else if (website.isNotEmpty && !_kUrlPattern.hasMatch(website)) {
          linkError = 'Web sitesi https:// ile başlamalı.';
        }
        if (specError != null || linkError != null) {
          cubit.showErrors(specialization: specError, link: linkError);
          return false;
        }
        return true;
      default:
        return false;
    }
  }

  void _goNext(int currentPage, OnboardingCubit cubit) {
    if (!_validateStep(currentPage, cubit)) return;
    if (currentPage < _lastStepIndex) {
      _pageController.nextPage(
        duration: motionDuration(context, AppDurations.scroll),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _submitRegistration(cubit);
    }
  }

  void _goBack() {
    _pageController.previousPage(
      duration: motionDuration(context, AppDurations.scroll),
      curve: Curves.easeInOutCubic,
    );
  }

  void _submitRegistration(OnboardingCubit cubit) {
    final RegistrationFlowState flow = sl<RegistrationFlowCubit>().state;
    final OnboardingState s = cubit.state;

    final Map<String, dynamic> registerData = {
      'email': widget.email,
      'password': widget.password,
      'phoneNumber': widget.phoneNumber,
      'role': widget.role.toJsonString(),
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'profilePhotoUrl': s.profilePhotoUrl,
      'bio': _bioController.text.trim(),
      'province': s.province,
      'district': s.district,
    };

    if (widget.role == UserRole.CLIENT) {
      // Akış yarıda kesilirse (uygulama öldürülür, RegistrationFlowCubit
      // bellekten silinir) varsayılan değerle kaydetmek yerine soruları
      // tekrar sordurmak gerekir: bu alanlar kalori, makro ve program
      // zorluğunun tamamını belirliyor.
      if (flow.birthDate == null ||
          flow.gender == null ||
          flow.heightCm == null ||
          flow.weightKg == null ||
          flow.goal == null ||
          flow.activityLevel == null) {
        _showServerError('Profil bilgilerin eksik. Sorulardan tekrar başlayalım.');
        context.go('/intro');
        return;
      }

      final DateTime birthDate = flow.birthDate!;
      final Gender gender = flow.gender!;
      final Goal goal = flow.goal!;
      final ActivityLevel activity = flow.activityLevel!;

      registerData.addAll({
        'dateOfBirth': DateFormat('yyyy-MM-dd').format(birthDate),
        'gender': gender.toJsonString(),
        'heightCm': flow.heightCm!.round(),
        'weightKg': flow.weightKg,
        'goal': goal.toJsonString(),
        'activityLevel': activity.toJsonString(),
        'experienceLevel': flow.experienceLevel?.toJsonString(),
      });
    } else {
      // CoachRegistrationValidator antrenörde bio, uzmanlık, profil fotoğrafı,
      // boy ve kiloyu zorunlu tutuyor. Boy/kilo intro'da soruluyor; akış
      // yarıda kesilmişse varsayılan uydurmak yerine sorulara dönülür.
      if (flow.heightCm == null || flow.weightKg == null) {
        _showServerError('Profil bilgilerin eksik. Sorulardan tekrar başlayalım.');
        context.go('/intro');
        return;
      }

      final String instagram = _instagramController.text.trim();
      final String website = _websiteController.text.trim();

      registerData.addAll({
        'specialization': s.specializations.join(','),
        'heightCm': flow.heightCm!.round(),
        'weightKg': flow.weightKg,
        'experienceLevel': flow.experienceLevel?.toJsonString(),
        'instagramUrl': instagram.isEmpty ? null : instagram,
        'websiteUrl': website.isEmpty ? null : website,
      });
    }

    context.read<AuthBloc>().add(RegisterSubmitted(registerData));
  }

  // ----------------------------------------------------------------- yapı

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpRequired) {
          context.go('/verify-otp');
        } else if (state is AuthError) {
          _showServerError(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<OnboardingCubit, OnboardingState>(
          builder: (context, state) {
            final OnboardingCubit cubit = context.read<OnboardingCubit>();
            final int page = state.currentPage;
            final int step = signupProfileStep(widget.role, page);
            final int total = signupTotalSteps(widget.role);

            return PopScope(
              canPop: page == 0,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                _goBack();
              },
              child: Stack(
                children: [
                  SafeArea(
                    child: Column(
                      children: [
                        IntroProgressBar(
                          currentStep: step,
                          totalSteps: total,
                          label: signupStepLabel(step, total),
                        ),
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            onPageChanged: cubit.updatePage,
                            children: [
                              _identityStep(state, cubit, page),
                              _photoStep(state, cubit, page),
                              _locationStep(state, cubit, page),
                              if (_isCoach) _expertiseStep(state, cubit, page),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (context.watch<AuthBloc>().state is AuthLoading)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black54,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Adımların ortak alt kısmı: solda geri, sağda ilerle. İlk adımda geri yok.
  Widget _footer({
    required int page,
    required OnboardingCubit cubit,
    String? primaryText,
  }) {
    final bool isLast = page >= _lastStepIndex;
    final Widget primary = PremiumButton(
      text: primaryText ?? (isLast ? 'KAYDI TAMAMLA' : 'DEVAM'),
      onPressed: () => _goNext(page, cubit),
    );

    if (page == 0) return primary;

    return Row(
      children: [
        Expanded(
          child: PremiumButton(
            text: 'GERİ',
            variant: PremiumButtonVariant.secondary,
            onPressed: _goBack,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(flex: 2, child: primary),
      ],
    );
  }

  Widget _errorLine(String? message) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        message,
        style: AppTextStyles.cardCaption.copyWith(color: AppColors.error),
      ),
    );
  }

  // ---------------------------------------------------------------- adımlar

  Widget _identityStep(OnboardingState state, OnboardingCubit cubit, int page) {
    return IntroQuestionScaffold(
      isActive: page == 0,
      title: 'Adın ne?',
      subtitle: _isCoach
          ? 'Danışanların seni bu isimle görecek.'
          : 'Profilinde bu isim görünecek.',
      footer: _footer(page: page, cubit: cubit),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AuthInputField(
                  controller: _firstNameController,
                  label: 'Ad',
                  icon: Icons.person_outline_rounded,
                  autofillHints: const [AutofillHints.givenName],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AuthInputField(
                  controller: _lastNameController,
                  label: 'Soyad',
                  icon: Icons.person_outline_rounded,
                  autofillHints: const [AutofillHints.familyName],
                ),
              ),
            ],
          ),
          _errorLine(state.nameError),
          const SizedBox(height: AppSpacing.lg),
          AuthInputField(
            controller: _bioController,
            label: _isCoach ? 'Kendini tanıt' : 'Biyografi (opsiyonel)',
            hint: _isCoach
                ? 'Deneyimin, çalışma şeklin, kimlerle çalıştığın…'
                : null,
            icon: Icons.info_outline_rounded,
            maxLines: 4,
            errorText: state.bioError,
          ),
        ],
      ),
    );
  }

  Widget _photoStep(OnboardingState state, OnboardingCubit cubit, int page) {
    final bool hasPhoto = state.profilePhotoUrl != null;

    return IntroQuestionScaffold(
      isActive: page == 1,
      title: 'Profil fotoğrafın',
      subtitle: _isCoach
          ? 'Danışanların seni görmeden seçmiyor; antrenör profilinde zorunlu.'
          : 'İstersen bu adımı atlayabilirsin.',
      // Fotoğraf opsiyonel olduğu için ayrı bir "atla" butonu, ileri butonuyla
      // birebir aynı işi yapardı. Tek ileri butonu kalır, etiketi durumu söyler.
      footer: _footer(
        page: page,
        cubit: cubit,
        primaryText: (hasPhoto || _isCoach) ? 'DEVAM' : 'ŞİMDİLİK GEÇ',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: state.isUploading ? null : _pickAndUploadPhoto,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.card,
                border: Border.all(
                  color: hasPhoto ? AppColors.primary : AppColors.glassBorder,
                  width: hasPhoto ? 2 : 1,
                ),
              ),
              child: ClipOval(
                child: state.isUploading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : hasPhoto
                        ? CachedNetworkImage(
                            imageUrl: AppConfig.resolveFileUrl(state.profilePhotoUrl!),
                            width: 160,
                            height: 160,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(
                              Icons.person_rounded,
                              color: AppColors.textMuted,
                              size: 72,
                            ),
                          )
                        : const Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.textMuted,
                            size: 48,
                          ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            hasPhoto ? 'Değiştirmek için dokun' : 'Yüklemek için dokun',
            style: AppTextStyles.cardCaption,
            textAlign: TextAlign.center,
          ),
          if (state.photoError != null)
            Center(child: _errorLine(state.photoError)),
        ],
      ),
    );
  }

  Widget _locationStep(OnboardingState state, OnboardingCubit cubit, int page) {
    return IntroQuestionScaffold(
      isActive: page == 2,
      title: _isCoach ? 'Nerede hizmet veriyorsun?' : 'Nerede yaşıyorsun?',
      subtitle: _isCoach
          ? 'Danışanlar seni bölgene göre buluyor.'
          : 'Yakınındaki antrenörleri gösterebilmemiz için.',
      footer: _footer(page: page, cubit: cubit),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CityPicker(
            province: state.province,
            district: state.district,
            onProvinceChanged: cubit.setProvince,
            onDistrictChanged: cubit.setDistrict,
          ),
          _errorLine(state.locationError),
        ],
      ),
    );
  }

  Widget _expertiseStep(OnboardingState state, OnboardingCubit cubit, int page) {
    // 'all' bir filtre değeri; kayıt sırasında seçilebilir bir uzmanlık değil.
    final List<CoachSpecialization> options = CoachSpecialization.values
        .where((s) => s != CoachSpecialization.all)
        .toList();

    return IntroQuestionScaffold(
      isActive: page == 3,
      title: 'Uzmanlığın ne?',
      subtitle: 'En fazla $kMaxSpecializations alan seç.',
      footer: _footer(page: page, cubit: cubit),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            IntroOptionCard(
              label: options[i].label,
              icon: options[i].icon,
              isSelected: state.specializations.contains(options[i].apiValue),
              index: i,
              isActive: page == 3,
              onTap: () => cubit.toggleSpecialization(options[i].apiValue),
            ),
          ],
          _errorLine(state.specializationError),
          const SizedBox(height: AppSpacing.lg),
          AuthInputField(
            controller: _instagramController,
            label: 'Instagram (opsiyonel)',
            hint: 'https://www.instagram.com/kullanici',
            icon: Icons.camera_alt_outlined,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: AppSpacing.lg),
          AuthInputField(
            controller: _websiteController,
            label: 'Web sitesi (opsiyonel)',
            hint: 'https://siteniz.com',
            icon: Icons.language_rounded,
            keyboardType: TextInputType.url,
          ),
          _errorLine(state.linkError),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
