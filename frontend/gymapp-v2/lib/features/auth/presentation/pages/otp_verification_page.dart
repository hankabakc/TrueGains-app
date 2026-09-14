import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/otp_verification/otp_cubit.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/otp_verification/otp_state.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';

class OtpVerificationPage extends StatelessWidget {
  final String email;
  final void Function(BuildContext) onVerified;

  const OtpVerificationPage({
    super.key,
    required this.email,
    required this.onVerified,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<OtpCubit>(),
      child: OtpVerificationView(email: email, onVerified: onVerified),
    );
  }
}

class OtpVerificationView extends StatefulWidget {
  final String email;
  final void Function(BuildContext) onVerified;

  const OtpVerificationView({
    super.key,
    required this.email,
    required this.onVerified,
  });

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 6; i++) {
      _focusNodes[i].onKeyEvent = (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
          if (_controllers[i].text.isEmpty && i > 0) {
            _focusNodes[i - 1].requestFocus();
            _controllers[i - 1].clear();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      };
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    // 6 haneli kod yapıştırılmışsa parçala ve dağıt
    if (value.length >= 6) {
      final code = value.substring(0, 6);
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = code[i];
      }
      _focusNodes[5].requestFocus();
    } else if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    if (_controllers.every((c) => c.text.isNotEmpty)) {
      final otp = _controllers.map((c) => c.text).join();
      context.read<OtpCubit>().verifyOtp(widget.email, otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            // İptal: sunucuya istek atılmaz. Doğrulanmamış kayıt, aynı e-postayla yeniden
            // kaydolunduğunda otomatik olarak yenisiyle değiştirilir. Eski "kaydı sil" ucu
            // kimlik doğrulaması istemediği için kaldırıldı: e-postayı bilen herkes
            // OTP ekranında bekleyen bir kaydı silebiliyordu.
            // Oturumu kapat ki yönlendirme ana panele atmasın, login'e dönsün.
            context.read<AuthBloc>().add(LogoutRequested());
            context.go('/login');
          },
        ),
      ),
      body: BlocListener<OtpCubit, OtpState>(
        listener: (context, state) {
          if (state.status == OtpStatus.success && state.auth != null) {
            // Token doğrulamadan sonra verildi: oturumu burada aç.
            context.read<AuthBloc>().add(AuthVerified(state.auth!));
            widget.onVerified(context);
          } else if (state.status == OtpStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error ?? 'Doğrulama başarısız'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Doğrulama',
                style: AppTextStyles.heroDisplay,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${widget.email} adresine gönderilen 6 haneli kodu giriniz.',
                style: AppTextStyles.bodyText,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 45,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      onChanged: (v) => _onOtpChanged(index, v),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: index == 0 ? 6 : 1, // İlk kutu yapıştırma için 6 haneye izin verir
                      style: AppTextStyles.heroTitle.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        counterText: '',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: const BorderSide(
                            color: AppColors.glassBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        filled: true,
                        fillColor: AppColors.glassWhite,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: BlocBuilder<OtpCubit, OtpState>(
                  builder: (context, state) {
                    if (state.status == OtpStatus.loading) {
                      return const CircularProgressIndicator(
                        color: AppColors.primary,
                      );
                    }
                    final bool isTimerActive = state.resendTimer > 0;
                    return TextButton(
                      onPressed: isTimerActive
                          ? null
                          : () {
                              context.read<OtpCubit>().resendOtp(widget.email);
                            },
                      child: Text(
                        isTimerActive
                            ? 'Kodu Tekrar Gönder (${state.resendTimer}s)'
                            : 'Kodu Tekrar Gönder',
                        style: AppTextStyles.bodyText.copyWith(
                          color: isTimerActive
                              ? AppColors.textMuted
                              : AppColors.primary,
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
}
