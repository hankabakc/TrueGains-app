import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/config/app_config.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/util/age_calculator.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/network_avatar.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:gymapp_v2/core/widgets/city_picker.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/profile/data/models/client_profile_response_model.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_event.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_state.dart';
import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';
import 'package:gymapp_v2/features/auth/data/models/goal.dart';
import 'package:gymapp_v2/features/auth/data/models/experience_level.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gymapp_v2/features/social/data/services/file_api_service.dart';

class ClientProfileDetailPage extends StatefulWidget {
  final ClientProfileResponseModel profileData;
  final bool readOnly;

  const ClientProfileDetailPage({
    super.key,
    required this.profileData,
    this.readOnly = false,
  });

  @override
  State<ClientProfileDetailPage> createState() => _ClientProfileDetailPageState();
}

class _ClientProfileDetailPageState extends State<ClientProfileDetailPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _instagramController;
  late TextEditingController _tiktokController;

  // Selection States
  DateTime? _selectedBirthDate;
  Gender? _selectedGender;
  Goal? _selectedGoal;
  ActivityLevel? _selectedActivityLevel;
  String? _profilePhotoUrl;
  
  // Privacy States
  bool _showAge = true;
  bool _showHeight = true;
  bool _showWeight = true;
  bool _isPickingImage = false;
  String? _selectedProvince;
  String? _selectedDistrict;
  ExperienceLevel? _selectedExperienceLevel;

  List<String> _publicPhotos = [];
  
  // Slider States
  late PageController _sliderController;
  int _currentSliderIndex = 0;

  @override
  void initState() {
    super.initState();
    _sliderController = PageController();
    final p = widget.profileData;
    _nameController = TextEditingController(text: p.fullName);
    _bioController = TextEditingController(text: p.bio);
    _heightController = TextEditingController(text: p.heightCm?.toString() ?? '');
    _weightController = TextEditingController(text: p.weightKg?.toString() ?? '');
    _instagramController = TextEditingController(text: _parseUsername(p.instagramUrl ?? '', 'instagram.com/'));
    _tiktokController = TextEditingController(text: _parseUsername(p.tiktokUrl ?? '', 'tiktok.com/@'));

    _selectedBirthDate = p.dateOfBirth != null ? DateTime.tryParse(p.dateOfBirth!) : null;
    _selectedGender = p.gender;
    _selectedGoal = p.goal;
    _selectedActivityLevel = p.activityLevel;
    _profilePhotoUrl = p.profilePhotoUrl;
    _publicPhotos = List.from(p.publicPhotos);
    
    _showAge = p.showAge;
    _showHeight = p.showHeight;
    _showWeight = p.showWeight;
    _selectedProvince = p.province;
    _selectedDistrict = p.district;
    _selectedExperienceLevel = p.experienceLevel;
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
        if (domainWithSlash.contains('tiktok.com') && username.startsWith('@')) username = username.substring(1);
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
    _heightController.dispose();
    _weightController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _sliderController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_profilePhotoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil fotoğrafı zorunludur.')));
      return;
    }
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doğum tarihi zorunludur.')));
      return;
    }
    if (_selectedProvince == null || _selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İl ve ilçe seçilmelidir.')));
      return;
    }
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;

    String instaVal = _instagramController.text.trim();
    String? instagramUrl;
    if (instaVal.isNotEmpty) {
      instagramUrl = instaVal.contains('instagram.com') ? instaVal : 'https://instagram.com/$instaVal';
    }

    String tiktokVal = _tiktokController.text.trim();
    String? tiktokUrl;
    if (tiktokVal.isNotEmpty) {
      final clean = tiktokVal.startsWith('@') ? tiktokVal.substring(1) : tiktokVal;
      tiktokUrl = clean.contains('tiktok.com') ? clean : 'https://tiktok.com/@$clean';
    }

    final updateData = {
      'fullName': _nameController.text.trim(),
      'bio': _bioController.text.trim(),
      'dateOfBirth': _selectedBirthDate != null ? DateFormat('yyyy-MM-dd').format(_selectedBirthDate!) : null,
      'gender': _selectedGender?.toJsonString(),
      'heightCm': int.tryParse(_heightController.text),
      'weightKg': double.tryParse(_weightController.text),
      'goal': _selectedGoal?.toJsonString(),
      'activityLevel': _selectedActivityLevel?.toJsonString(),
      'profilePhotoUrl': _profilePhotoUrl,
      'instagramUrl': instagramUrl,
      'tiktokUrl': tiktokUrl,
      'publicPhotos': _publicPhotos,
      'showAge': _showAge,
      'showHeight': _showHeight,
      'showWeight': _showWeight,
      'province': _selectedProvince,
      'district': _selectedDistrict,
      'experienceLevel': _selectedExperienceLevel?.toJsonString(),
    };

    context.read<ProfileBloc>().add(
      UpdateProfile(userId: widget.profileData.userId, updateData: updateData),
    );
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    if (_isPickingImage) return;
    _isPickingImage = true;

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (!mounted) return;
      if (image != null) {
        final result = await sl<FileApiService>().uploadFile(image.path, image.name);
        if (!mounted) return;
        if (result.success && result.data != null && result.data!['url'] != null) {
          setState(() => _profilePhotoUrl = result.data!['url'] as String);
        }
      }
    } finally {
      if (mounted) _isPickingImage = false;
    }
  }

  Future<void> _pickAndUploadPublicPhoto() async {
    if (_isPickingImage) return;
    _isPickingImage = true;

    try {
      final picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(imageQuality: 80);
      if (!mounted) return;

      if (images.isNotEmpty) {
        int remaining = 6 - _publicPhotos.length;
        if (remaining <= 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Maksimum 6 fotoğraf yükleyebilirsiniz.')),
            );
          }
          return;
        }

        List<XFile> toUpload = images;
        if (images.length > remaining) {
          toUpload = images.take(remaining).toList();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sadece ilk $remaining fotoğraf seçildi (Limit: 6).')),
            );
          }
        }

        for (var image in toUpload) {
          final result = await sl<FileApiService>().uploadFile(image.path, image.name);
          if (!mounted) return;
          if (result.success && result.data != null && result.data!['url'] != null) {
            setState(() => _publicPhotos.add(result.data!['url'] as String));
          }
        }
      }
    } finally {
      if (mounted) _isPickingImage = false;
    }
  }

  void _removePublicPhoto(int index) {
    setState(() => _publicPhotos.removeAt(index));
  }

  void _onReorderPublicPhotos(int oldIndex, int newIndex) {
    setState(() {
      final item = _publicPhotos.removeAt(oldIndex);
      _publicPhotos.insert(newIndex, item);
    });
  }

  Widget _buildDragDropGallery({required bool isEdit}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: isEdit ? 6 : _publicPhotos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        if (index < _publicPhotos.length) {
          final photoUrl = _publicPhotos[index];
          final content = ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(imageUrl: AppConfig.resolveFileUrl(photoUrl), fit: BoxFit.cover),
                if (isEdit)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePublicPhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
              ],
            ),
          );

          if (!isEdit) return content;

          return DragTarget<int>(
            onAcceptWithDetails: (details) => _onReorderPublicPhotos(details.data, index),
            builder: (context, candidateData, rejectedData) {
              return LongPressDraggable<int>(
                data: index,
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: content,
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.3, child: content),
                child: content,
              );
            },
          );
        }

        if (!isEdit) return const SizedBox.shrink();

        return GestureDetector(
          onTap: _publicPhotos.length < 6 ? _pickAndUploadPublicPhoto : null,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassWhite,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Icon(Icons.add_a_photo_rounded, color: Colors.white24, size: 28),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final bool isOwnProfile = authState is AuthAuthenticated && authState.auth.id == widget.profileData.userId;
    final bool showEditOption = isOwnProfile && !widget.readOnly;

    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil başarıyla güncellendi.')));
          context.read<ProfileBloc>().add(const FetchProfile(isCoach: false));
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
        }
      },
      child: DefaultTabController(
        length: showEditOption ? 2 : 1,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            title: Text(
              widget.readOnly
                  ? 'Sporcu Profili'
                  : (isOwnProfile ? 'Profil Yönetimi' : 'Sporcu Profili'),
              style: AppTextStyles.heroTitle.copyWith(fontSize: 18),
            ),
            actions: [
              if (showEditOption)
                Builder(
                  builder: (context) {
                    final tabController = DefaultTabController.of(context);
                    return AnimatedBuilder(
                      animation: tabController,
                      builder: (context, child) {
                        if (tabController.index == 1) {
                          return IconButton(
                            icon: const Icon(Icons.check_rounded, color: AppColors.primary, size: 28),
                            onPressed: _onSave,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    );
                  },
                ),
              const SizedBox(width: 8),
            ],
            bottom: showEditOption
                ? TabBar(
                    dividerColor: AppColors.glassBorder,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    labelColor: AppColors.textPrimary,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: AppTextStyles.buttonText,
                    tabs: const [
                      Tab(text: 'ÖNİZLEME'),
                      Tab(text: 'DÜZENLE'),
                    ],
                  )
                : null,
          ),
          body: showEditOption
              ? TabBarView(
                  children: [
                    _buildPreviewTab(isOwnProfile),
                    _buildEditTab(),
                  ],
                )
              : _buildPreviewTab(isOwnProfile),
        ),
      ),
    );
  }

  Widget _buildEditTab() {
    return AbsorbPointer(
      absorbing: widget.readOnly,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
                      ),
                      child: NetworkAvatar(
                        imageUrl: _profilePhotoUrl,
                        size: 100,
                        ringColor: Colors.transparent,
                      ),
                    ),
                    if (!widget.readOnly)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickAndUploadProfilePhoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 20),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            _buildSectionTitle('FOTOĞRAFLARIM (DRAG & DROP)'),
            _buildDragDropGallery(isEdit: !widget.readOnly),
            const SizedBox(height: 32),
            _buildSectionTitle('TEMEL BİLGİLER'),
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Ad Soyad',
                    icon: Icons.person_rounded,
                    validator: (v) => v == null || v.isEmpty ? 'Ad Soyad zorunludur.' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDatePicker(),
                  const SizedBox(height: 16),
                  _buildDropdown<Gender>(
                    value: _selectedGender,
                    items: Gender.values,
                    itemToString: (g) => g.toUIString(),
                    label: 'Cinsiyet',
                    icon: Icons.wc_rounded,
                    onChanged: (v) => setState(() => _selectedGender = v),
                    validator: (v) => v == null ? 'Cinsiyet seçiniz.' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _bioController,
                    label: 'Biyografi',
                    icon: Icons.edit_note_rounded,
                    maxLines: 3,
                    validator: (v) => v == null || v.isEmpty ? 'Biyografi zorunludur.' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('FİZİKSEL BİLGİLER'),
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _heightController,
                          label: 'Boy (cm)',
                          icon: Icons.height_rounded,
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty || int.tryParse(v) == null ? 'Geçerli boy giriniz.' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _weightController,
                          label: 'Kilo (kg)',
                          icon: Icons.monitor_weight_rounded,
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Geçerli kilo giriniz.' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown<Goal>(
                    value: _selectedGoal,
                    items: Goal.values,
                    itemToString: (g) => g.toUIString(),
                    label: 'Hedef',
                    icon: Icons.track_changes_rounded,
                    onChanged: (v) => setState(() => _selectedGoal = v),
                    validator: (v) => v == null ? 'Hedef seçiniz.' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown<ActivityLevel>(
                    value: _selectedActivityLevel,
                    items: ActivityLevel.values,
                    itemToString: (a) => a.toUIString(),
                    label: 'Aktivite Seviyesi',
                    icon: Icons.bolt_rounded,
                    onChanged: (v) => setState(() => _selectedActivityLevel = v),
                    validator: (v) => v == null ? 'Aktivite seçiniz.' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown<ExperienceLevel>(
                    value: _selectedExperienceLevel,
                    items: ExperienceLevel.values,
                    itemToString: (e) => e.toUIString(),
                    label: 'Deneyim Seviyesi',
                    icon: Icons.trending_up_rounded,
                    onChanged: (v) => setState(() => _selectedExperienceLevel = v),
                    validator: (v) => v == null ? 'Deneyim seviyesi seçiniz.' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('KONUM'),
            GlassContainer(
              padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 32),
            _buildSectionTitle('SOSYAL MEDYA'),
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSocialField(
                    controller: _instagramController,
                    label: 'Instagram',
                    icon: Icons.camera_alt_outlined,
                    prefix: 'instagram.com/',
                    hintText: 'kullanici_adi',
                  ),
                  const SizedBox(height: 16),
                  _buildSocialField(
                    controller: _tiktokController,
                    label: 'TikTok',
                    icon: Icons.play_circle_outline_rounded,
                    prefix: 'tiktok.com/@',
                    hintText: 'kullanici_adi',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('GİZLİLİK AYARLARI'),
            GlassContainer(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _buildSwitchTile('Yaşımı Göster', _showAge, (v) => setState(() => _showAge = v)),
                  _buildSwitchTile('Boyumu Göster', _showHeight, (v) => setState(() => _showHeight = v)),
                  _buildSwitchTile('Kilomu Göster', _showWeight, (v) => setState(() => _showWeight = v)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildPreviewTab(bool isOwnProfile) {
    final bool hasSocial =
        _instagramController.text.trim().isNotEmpty || _tiktokController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPreviewHero(),
          const SizedBox(height: AppSpacing.xl),
          if (_publicPhotos.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SectionHeader(label: 'Galeri'),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildPreviewGallerySlider(),
            const SizedBox(height: AppSpacing.xl),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SectionHeader(label: 'İstatistikler'),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _buildDossier(isOwnProfile),
          ),
          if (hasSocial) ...[
            const SizedBox(height: AppSpacing.xl),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SectionHeader(label: 'Sosyal'),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _buildSocialRow(),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildPreviewGallerySlider() {
    if (_publicPhotos.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 3 / 2,
          child: PageView.builder(
            controller: _sliderController,
            itemCount: _publicPhotos.length,
            onPageChanged: (index) => setState(() => _currentSliderIndex = index),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: CachedNetworkImage(
                    imageUrl: AppConfig.resolveFileUrl(_publicPhotos[index]),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: AppColors.glassWhite),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
                  ),
                ),
              );
            },
          ),
        ),
        if (_publicPhotos.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _publicPhotos.length,
              (index) => AnimatedContainer(
                duration: AppDurations.base,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                height: 8,
                width: _currentSliderIndex == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentSliderIndex == index ? AppColors.primary : AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewHero() {
    final location = [
      (_selectedProvince ?? '').trim(),
      (_selectedDistrict ?? '').trim(),
    ].where((e) => e.isNotEmpty).join(' · ');
    final experience = _selectedExperienceLevel?.toUIString();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
              boxShadow: AppElevation.accentGlow(AppColors.primary),
            ),
            child: NetworkAvatar(
              imageUrl: _profilePhotoUrl,
              size: 108,
              ringColor: Colors.transparent,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _nameController.text.isEmpty ? 'İsimsiz' : _nameController.text,
            textAlign: TextAlign.center,
            style: AppTextStyles.heroDisplay,
          ),
          if (location.isNotEmpty || (experience != null && experience.isNotEmpty)) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (location.isNotEmpty) _buildHeroPill(Icons.location_on_rounded, location),
                if (experience != null && experience.isNotEmpty)
                  _buildHeroPill(Icons.trending_up_rounded, experience),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            _bioController.text.isEmpty ? 'Biyografi belirtilmedi.' : _bioController.text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyText.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 14),
          const SizedBox(width: AppSpacing.xxs),
          Text(text, style: AppTextStyles.tagText.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildSocialRow() {
    final insta = _instagramController.text.trim();
    final tiktok = _tiktokController.text.trim();
    return Row(
      children: [
        if (insta.isNotEmpty)
          Expanded(
            child: _buildSocialPill(
              Icons.camera_alt_outlined,
              '@$insta',
              () => _launchSocialUrl('https://instagram.com/$insta'),
            ),
          ),
        if (insta.isNotEmpty && tiktok.isNotEmpty) const SizedBox(width: AppSpacing.md),
        if (tiktok.isNotEmpty)
          Expanded(
            child: _buildSocialPill(
              Icons.play_circle_outline_rounded,
              '@$tiktok',
              () => _launchSocialUrl('https://tiktok.com/@$tiktok'),
            ),
          ),
      ],
    );
  }

  Widget _buildSocialPill(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        borderRadius: AppRadius.xl,
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.tagText.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchSocialUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildDossier(bool isOwnProfile) {
    bool canSee(bool show) => show || isOwnProfile || widget.readOnly;

    final rows = <Widget>[
      _buildDossierRow(
        Icons.calendar_month_rounded,
        'Yaş',
        canSee(_showAge) ? calculateAge(_selectedBirthDate?.toIso8601String())?.toString() : null,
      ),
      _buildDossierRow(
        Icons.height_rounded,
        'Boy',
        canSee(_showHeight) ? '${_heightController.text} cm' : null,
      ),
      _buildDossierRow(
        Icons.monitor_weight_outlined,
        'Kilo',
        canSee(_showWeight) ? '${_weightController.text} kg' : null,
      ),
      _buildDossierRow(
        Icons.track_changes_rounded,
        'Hedef',
        _selectedGoal?.toUIString() ?? 'Belirtilmedi',
      ),
      _buildDossierRow(
        Icons.bolt_rounded,
        'Aktivite',
        _selectedActivityLevel?.toUIString() ?? 'Belirtilmedi',
      ),
      _buildDossierRow(
        Icons.trending_up_rounded,
        'Deneyim',
        _selectedExperienceLevel?.toUIString() ?? 'Belirtilmedi',
      ),
    ];

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              const Divider(height: 1, thickness: 1, color: AppColors.glassBorder),
          ],
        ],
      ),
    );
  }

  Widget _buildDossierRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTextStyles.bodyText),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: value != null
                  ? Text(
                      value.replaceAll('_', ' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.listTitle,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 14),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          'Gizli',
                          style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
      );

  InputDecoration _buildInputDecoration(String label, IconData icon, {String? prefixText, String? hintText}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white10, fontSize: 12),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
      prefixText: prefixText,
      prefixStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      onChanged: (_) => setState(() {}),
      decoration: _buildInputDecoration(label, icon),
      validator: validator,
    );
  }

  Widget _buildSocialField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String prefix,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      onChanged: (_) => setState(() {}),
      decoration: _buildInputDecoration(label, icon, prefixText: prefix, hintText: hintText),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _selectedBirthDate ?? DateTime(2000),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );
        if (d != null) setState(() => _selectedBirthDate = d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.glassWhite,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Doğum Tarihi', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  Text(
                    _selectedBirthDate != null ? DateFormat('dd.MM.yyyy').format(_selectedBirthDate!) : 'Seçiniz',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required String Function(T) itemToString,
    required String label,
    required IconData icon,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(
                  itemToString(e),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ))
          .toList(),
      onChanged: (v) {
        onChanged(v);
        setState(() {});
      },
      dropdownColor: AppColors.background,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38),
      decoration: _buildInputDecoration(label, icon),
      validator: validator,
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) => SwitchListTile(title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)), value: value, onChanged: onChanged, activeThumbColor: AppColors.primary, contentPadding: const EdgeInsets.symmetric(horizontal: 16));

}
