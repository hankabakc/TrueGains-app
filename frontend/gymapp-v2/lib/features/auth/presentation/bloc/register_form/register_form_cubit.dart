import 'package:flutter_bloc/flutter_bloc.dart';
import 'register_form_state.dart';

class RegisterFormCubit extends Cubit<RegisterFormState> {
  RegisterFormCubit() : super(const RegisterFormState());

  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  void toggleConfirmPasswordVisibility() {
    emit(state.copyWith(isConfirmPasswordVisible: !state.isConfirmPasswordVisible));
  }

  bool validate(String email, String password, String confirmPassword, String phoneNumber) {
    String? emailError;
    String? passwordError;
    String? confirmPasswordError;
    String? phoneError;

    // RegisterRequest.java'daki desenin aynısı; istemcide kontrol edilmezse
    // kullanıcı formu doldurup sunucudan 400 alıyor.
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );

    if (email.isEmpty) {
      emailError = 'E-postanın iki parçasını da doldurmalısın.';
    } else if (!emailRegex.hasMatch(email)) {
      emailError = 'Geçerli bir e-posta giriniz.';
    }

    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&.\-_])[A-Za-z\d@$!%*?&.\-_]{10,}$',
    );

    if (password.isEmpty) {
      passwordError = 'Şifre alanı boş bırakılamaz.';
    } else if (!passwordRegex.hasMatch(password)) {
      passwordError = 'Şifre en az 10 karakter olmalı; büyük harf, küçük harf, rakam ve özel karakter içermelidir.';
    }

    if (password != confirmPassword) {
      confirmPasswordError = 'Şifreler uyuşmuyor.';
    }

    if (phoneNumber.isEmpty) {
      phoneError = 'Telefon numarası zorunludur.';
    } else if (phoneNumber.length < 10) {
      phoneError = 'Geçerli bir telefon numarası giriniz.';
    }

    emit(state.copyWith(
      emailError: emailError,
      passwordError: passwordError,
      confirmPasswordError: confirmPasswordError,
      phoneError: phoneError,
    ));

    return emailError == null && passwordError == null && confirmPasswordError == null && phoneError == null;
  }
}
