import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/auth/data/repositories/auth_repository.dart';
import 'forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthRepository _repository;

  ForgotPasswordCubit(this._repository) : super(const ForgotPasswordState());

  Future<void> sendResetCode(String email) async {
    if (email.trim().isEmpty) {
      emit(state.copyWith(
        stage: ForgotPasswordStage.enterEmail,
        errorMessage: 'E-posta adresi boş bırakılamaz.',
      ));
      return;
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email.trim())) {
      emit(state.copyWith(
        stage: ForgotPasswordStage.enterEmail,
        errorMessage: 'Geçerli bir e-posta adresi giriniz.',
      ));
      return;
    }

    emit(state.copyWith(stage: ForgotPasswordStage.loading));
    final resp = await _repository.forgotPassword(email.trim());

    if (resp.success) {
      emit(state.copyWith(
        stage: ForgotPasswordStage.codeSent,
        email: email.trim(),
      ));
    } else {
      emit(state.copyWith(
        stage: ForgotPasswordStage.failure,
        errorMessage: resp.message,
      ));
    }
  }

  Future<void> resetPassword(String code, String newPassword) async {
    if (code.trim().isEmpty) {
      emit(state.copyWith(
        stage: ForgotPasswordStage.codeSent,
        errorMessage: 'Doğrulama kodu boş bırakılamaz.',
      ));
      return;
    }
    if (newPassword.length < 10) {
      emit(state.copyWith(
        stage: ForgotPasswordStage.codeSent,
        errorMessage: 'Yeni şifre en az 10 karakter olmalıdır.',
      ));
      return;
    }
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&.\-_])[A-Za-z\d@$!%*?&.\-_]{10,}$',
    );
    if (!passwordRegex.hasMatch(newPassword)) {
      emit(state.copyWith(
        stage: ForgotPasswordStage.codeSent,
        errorMessage: 'Şifre en az bir büyük harf, bir küçük harf, bir rakam ve bir özel karakter içermelidir.',
      ));
      return;
    }

    emit(state.copyWith(stage: ForgotPasswordStage.loading));
    final resp = await _repository.resetPassword(
      state.email,
      code.trim(),
      newPassword,
    );

    if (resp.success) {
      emit(state.copyWith(stage: ForgotPasswordStage.success));
    } else {
      emit(state.copyWith(
        stage: ForgotPasswordStage.codeSent,
        errorMessage: resp.message,
      ));
    }
  }
}
