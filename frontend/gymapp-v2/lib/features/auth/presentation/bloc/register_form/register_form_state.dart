import 'package:equatable/equatable.dart';

class RegisterFormState extends Equatable {
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? phoneError;

  const RegisterFormState({
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    this.phoneError,
  });

  RegisterFormState copyWith({
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
    String? emailError,
    String? passwordError,
    String? confirmPasswordError,
    String? phoneError,
  }) {
    return RegisterFormState(
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible: isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      emailError: emailError,
      passwordError: passwordError,
      confirmPasswordError: confirmPasswordError,
      phoneError: phoneError,
    );
  }

  @override
  List<Object?> get props => [
    isPasswordVisible,
    isConfirmPasswordVisible,
    emailError,
    passwordError,
    confirmPasswordError,
    phoneError,
  ];
}
