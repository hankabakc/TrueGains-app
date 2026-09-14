import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/config/app_config.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/features/profile/data/models/client_profile_response_model.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_event.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_state.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_form/profile_form_cubit.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_form/profile_form_state.dart';
import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';
import 'package:gymapp_v2/features/auth/data/models/goal.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/features/social/data/services/file_api_service.dart';

class PersonalInfoPage extends StatefulWidget {
  final ClientProfileResponseModel profileData;

  const PersonalInfoPage({super.key, required this.profileData});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _instagramController;
  late TextEditingController _tiktokController;
  late ProfileFormCubit _formCubit;
  bool _isUploadingPhoto = false;



  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.profileData.fullName.trim().isEmpty
          ? 'İsimsiz'
          : widget.profileData.fullName,
    );
    _bioController = TextEditingController(text: widget.profileData.bio);
    _heightController = TextEditingController(
      text: widget.profileData.heightCm?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.profileData.weightKg?.toString() ?? '',
    );
    _instagramController =
        TextEditingController(text: _parseUsername(widget.profileData.instagramUrl ?? '', 'instagram.com/'));
    _tiktokController =
        TextEditingController(text: _parseUsername(widget.profileData.tiktokUrl ?? '', 'tiktok.com/@'));

    _formCubit = ProfileFormCubit(widget.profileData);
  }

  String _parseUsername(String url, String domainWithSlash) {
    if (url.isEmpty) return '';
    try {
      final index = url.indexOf(domainWithSlash);
      if (index != -1) {
        String username = url.substring(index + domainWithSlash.length);
        if (username.endsWith('/')) {
          username = username.substring(0, username.length - 1);
        }
        final queryIndex = username.indexOf('?');
        if (queryIndex != -1) {
          username = username.substring(0, queryIndex);
        }
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
    _heightController.dispose();
    _weightController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _formCubit.close();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _formCubit.state.birthDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.background,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _formCubit.updateBirthDate(picked);
    }
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen formdaki eksik veya geçersiz alanları kontrol ediniz.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final updateData = _formCubit.buildUpdatePayload(
      instagramInput: _instagramController.text,
      tiktokInput: _tiktokController.text,
    );

    context.read<ProfileBloc>().add(
          UpdateProfile(
              userId: widget.profileData.userId, updateData: updateData),
        );
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    if (_isUploadingPhoto) return;
    setState(() => _isUploadingPhoto = true);

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final result = await sl<FileApiService>().uploadFile(image.path, image.name);
        if (result.success && result.data != null) {
          _formCubit.updateProfilePhoto(result.data!['url']);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(result.message),
                  backgroundColor: AppColors.error),
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _formCubit,
      child: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            context.read<ProfileBloc>().add(const FetchProfile(isCoach: false));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profil başarıyla güncellendi.')),
            );
            context.pop(true);
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: GestureDetector(
              onLongPress: () {
                throw Exception('Sentry Frontend QA Test: Kontrollü Hata');
              },
              child: const Text(
                'Kişisel Bilgiler',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, state) {
                  if (state is ProfileLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  return IconButton(
                    onPressed: _saveProfile,
                    icon: const Icon(
                      Icons.check_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  );
                },
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: BlocBuilder<ProfileFormCubit, ProfileFormState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfilePhotoSection(state.profilePhotoUrl),
                      const SizedBox(height: 32),
                      _buildSectionTitle('KİMLİK BİLGİLERİ'),
                      GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              label: 'Ad Soyad',
                              icon: Icons.person_rounded,
                              onChanged: (v) => _formCubit.updateFullName(v),
                            ),
                            const SizedBox(height: 16),
                            _buildDatePickerTile(state.birthDate),
                            const SizedBox(height: 16),
                            _buildDropdown<Gender>(
                              value: state.gender,
                              items: Gender.values,
                              itemToString: (g) => g.toUIString(),
                              label: 'Cinsiyet',
                              icon: Icons.wc_rounded,
                              onChanged: (v) => _formCubit.updateGender(v),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _bioController,
                              label: 'Biyografi',
                              icon: Icons.edit_note_rounded,
                              maxLines: 3,
                              onChanged: (v) => _formCubit.updateBio(v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle('SOSYAL MEDYA VE BAĞLANTILAR'),
                      GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildSocialField(
                              controller: _instagramController,
                              label: 'Instagram Kullanıcı Adı',
                              icon: Icons.camera_alt_outlined,
                              prefix: 'www.instagram.com/',
                              hint: 'kullaniciadi',
                              onChanged: (v) {
                                final fullUrl = v.isEmpty ? '' : 'www.instagram.com/$v';
                                _formCubit.updateInstagramUrl(fullUrl);
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildSocialField(
                              controller: _tiktokController,
                              label: 'TikTok Kullanıcı Adı',
                              icon: Icons.play_circle_outline_rounded,
                              prefix: 'www.tiktok.com/@',
                              hint: 'kullaniciadi',
                              onChanged: (v) {
                                final clean = v.startsWith('@') ? v.substring(1) : v;
                                final fullUrl = clean.isEmpty ? '' : 'www.tiktok.com/@$clean';
                                _formCubit.updateTiktokUrl(fullUrl);
                              },
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
                                    onChanged: (v) => _formCubit.updateHeightCm(int.tryParse(v)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _weightController,
                                    label: 'Kilo (kg)',
                                    icon: Icons.monitor_weight_rounded,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    onChanged: (v) => _formCubit.updateWeightKg(double.tryParse(v)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildDropdown<Goal>(
                              value: state.goal,
                              items: Goal.values,
                              itemToString: (g) => g.toUIString(),
                              label: 'Hedef',
                              icon: Icons.track_changes_rounded,
                              onChanged: (v) => _formCubit.updateGoal(v),
                              validator: (value) => value == null
                                  ? 'Lütfen bir hedef seçiniz.'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildDropdown<ActivityLevel>(
                              value: state.activityLevel,
                              items: ActivityLevel.values,
                              itemToString: (a) => a.toUIString(),
                              label: 'Aktivite Seviyesi',
                              icon: Icons.bolt_rounded,
                              onChanged: (v) =>
                                  _formCubit.updateActivityLevel(v),
                              validator: (value) => value == null
                                  ? 'Lütfen aktivite seviyenizi seçiniz.'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle('GİZLİLİK VE GÖSTERİM'),
                      GlassContainer(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            _buildSwitchTile(
                              title: 'Yaşımı Göster',
                              value: state.showAge,
                              onChanged: (v) => _formCubit.toggleShowAge(v),
                            ),
                            _buildSwitchTile(
                              title: 'Boyumu Göster',
                              value: state.showHeight,
                              onChanged: (v) => _formCubit.toggleShowHeight(v),
                            ),
                            _buildSwitchTile(
                              title: 'Kilomu Göster',
                              value: state.showWeight,
                              onChanged: (v) => _formCubit.toggleShowWeight(v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSection(String? currentUrl) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: ClipOval(
              child: _isUploadingPhoto
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2))
                  : (currentUrl != null
                      ? CachedNetworkImage(
                          imageUrl: AppConfig.resolveFileUrl(currentUrl),
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: Colors.white.withValues(alpha: 0.05)),
                          errorWidget: (context, url, error) => const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white24),
                        )
                      : const Icon(Icons.person, size: 50, color: Colors.white24)),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickAndUploadProfilePhoto,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSocialField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String prefix,
    String? hint,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          style: AppTextStyles.bodyText,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            prefix: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                prefix,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
              ),
            ),
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: AppTextStyles.bodyText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildDatePickerTile(DateTime? selectedDate) {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.glassBorder),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Doğum Tarihi',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                Text(
                  selectedDate != null
                      ? DateFormat('dd.MM.yyyy').format(selectedDate)
                      : 'Seçiniz',
                  style: AppTextStyles.bodyText,
                ),
              ],
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
      key: ValueKey(value),
      initialValue: items.contains(value) ? value : null,
      isExpanded: true,
      items: items
          .map(
            (e) => DropdownMenuItem<T>(
              value: e,
              child: Text(
                itemToString(e),
                style: AppTextStyles.bodyText,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
      dropdownColor: AppColors.background,
      style: AppTextStyles.bodyText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyText,
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
