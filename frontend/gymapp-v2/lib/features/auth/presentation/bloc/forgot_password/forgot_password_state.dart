import 'package:equatable/equatable.dart';

enum ForgotPasswordStage { enterEmail, codeSent, loading, success, failure }

class ForgotPasswordState extends Equatable {
  final ForgotPasswordStage stage;
  final String email;
  final String? errorMessage;

  const ForgotPasswordState({
    this.stage = ForgotPasswordStage.enterEmail,
    this.email = '',
    this.errorMessage,
  });

  ForgotPasswordState copyWith({
    ForgotPasswordStage? stage,
    String? email,
    String? errorMessage,
  }) {
    return ForgotPasswordState(
      stage: stage ?? this.stage,
      email: email ?? this.email,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [stage, email, errorMessage];
}
