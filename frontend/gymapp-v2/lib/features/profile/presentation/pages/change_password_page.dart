import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_event.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_state.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  final ValueNotifier<bool> _obscureCurrent = ValueNotifier(true);
  final ValueNotifier<bool> _obscureNew = ValueNotifier(true);
  final ValueNotifier<bool> _obscureConfirm = ValueNotifier(true);

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _obscureCurrent.dispose();
    _obscureNew.dispose();
    _obscureConfirm.dispose();
    super.dispose();
  }

  void _changePassword() {
    if (!_formKey.currentState!.validate()) return;

    context.read<ProfileBloc>().add(
      ChangePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is PasswordChangeSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Şifreniz başarıyla güncellendi.')),
          );
          context.pop();
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Şifre ve Güvenlik',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 20),
                  child: Text(
                    'HESAP GÜVENLİĞİ',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: _obscureCurrent,
                        builder: (context, obscure, _) {
                          return _buildPasswordField(
                            controller: _currentController,
                            label: 'Mevcut Şifre',
                            obscure: obscure,
                            onToggle: () => _obscureCurrent.value = !_obscureCurrent.value,
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ValueListenableBuilder<bool>(
                        valueListenable: _obscureNew,
                        builder: (context, obscure, _) {
                          return _buildPasswordField(
                            controller: _newController,
                            label: 'Yeni Şifre',
                            obscure: obscure,
                            onToggle: () => _obscureNew.value = !_obscureNew.value,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Gerekli';
                              if (value.length < 10) return 'En az 10 karakter olmalı';
                              // Register ile aynı karmaşıklık kuralı.
                              final passwordRegex = RegExp(
                                r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&.\-_])[A-Za-z\d@$!%*?&.\-_]{10,}$',
                              );
                              if (!passwordRegex.hasMatch(value)) {
                                return 'Büyük harf, küçük harf, rakam ve özel karakter içermelidir';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ValueListenableBuilder<bool>(
                        valueListenable: _obscureConfirm,
                        builder: (context, obscure, _) {
                          return _buildPasswordField(
                            controller: _confirmController,
                            label: 'Yeni Şifre Tekrar',
                            obscure: obscure,
                            onToggle: () => _obscureConfirm.value = !_obscureConfirm.value,
                            validator: (value) {
                              if (value != _newController.text) return 'Şifreler eşleşmiyor';
                              return null;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, state) {
                      final isSaving = state is ProfileLoading;
                      return ElevatedButton(
                        onPressed: isSaving ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          elevation: 0,
                        ),
                        child:
                            isSaving
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'ŞİFREYİ GÜNCELLE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textPrimary),
      validator:
          validator ??
          (value) => value == null || value.isEmpty ? 'Gerekli' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: const Icon(
          Icons.lock_rounded,
          color: AppColors.primary,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary),
        ),
        errorStyle: const TextStyle(color: AppColors.error),
      ),
    );
  }
}
