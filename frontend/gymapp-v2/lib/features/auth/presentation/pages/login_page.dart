import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/login_form/login_form_cubit.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/registration_flow/registration_flow_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimens.dart';
import '../widgets/auth_input_field.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/premium_button.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LoginFormCubit>(),
      child: const LoginView(),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Kayıt akışı `push` ile açıldığından login sayfası yığında canlı kalır.
        // Arka plandayken global AuthBloc olaylarına (ör. kayıt sonrası AuthOtpRequired)
        // tepki verip yanlış mesaj göstermesini engelle: yalnızca login öndeyken işle.
        if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;

        if (state is AuthError) {
          _showError(context, state.message);
        }
        if (state is AuthOtpRequired) {
          // Telefonu doğrulanmamış hesap: yeni kod gönderildi, doğrulama ekranına geç.
          sl<RegistrationFlowCubit>().setEmailForVerification(state.email);
          _showError(context, 'Telefonunuz doğrulanmadı. Doğrulama kodu telefonunuza gönderildi.');
          context.go('/verify-otp');
        }
        if (state is AuthAuthenticated) {
          const storage = FlutterSecureStorage();
          storage.write(key: 'accessToken', value: state.auth.accessToken);

          context.go(
            '/main',
            extra: {
              'role': state.auth.role,
              'userId': state.auth.id,
              'accessToken': state.auth.accessToken,
            },
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(context),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                    _buildLoginForm(context, state),
                    const SizedBox(height: AppSpacing.xl),
                    _buildRegisterLink(context),
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
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset('assets/branding/app_icon.png'),
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
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Daha güçlü bir sen için hazır mısın?',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyText.copyWith(
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthState state) {
    final paddingVal = MediaQuery.of(context).size.width > 360 ? AppSpacing.xl : AppSpacing.md;
    return GlassContainer(
      padding: EdgeInsets.all(paddingVal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Giriş Yap',
            style: AppTextStyles.heroTitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          AuthInputField(
            controller: _emailController,
            label: 'E-posta',
            hint: 'ornek@email.com',
            icon: Icons.alternate_email_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          BlocBuilder<LoginFormCubit, LoginFormState>(
            builder: (context, loginFormState) {
              return AuthInputField(
                controller: _passwordController,
                label: 'Şifre',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                isPasswordVisible: loginFormState.isPasswordVisible,
                onToggleVisibility: () => context.read<LoginFormCubit>().togglePasswordVisibility(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              child: Text(
                'Şifremi Unuttum?',
                style: AppTextStyles.bodyText.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PremiumButton(
            text: 'Başlayalım',
            isLoading: state is AuthLoading,
            onPressed: () {
              context.read<AuthBloc>().add(
                LoginSubmitted(_emailController.text, _passwordController.text),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Henüz katılmadın mı?',
          style: AppTextStyles.bodyText,
        ),
        TextButton(
          onPressed: () => context.push('/register'),
          child: Text(
            'Kayıt Ol',
            style: AppTextStyles.bodyText.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showError(BuildContext context, String message) {
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
}


