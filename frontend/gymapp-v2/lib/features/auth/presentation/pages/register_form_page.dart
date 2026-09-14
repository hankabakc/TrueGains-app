import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/register_form/register_form_cubit.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/register_form/register_form_state.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/registration_flow/registration_flow_cubit.dart';
import 'package:gymapp_v2/features/auth/presentation/signup_steps.dart';
import 'package:gymapp_v2/features/auth/presentation/widgets/auth_input_field.dart';
import 'package:gymapp_v2/core/widgets/signup/intro_progress_bar.dart';
import 'package:gymapp_v2/core/widgets/signup/intro_question_scaffold.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class RegisterFormPage extends StatefulWidget {
  final UserRole role;

  const RegisterFormPage({super.key, required this.role});

  @override
  State<RegisterFormPage> createState() => _RegisterFormPageState();
}

class _RegisterFormPageState extends State<RegisterFormPage> {
  final _emailLocalController = TextEditingController();
  final _emailDomainController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _completePhoneNumber = '';
  late RegisterFormCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<RegisterFormCubit>();
  }

  @override
  void dispose() {
    _emailLocalController.dispose();
    _emailDomainController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int step = signupFormStep(widget.role);
    final int total = signupTotalSteps(widget.role);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.background,
        // resizeToAvoidBottomInset varsayılanı true: klavye açılınca içerik
        // alanı küçülür ve scaffold'un kaydırılabilir gövdesi devreye girer.
        body: SafeArea(
          child: Column(
            children: [
              IntroProgressBar(
                currentStep: step,
                totalSteps: total,
                label: signupStepLabel(step, total),
              ),
              Expanded(
                child: BlocBuilder<RegisterFormCubit, RegisterFormState>(
                  builder: (context, state) {
                    return IntroQuestionScaffold(
                      isActive: true,
                      title: 'Hesabını oluştur',
                      subtitle: widget.role == UserRole.COACH
                          ? 'Antrenör hesabın için doğrulama bilgileri.'
                          : 'Doğrulama için bu bilgiler gerekli.',
                      footer: PremiumButton(
                        text: 'DEVAM',
                        onPressed: _handleNext,
                      ),
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _phoneField(state),
                            const SizedBox(height: AppSpacing.lg),
                            _emailField(state),
                            const SizedBox(height: AppSpacing.lg),
                            AuthInputField(
                              controller: _passwordController,
                              label: 'Şifre',
                              hint: 'Minimum 10 karakter',
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                              isPasswordVisible: state.isPasswordVisible,
                              onToggleVisibility: _cubit.togglePasswordVisibility,
                              autofillHints: const [AutofillHints.newPassword],
                              errorText: state.passwordError,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AuthInputField(
                              controller: _confirmPasswordController,
                              label: 'Şifre Tekrar',
                              hint: 'Şifreni doğrula',
                              icon: Icons.lock_reset_rounded,
                              isPassword: true,
                              isPasswordVisible: state.isConfirmPasswordVisible,
                              onToggleVisibility:
                                  _cubit.toggleConfirmPasswordVisibility,
                              errorText: state.confirmPasswordError,
                            ),
                          ],
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
    );
  }

  /// E-posta iki parçada alınır; aradaki `@` yazılabilir bir karakter değil,
  /// sabit ayraç. Böylece kullanıcı `@`'i unutamaz veya iki kez yazamaz.
  Widget _emailField(RegisterFormState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'E-posta',
          style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              flex: 5,
              child: TextField(
                controller: _emailLocalController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                // Kullanıcı tam adresi yapıştırırsa alan otomatik bölünür.
                onChanged: _splitPastedEmail,
                style: AppTextStyles.bodyText.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: 'kullanici',
                  prefixIcon: Icon(
                    Icons.alternate_email_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                '@',
                style: AppTextStyles.listTitle.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: TextField(
                controller: _emailDomainController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: AppTextStyles.bodyText.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(hintText: 'email.com'),
              ),
            ),
          ],
        ),
        if (state.emailError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              state.emailError!,
              style: AppTextStyles.cardCaption.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }

  void _splitPastedEmail(String value) {
    if (!value.contains('@')) return;
    final int at = value.indexOf('@');
    _emailLocalController.value = TextEditingValue(
      text: value.substring(0, at),
      selection: TextSelection.collapsed(offset: at),
    );
    final String domain = value.substring(at + 1);
    if (domain.isNotEmpty) _emailDomainController.text = domain;
  }

  /// IntlPhoneField kendi etiketini üretmediği için AuthInputField'ın
  /// etiket + alan düzeni burada elle kurulur.
  Widget _phoneField(RegisterFormState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Telefon Numarası',
          style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        IntlPhoneField(
          decoration: InputDecoration(
            hintText: '5XX XXX XX XX',
            errorText: state.phoneError,
            prefixIcon: const Icon(
              Icons.phone_android_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            counterText: '',
          ),
          style: AppTextStyles.bodyText.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          dropdownTextStyle: AppTextStyles.bodyText.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          initialCountryCode: 'TR',
          languageCode: 'tr',
          pickerDialogStyle: PickerDialogStyle(
            searchFieldInputDecoration: const InputDecoration(
              hintText: 'Ülke Ara',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          onChanged: (phone) => _completePhoneNumber = phone.completeNumber,
          invalidNumberMessage: 'Geçersiz telefon numarası',
        ),
      ],
    );
  }

  void _handleNext() {
    final String local = _emailLocalController.text.trim();
    final String domain = _emailDomainController.text.trim();
    // İki parçadan biri boşsa geçersiz bir adres kurulur; cubit.validate
    // '@' içermeyen veya boş parçalı adresi zaten reddeder.
    final String email = (local.isEmpty || domain.isEmpty) ? '' : '$local@$domain';
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (_cubit.validate(email, password, confirmPassword, _completePhoneNumber)) {
      sl<RegistrationFlowCubit>().setCredentials(
        email: email,
        password: password,
        phoneNumber: _completePhoneNumber,
        role: widget.role,
      );
      context.push('/onboarding');
    }
  }
}
