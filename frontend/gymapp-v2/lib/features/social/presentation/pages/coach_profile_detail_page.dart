import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/config/app_config.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/network_avatar.dart';
import 'package:gymapp_v2/features/finance/ui/widgets/package_features_list.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:gymapp_v2/core/widgets/city_picker.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_event.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_state.dart';
import 'package:gymapp_v2/features/social/data/models/coach_profile_model.dart';
import 'package:gymapp_v2/features/social/presentation/widgets/report_user_sheet.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/coach_profile/coach_profile_bloc.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/coach_profile/coach_profile_event.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/coach_profile/coach_profile_state.dart' as coach_state;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gymapp_v2/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/social/data/models/coach_specialization.dart';
import 'package:gymapp_v2/features/social/presentation/widgets/reviews_section.dart';
import 'package:gymapp_v2/features/social/presentation/widgets/gallery_grid_widget.dart';
import 'package:gymapp_v2/features/social/presentation/widgets/success_stories_section.dart';
import 'package:gymapp_v2/features/auth/data/models/experience_level.dart';
import 'package:gymapp_v2/features/auth/data/models/coaching_mode.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/chat_bloc.dart';
import 'package:gymapp_v2/features/finance/models/finance_models.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';

class CoachProfileDetailPage extends StatefulWidget {
  final int coachId;
  final String coachName;

  const CoachProfileDetailPage({
    super.key,
    required this.coachId,
    required this.coachName,
  });

  @override
  State<CoachProfileDetailPage> createState() => _CoachProfileDetailPageState();
}

