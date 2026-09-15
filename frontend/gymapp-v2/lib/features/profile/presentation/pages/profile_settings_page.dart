import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/network_avatar.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_event.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_state.dart';

class ProfileSettingsPage extends StatelessWidget {
  final UserRole role;
  final int userId;

  const ProfileSettingsPage({
    super.key,
    required this.role,
    required this.userId,
  });

  Future<void> _handleLogout(BuildContext context) async {
    // Merkezi logout akışını tetikle
    context.read<AuthBloc>().add(LogoutRequested());
    // Not: Yönlendirme app_router.dart içindeki refreshListenable ile otomatik yapılacak.
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => GlassContainer(
            margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 260),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Hesabımı Sil',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Hesabın ve tüm verilerin kalıcı olarak silinecek: profil bilgilerin, ölçümlerin, antrenman ve beslenme kayıtların, mesajların. Bu işlem geri alınamaz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Vazgeç',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.read<ProfileBloc>().add(const DeleteAccount());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                            ),
                            child: const Text(
                              'Hesabımı Sil',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => GlassContainer(
            margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 300),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Çıkış Yap',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'İPTAL',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _handleLogout(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                            ),
                            child: const Text(
                              'ÇIKIŞ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profil ve Ayarlar',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is AccountDeleteSuccess) {
            // Hesap sunucuda silindi, jeton ölü. Çıkış bekleyen kayıtları göndermeye çalışmaz;
            // cihazdaki jeton, çerez ve önbelleği temizler (AuthRepository.logout).
            context.read<AuthBloc>().add(const LogoutRequested(syncPending: false));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hesabın silindi.')),
            );
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            // Sayfa profil bilgilerini state'ten çiziyor; ProfileError hiçbir dala girmediği için
            // ekran "İsimsiz" ve boş e-postayla kalıyordu. Hata gösterildikten sonra profil
            // yeniden çekilir.
            context.read<ProfileBloc>().add(FetchProfile(isCoach: role == UserRole.COACH));
          }
        },
        builder: (context, state) {
          String fullName = 'İsimsiz';
          String email = '';
          String? photoUrl;
          String? bio;
          dynamic profileData;
          bool isLoading = false;

          if (state is ProfileLoading) {
            isLoading = true;
          } else if (state is ProfileLoaded) {
            profileData = state.profile;
            fullName = state.profile.fullName;
            email = state.profile.email;
            photoUrl = state.profile.profilePhotoUrl;
            bio = state.profile.bio;
          } else if (state is CoachProfileLoaded) {
            profileData = state.profile;
            fullName = state.profile.fullName;
            email = state.profile.email;
            photoUrl = state.profile.profilePhotoUrl;
            bio = state.profile.bio;
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProfileBloc>().add(FetchProfile(isCoach: role == UserRole.COACH));
            },
            color: AppColors.primary,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildUserCard(
                    context: context,
                    fullName: fullName,
                    email: email,
                    photoUrl: photoUrl,
                    bio: bio,
                    profileData: profileData,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'HESAP AYARLARI',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (role == UserRole.CLIENT)
                    _buildSettingTile(
                      icon: Icons.history_rounded,
                      title: 'Zaman Tüneli (Galerim)',
                      onTap: () => context.push('/profile/gallery'),
                    ),
                  _buildSettingTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Şifre ve Güvenlik',
                    onTap: () => context.push('/profile/change-password'),
                  ),
                  if (role == UserRole.CLIENT)
                    _buildSettingTile(
                      icon: Icons.card_membership_rounded,
                      title: 'Ödemeler & Sepetim',
                      onTap: () => context.push('/my-subscription'),
                    ),
                  if (role == UserRole.COACH)
                    _buildSettingTile(
                      icon: Icons.payments_outlined,
                      title: 'Paket Yönetimi',
                      onTap: () => context.push('/coach/packages'),
                    ),
                  _buildSettingTile(
                    icon: Icons.delete_forever_rounded,
                    title: 'Hesabımı Sil',
                    color: AppColors.error,
                    onTap: () => _showDeleteAccountDialog(context),
                  ),
                  const SizedBox(height: 32),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'DESTEK VE HAKKINDA',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Uygulama Hakkında',
                    onTap: () => context.push('/profile/about'),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                      label: const Text(
                        'OTURUMU KAPAT',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserCard({
    required BuildContext context,
    required String fullName,
    required String email,
    required String? photoUrl,
    required String? bio,
    required dynamic profileData,
    required bool isLoading,
  }) {
    if (isLoading) {
      return GlassContainer(
        padding: const EdgeInsets.all(24),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return InkWell(
      onTap: () async {
        if (profileData != null) {
          if (role == UserRole.COACH) {
            await context.push(
              Uri(
                path: '/coach-profile/$userId',
                queryParameters: {'name': fullName},
              ).toString(),
            );
            if (context.mounted) {
              context.read<ProfileBloc>().add(const FetchProfile(isCoach: true));
            }
          } else {
            // SPORCU İÇİN: Birleşik Profil sayfasına (Düzenle/Önizleme) yönlendir.
            await context.push('/profile/detail', extra: profileData);
            if (context.mounted) {
              context.read<ProfileBloc>().add(const FetchProfile(isCoach: false));
            }
          }
        }
      },
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            NetworkAvatar(
              imageUrl: photoUrl,
              size: 72,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName.trim().isEmpty ? 'İsimsiz' : fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    email,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  if (bio != null && bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: role == UserRole.COACH
                              ? Colors.blue.withValues(alpha: 0.2)
                              : AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          role == UserRole.COACH ? 'ANTRENÖR' : 'SPORCU',
                          style: TextStyle(
                            color: role == UserRole.COACH ? Colors.blue : AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.edit_note_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.glassWhite,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color ?? AppColors.textPrimary, size: 20),
        ),
        title: Text(
          title,
          style: AppTextStyles.listTitle.copyWith(
            color: color,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: color?.withValues(alpha: 0.5) ?? AppColors.glassBorder,
          size: 20,
        ),
      ),
    );
  }
}
