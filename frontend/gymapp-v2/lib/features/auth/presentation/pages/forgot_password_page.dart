import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimens.dart';
import '../widgets/auth_input_field.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/premium_button.dart';
import '../bloc/forgot_password/forgot_password_cubit.dart';
import '../bloc/forgot_password/forgot_password_state.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ForgotPasswordCubit>(),
      child: const ForgotPasswordView(),
    );
  }
}

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          _showError(context, state.errorMessage!);
        }
        if (state.stage == ForgotPasswordStage.success) {
          _showSuccess(context, 'Şifreniz güncellendi, giriş yapabilirsiniz.');
          context.go('/login');
        }
      },
      builder: (context, state) {
        final isLoading = state.stage == ForgotPasswordStage.loading;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
              onPressed: () {
                if (state.stage == ForgotPasswordStage.codeSent) {
                  context.read<ForgotPasswordCubit>().sendResetCode(_emailController.text);
                } else {
                  context.pop();
                }
              },
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(context),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                    GlassContainer(
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width > 360 ? AppSpacing.xl : AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            state.stage == ForgotPasswordStage.codeSent
                                ? 'Şifreyi Sıfırla'
                                : 'Şifremi Unuttum',
                            style: AppTextStyles.heroTitle,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (state.stage != ForgotPasswordStage.codeSent) ...[
                            _buildEmailForm(context, isLoading),
                          ] else ...[
                            _buildResetForm(context, isLoading),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final logoSize = MediaQuery.of(context).size.width * 0.2;
    return Column(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_open_rounded,
            size: 40,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'TRUEGAINS',
          style: AppTextStyles.heroDisplay.copyWith(
            fontSize: 36,
            color: AppColors.textPrimary,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailForm(BuildContext context, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Şifrenizi sıfırlamak için hesabınıza kayıtlı e-posta adresinizi girin. Size bir doğrulama kodu göndereceğiz.',
          style: AppTextStyles.bodyText.copyWith(fontSize: 14),
        ),
        const SizedBox(height: AppSpacing.lg),
        AuthInputField(
          controller: _emailController,
          label: 'E-posta',
          hint: 'ornek@email.com',
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.xl),
        PremiumButton(
          text: 'Doğrulama Kodu Gönder',
          isLoading: isLoading,
          onPressed: () {
            final email = _emailController.text.trim();
            if (email.isEmpty) {
              _showError(context, 'E-posta adresi boş bırakılamaz.');
              return;
            }
            final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
            if (!emailRegex.hasMatch(email)) {
              _showError(context, 'Geçerli bir e-posta adresi giriniz.');
              return;
            }
            context.read<ForgotPasswordCubit>().sendResetCode(email);
          },
        ),
      ],
    );
  }

  Widget _buildResetForm(BuildContext context, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'E-posta adresinize gelen 6 haneli doğrulama kodunu ve yeni şifrenizi girin.',
          style: AppTextStyles.bodyText.copyWith(fontSize: 14),
        ),
        const SizedBox(height: AppSpacing.lg),
        AuthInputField(
          controller: _codeController,
          label: 'Doğrulama Kodu',
          hint: '6 haneli kod',
          icon: Icons.domain_verification_rounded,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.md),
        AuthInputField(
          controller: _passwordController,
          label: 'Yeni Şifre',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          isPasswordVisible: _isPasswordVisible,
          onToggleVisibility: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AuthInputField(
          controller: _confirmPasswordController,
          label: 'Yeni Şifre Tekrar',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          isPasswordVisible: _isConfirmPasswordVisible,
          onToggleVisibility: () {
            setState(() {
              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
            });
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        PremiumButton(
          text: 'Şifreyi Sıfırla',
          isLoading: isLoading,
          onPressed: () {
            final code = _codeController.text.trim();
            final newPassword = _passwordController.text;
            final confirmPassword = _confirmPasswordController.text;

            if (code.isEmpty) {
              _showError(context, 'Doğrulama kodu boş bırakılamaz.');
              return;
            }
            if (newPassword.isEmpty) {
              _showError(context, 'Yeni şifre alanı boş bırakılamaz.');
              return;
            }
            if (newPassword.length < 10) {
              _showError(context, 'Yeni şifre en az 10 karakter olmalıdır.');
              return;
            }
            final passwordRegex = RegExp(
              r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&.\-_])[A-Za-z\d@$!%*?&.\-_]{10,}$',
            );
            if (!passwordRegex.hasMatch(newPassword)) {
              _showError(context, 'Şifre en az bir büyük harf, bir küçük harf, bir rakam ve bir özel karakter içermelidir.');
              return;
            }
            if (newPassword != confirmPassword) {
              _showError(context, 'Girdiğiniz şifreler eşleşmiyor.');
              return;
            }

            context.read<ForgotPasswordCubit>().resetPassword(code, newPassword);
          },
        ),
      ],
    );
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.textPrimary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.textPrimary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }
}