class _CoachProfileDetailPageState extends State<CoachProfileDetailPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _instagramController;
  late TextEditingController _tiktokController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _experienceController;
  
  // States
  String? _profilePhotoUrl;
  bool _isUploadingPhoto = false;
  final Set<String> _selectedSpecializations = {};
  bool _controllersInitialized = false;
  String? _selectedProvince;
  String? _selectedDistrict;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.coachName);
    _bioController = TextEditingController();
    _instagramController = TextEditingController();
    _tiktokController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _experienceController = TextEditingController();
  }

  void _initializeControllers(CoachProfileModel profile) {
    if (_controllersInitialized) return;
    _controllersInitialized = true;
    setState(() {
      _selectedProvince = profile.province;
      _selectedDistrict = profile.district;
      _nameController.text = profile.fullName;
      _bioController.text = profile.bio ?? '';
      _selectedSpecializations.clear();
      if (profile.specialization != null && profile.specialization!.isNotEmpty) {
        _selectedSpecializations.addAll(
          profile.specialization!
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty),
        );
      }
      _profilePhotoUrl = profile.profilePhotoUrl;
      _instagramController.text = _parseUsername(profile.instagramUrl ?? '', 'instagram.com/');
      _tiktokController.text = _parseUsername(profile.tiktokUrl ?? '', 'tiktok.com/@');
      _heightController.text = profile.heightCm?.toString() ?? '';
      _weightController.text = profile.weightKg?.toStringAsFixed(0) ?? '';
      _experienceController.text = profile.experienceYears?.toString() ?? '';
    });
  }

  String _parseUsername(String url, String domainWithSlash) {
    if (url.isEmpty) return '';
    try {
      final index = url.indexOf(domainWithSlash);
      if (index != -1) {
        String username = url.substring(index + domainWithSlash.length);
        if (username.endsWith('/')) username = username.substring(0, username.length - 1);
        final queryIndex = username.indexOf('?');
        if (queryIndex != -1) username = username.substring(0, queryIndex);
        if (domainWithSlash.contains('tiktok.com') && username.startsWith('@')) {
          username = username.substring(1);
        }
        return username;
      }
    } catch (_) {}
    if (!url.contains('.')) return url;
    return '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kırmızı ile işaretlenen zorunlu alanları doldurun.')),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      if (_profilePhotoUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil fotoğrafı zorunludur.')));
        return;
      }

      if (_selectedProvince == null || _selectedDistrict == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İl ve ilçe seçilmelidir.')));
        return;
      }

      String instaVal = _instagramController.text.trim();
      String? instagramUrl;
      if (instaVal.isNotEmpty) {
        instagramUrl = instaVal.startsWith('http') ? instaVal : 'https://instagram.com/$instaVal';
      }

      String tiktokVal = _tiktokController.text.trim();
      String? tiktokUrl;
      if (tiktokVal.isNotEmpty) {
        final cleanTiktok = tiktokVal.startsWith('@') ? tiktokVal.substring(1) : tiktokVal;
        tiktokUrl = tiktokVal.startsWith('http') ? tiktokVal : 'https://tiktok.com/@$cleanTiktok';
      }

      if (_selectedSpecializations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En az bir uzmanlık seçmelisiniz.')),
        );
        return;
      }

      final updateData = {
        'fullName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'specialization': _selectedSpecializations.join(', '),
        'experienceYears': int.tryParse(_experienceController.text.trim()),
        'heightCm': int.tryParse(_heightController.text.trim()),
        'weightKg': double.tryParse(_weightController.text.trim()),
        'instagramUrl': instagramUrl,
        'tiktokUrl': tiktokUrl,
        'province': _selectedProvince,
        'district': _selectedDistrict,
      };

      context.read<ProfileBloc>().add(
            UpdateProfile(
               userId: widget.coachId,
               updateData: updateData,
               isCoach: true,
            ),
          );
    }
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    if (_isUploadingPhoto) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null && mounted) {
      context.read<ProfileBloc>().add(UploadProfilePhoto(filePath: image.path, fileName: image.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final bool isOwnProfile = authState is AuthAuthenticated && authState.auth.id == widget.coachId;

    return BlocProvider<CoachProfileBloc>(
      create: (context) => sl<CoachProfileBloc>()
        ..add(LoadCoachProfile(widget.coachId))
        ..add(LoadCoachReviews(widget.coachId)),
      child: DefaultTabController(
        length: isOwnProfile ? 2 : 1,
        child: MultiBlocListener(
          listeners: [
            BlocListener<ProfileBloc, ProfileState>(
              listener: (context, state) {
                if (state is ProfileUpdateSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil güncellendi.')));
                  context.go('/main', extra: {'role': UserRole.COACH});
                } else if (state is ProfilePhotoUploadLoading) {
                  setState(() => _isUploadingPhoto = true);
                } else if (state is ProfilePhotoUploadSuccess) {
                  setState(() {
                    _isUploadingPhoto = false;
                    _profilePhotoUrl = state.photoUrl;
                  });
                } else if (state is ProfilePhotoUploadError) {
                  setState(() => _isUploadingPhoto = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                } else if (state is ProfileError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
            ),
            BlocListener<CoachProfileBloc, coach_state.CoachProfileState>(
              listener: (context, state) {
                if (state is coach_state.CoachProfileLoaded) {
                  _initializeControllers(state.profile);
                }
              },
            ),
          ],
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
              title: Text(
                isOwnProfile ? 'Profil Yönetimi' : widget.coachName,
                style: AppTextStyles.heroTitle,
              ),
              actions: [
                // Sikayet yalnizca BASKASININ profilinde: kendi profilini
                // sikayet etmek anlamsiz, backend de reddediyor.
                if (!isOwnProfile)
                  IconButton(
                    icon: const Icon(Icons.flag_outlined, color: AppColors.textMuted),
                    tooltip: 'Şikâyet et',
                    onPressed: () => showReportUserSheet(
                      context,
                      reportedUserId: widget.coachId,
                      displayName: widget.coachName,
                    ),
                  ),
                if (isOwnProfile)
                  Builder(
                    builder: (context) {
                      final tabController = DefaultTabController.of(context);
                      return AnimatedBuilder(
                        animation: tabController,
                        builder: (context, child) {
                          if (tabController.index == 0) {
                            return IconButton(
                              icon: const Icon(Icons.check_rounded, color: AppColors.success, size: 28),
                              onPressed: _onSave,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      );
                    },
                  ),
                const SizedBox(width: AppSpacing.xs),
              ],
              bottom: isOwnProfile
                  ? TabBar(
                      dividerColor: Colors.transparent,
                      indicatorColor: AppColors.primary,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textMuted,
                      labelStyle: AppTextStyles.tagText.copyWith(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                      tabs: const [Tab(text: 'DÜZENLE'), Tab(text: 'ÖNİZLEME')],
                    )
                  : null,
            ),
            body: isOwnProfile
                ? TabBarView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildEditTab(),
                      _CoachProfileBody(coachId: widget.coachId, controllers: _getControllers()),
                    ],
                  )
                : _CoachProfileBody(coachId: widget.coachId),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getControllers() {
    return {
      'name': _nameController,
      'bio': _bioController,
      'specialization': _selectedSpecializations.join(','),
      'profilePhoto': _profilePhotoUrl,
      'instagram': _instagramController,
      'tiktok': _tiktokController,
      'height': _heightController,
      'weight': _weightController,
    };
  }

  Widget _buildEditTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfilePhotoEditor(),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(label: 'TEMEL BİLGİLER'),
            const SizedBox(height: AppSpacing.sm),
            GlassContainer(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _buildInputField(
                    controller: _nameController,
                    label: 'Ad Soyad',
                    icon: Icons.person_outline,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Ad Soyad zorunludur.' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Uzmanlık Alanları (En fazla 5 adet)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: CoachSpecialization.values
                        .where((s) => s != CoachSpecialization.all)
                        .map((s) {
                      final isSelected = _selectedSpecializations.contains(s.apiValue);
                      return FilterChip(
                        label: Text(s.label),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.glassWhite,
                        checkmarkColor: AppColors.background,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.background : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.3),
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              if (_selectedSpecializations.length >= 5) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('En fazla 5 uzmanlık seçebilirsiniz.')),
                                );
                                return;
                              }
                              _selectedSpecializations.add(s.apiValue);
                            } else {
                              _selectedSpecializations.remove(s.apiValue);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildInputField(
                    controller: _bioController,
                    label: 'Hakkımda',
                    icon: Icons.description_outlined,
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Biyografi zorunludur.' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(label: 'PROFESYONEL BİLGİLER'),
            const SizedBox(height: AppSpacing.sm),
            GlassContainer(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _buildInputField(
                    controller: _experienceController,
                    label: 'Deneyim (yıl)',
                    icon: Icons.workspace_premium_outlined,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty) {
                        final val = int.tryParse(v.trim());
                        if (val == null || val < 0 || val > 80) {
                          return 'Deneyim 0-80 yıl aralığında olmalıdır.';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(label: 'KONUM'),
            const SizedBox(height: AppSpacing.sm),
            GlassContainer(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: CityPicker(
                province: _selectedProvince,
                district: _selectedDistrict,
                onProvinceChanged: (v) => setState(() {
                  _selectedProvince = v;
                  _selectedDistrict = null;
                }),
                onDistrictChanged: (v) => setState(() => _selectedDistrict = v),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(label: 'FİZİKSEL BİLGİLER'),
            const SizedBox(height: AppSpacing.sm),
            GlassContainer(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      controller: _heightController,
                      label: 'Boy (cm)',
                      icon: Icons.height_rounded,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      validator: (v) => v == null || v.isEmpty || int.tryParse(v) == null ? 'Geçerli boy giriniz.' : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildInputField(
                      controller: _weightController,
                      label: 'Kilo (kg)',
                      icon: Icons.monitor_weight_outlined,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Geçerli kilo giriniz.' : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(label: 'SOSYAL MEDYA'),
            const SizedBox(height: AppSpacing.sm),
            GlassContainer(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _buildSocialField(controller: _instagramController, label: 'Instagram', icon: Icons.camera_alt_outlined, prefix: 'instagram.com/', onChanged: (_) => setState(() {})),
                  const SizedBox(height: AppSpacing.md),
                  _buildSocialField(controller: _tiktokController, label: 'TikTok', icon: Icons.play_circle_outline_rounded, prefix: 'tiktok.com/@', onChanged: (_) => setState(() {})),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhotoEditor() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              gradient: AppColors.primaryGradient,
            ),
            padding: const EdgeInsets.all(AppSpacing.xxs / 2),
            child: Container(
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surface),
              clipBehavior: Clip.antiAlias,
              child: ClipOval(
                child: _isUploadingPhoto
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : (_profilePhotoUrl != null
                        ? CachedNetworkImage(imageUrl: AppConfig.resolveFileUrl(_profilePhotoUrl!), fit: BoxFit.cover)
                        : const Icon(Icons.person_rounded, size: 50, color: AppColors.textMuted)),
              ),
            ),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
              onTap: _pickAndUploadProfilePhoto,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: AppColors.background, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator, void Function(String)? onChanged}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true, 
        fillColor: AppColors.glassWhite,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
      ),
    );
  }



  Widget _buildSocialField({required TextEditingController controller, required String label, required IconData icon, required String prefix, void Function(String)? onChanged}) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        prefixText: prefix,
        prefixStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
        filled: true, 
        fillColor: AppColors.glassWhite,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
      ),
    );
  }
}

class _CoachProfileBody extends StatelessWidget {
  final int coachId;
  final Map<String, dynamic>? controllers;

  const _CoachProfileBody({required this.coachId, this.controllers});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CoachProfileBloc, coach_state.CoachProfileState>(
      listener: (context, state) {
        if (state is coach_state.CoachRequestSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.success));
        }
      },
      child: BlocBuilder<CoachProfileBloc, coach_state.CoachProfileState>(
        builder: (context, state) {
          if (state is coach_state.CoachProfileLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is coach_state.CoachProfileLoaded) {
            final profile = state.profile;
            final String name = (controllers?['name'] as TextEditingController?)?.text ?? profile.fullName;
            final String bio = (controllers?['bio'] as TextEditingController?)?.text ?? (profile.bio ?? 'Biyografi belirtilmedi.');
            final String? photo = (controllers?['profilePhoto'] as String?) ?? profile.profilePhotoUrl;
            final String spec = controllers?['specialization'] as String? ?? (profile.specialization ?? 'ANTRENÖR');

            return DefaultTabController(
              length: 4,
              child: NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        _buildHeader(name, spec, photo, profile),
                        const SizedBox(height: AppSpacing.lg),
                        _buildBentoGrid(bio, profile),
                        const SizedBox(height: AppSpacing.xl),
                        TabBar(
                          dividerColor: Colors.transparent,
                          indicatorColor: AppColors.primary,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textMuted,
                          labelStyle: AppTextStyles.tagText.copyWith(fontWeight: FontWeight.w900, fontSize: 13),
                          // Tab'in varsayilan 16+16 px ic bosluguyla "PORTFOLYO"
                          // sekme basina dusen ~98 px'e sigmiyor ve "PORTFOLY"
                          // olarak kirpiliyordu. Bosluk daraltilinca sigiyor.
                          labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                          tabs: const [Tab(text: 'PORTFOLYO'), Tab(text: 'BAŞARI'), Tab(text: 'YORUMLAR'), Tab(text: 'PAKETLER')],
                        ),
                      ],
                    ),
                  )
                ],
                body: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: TabBarView(
                    children: [
                      GalleryGridWidget(images: profile.portfolioImages, emptyText: 'Henüz portfolyo görseli yok.'),
                      SuccessStoriesSection(progressList: profile.authorizedStudentProgress),
                      ReviewsSection(coachId: coachId, isSubscribed: profile.isSubscribed ?? false),
                      _CoachPackagesSection(coachId: coachId),
                    ],
                  ),
                ),
              ),
            );
          }
          if (state is coach_state.CoachProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyText,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: 160,
                    child: PremiumButton(
                      onPressed: () {
                        context.read<CoachProfileBloc>().add(LoadCoachProfile(coachId));
                        context.read<CoachProfileBloc>().add(LoadCoachReviews(coachId));
                      },
                      text: 'TEKRAR DENE',
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeader(String name, String spec, String? photo, CoachProfileModel profile) => Column(
    children: [
      NetworkAvatar(
        imageUrl: photo,
        size: 96,
        gradientRing: true,
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        name, 
        style: AppTextStyles.heroDisplay,
      ),
      const SizedBox(height: AppSpacing.xxs),
      if (profile.reviewCount > 0)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              profile.averageRating!.toStringAsFixed(1),
              style: AppTextStyles.bodyText.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' · ${profile.reviewCount} yorum',
              style: AppTextStyles.bodyText.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        )
      else
        Text(
          'Henüz yorum yok',
          style: AppTextStyles.bodyText.copyWith(
            color: AppColors.textMuted,
            fontSize: 13,
          ),
        ),
      const SizedBox(height: AppSpacing.xs),
      Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...spec.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).map((s) {
            final enumVal = CoachSpecialization.values.firstWhere(
              (e) => e.apiValue == s,
              orElse: () => CoachSpecialization.fitness,
            );
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    enumVal.icon,
                    size: 12,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    s.toUpperCase(),
                    style: AppTextStyles.tagText.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      if (profile.province != null && profile.province!.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              '${profile.province}${profile.district != null ? ' / ${profile.district}' : ''}',
              style: AppTextStyles.tagText.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    ],
  );

  Widget _buildBentoGrid(String bio, CoachProfileModel profile) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatBento(
                Icons.workspace_premium_outlined,
                'DENEYİM',
                profile.experienceYears != null ? '${profile.experienceYears} yıl' : '—',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatBento(
                Icons.groups_outlined,
                'AKTİF ÖĞRENCİ',
                '${profile.activeStudentCount}',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatBento(
                Icons.verified_user_outlined,
                'ÜYELİK',
                profile.memberSince != null ? '${profile.memberSince!.year}' : '—',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GlassContainer(
          width: double.infinity,
          borderRadius: AppRadius.xl,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(label: 'HAKKIMDA'),
              const SizedBox(height: AppSpacing.sm),
              Text(
                bio, 
                style: AppTextStyles.bodyText,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildStatBento(IconData icon, String label, String value) => GlassContainer(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    borderRadius: AppRadius.xl,
    child: Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label, 
          style: AppTextStyles.cardLabel.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value, 
          style: AppTextStyles.cardValue.copyWith(fontSize: 16),
        ),
      ],
    ),
  );
}

class _CoachPackagesSection extends StatefulWidget {
  final int coachId;
  const _CoachPackagesSection({required this.coachId});
  @override
  State<_CoachPackagesSection> createState() => _CoachPackagesSectionState();
}

class _CoachPackagesSectionState extends State<_CoachPackagesSection> {
  SubscriptionPackageModel? _pendingStagedPackage;
  bool _isInitiatingChat = false;

  @override
  void initState() {
    super.initState();
    context.read<FinanceBloc>().add(LoadPackages(widget.coachId));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final bool isOwnProfile = authState is AuthAuthenticated && authState.auth.id == widget.coachId;
    // Koçlar paket satın alamaz; satın alma aksiyonu yalnızca sporculara gösterilir.
    final bool isCoach = authState is AuthAuthenticated && authState.auth.role == UserRole.COACH;

    return MultiBlocListener(
      listeners: [
        BlocListener<FinanceBloc, FinanceState>(
          listenWhen: (p, c) => p.status != c.status && c.status == FinanceStatus.cartUpdated,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.successMessage ?? 'Paket sepetinize eklendi.'),
              backgroundColor: AppColors.success,
            ));
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.push('/my-subscription');
              }
            });
          },
        ),
        BlocListener<ChatBloc, ChatState>(
          listenWhen: (p, c) => _isInitiatingChat,
          listener: (context, state) {
            if (state is ChatInitiated) {
              setState(() {
                _isInitiatingChat = false;
              });
              final chatBloc = context.read<ChatBloc>();
              final stagedPkg = _pendingStagedPackage;
              _pendingStagedPackage = null;
              
              if (authState is AuthAuthenticated) {
                final currentUserId = authState.auth.id;
                context
                    .push(
                      '/chat',
                      extra: <String, dynamic>{
                        'conversation': state.conversation,
                        'currentUserId': currentUserId,
                        'stagedPackage': stagedPkg,
                      },
                    )
                    .then((_) {
                      chatBloc.add(ResetChatState());
                    });
              }
            } else if (state is ChatError) {
              setState(() {
                _isInitiatingChat = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          final coachPackages = state.packages.where((p) => p.coachId == widget.coachId).toList();
          if (coachPackages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 36,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Henüz paket bulunmuyor.', 
                    style: AppTextStyles.bodyText,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: coachPackages.length,
            itemBuilder: (context, index) {
              final pkg = coachPackages[index];
              final bool hasQuota = pkg.quota != null;
              final int remaining = hasQuota ? (pkg.quota! - pkg.activeSubscriberCount).clamp(0, pkg.quota!) : 0;
              final bool isFull = hasQuota && remaining <= 0;

              return GlassContainer(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                borderRadius: AppRadius.xl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pkg.name, 
                            style: AppTextStyles.listTitle,
                          ),
                        ),
                        if (!isOwnProfile)
                          IconButton(
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            tooltip: 'Paket Sor',
                            onPressed: () {
                              setState(() {
                                _pendingStagedPackage = pkg;
                                _isInitiatingChat = true;
                              });
                              context.read<ChatBloc>().add(
                                    ChatInitiationRequested(widget.coachId),
                                  );
                            },
                          ),
                        Text(
                          '${pkg.price.toStringAsFixed(0)} ₺', 
                          style: AppTextStyles.cardValue.copyWith(
                            color: AppColors.primary,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded, 
                          size: 14, 
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          '${pkg.durationDays} gün',
                          style: AppTextStyles.bodyText.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (isFull) ...[
                          const SizedBox(width: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.error),
                            ),
                            child: Text(
                              'Kontenjan Dolu',
                              style: AppTextStyles.tagText.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ] else if (hasQuota && remaining <= 3) ...[
                          const SizedBox(width: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Text(
                              'Son $remaining kontenjan',
                              style: AppTextStyles.tagText.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (pkg.levels != null || pkg.mode != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (pkg.mode != null) ...[
                            (() {
                              final modeEnum = CoachingMode.fromString(pkg.mode);
                              if (modeEnum == null) return const SizedBox.shrink();
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  modeEnum.toUIString(),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }()),
                          ],
                          if (pkg.levels != null) ...[
                            ...pkg.levels!.split(',').map((levelStr) {
                              final levelEnum = ExperienceLevel.fromString(levelStr.trim());
                              if (levelEnum == null) return const SizedBox.shrink();
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.glassWhite,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.glassBorder),
                                ),
                                child: Text(
                                  levelEnum.toUIString(),
                                  style: AppTextStyles.tagText.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ],
                    if (pkg.description != null && pkg.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        pkg.description!,
                        style: AppTextStyles.bodyText.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (pkg.features != null && pkg.features!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      PackageFeaturesList(features: pkg.features),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    // Koç hesabı paket satın alamaz: satın alma butonu yalnızca sporculara gösterilir.
                    if (isCoach)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Text(
                          'Koç hesabı ile satın alma yapılamaz',
                          style: AppTextStyles.bodyText.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isFull ? null : () => context.read<FinanceBloc>().add(AddPackageToCart(pkg.id)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.background,
                            disabledBackgroundColor: AppColors.surface.withValues(alpha: 0.5),
                            disabledForegroundColor: AppColors.textMuted,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: Text(
                            isFull ? 'KONTENJAN DOLU' : 'SATIN AL',
                            style: AppTextStyles.buttonText.copyWith(
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
