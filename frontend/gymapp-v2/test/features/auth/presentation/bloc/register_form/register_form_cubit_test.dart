import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/register_form/register_form_cubit.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/register_form/register_form_state.dart';

/// `RegisterFormCubit`, backend'deki `RegisterRequest.java` doğrulamasının istemci
/// aynasıdır. İki katman ayrışırsa kullanıcı formu doğru doldurduğunu sanır ama
/// sunucudan 400 alır (ya da tersi: istemci gereksiz yere engeller).
void main() {
  late RegisterFormCubit cubit;

  // Backend testlerindeki `RegisterRequestFixture` ile AYNI değerler.
  const validEmail = 'ali@test.com';
  const validPassword = 'Password123!';
  const validPhone = '+905555555555';

  setUp(() {
    cubit = RegisterFormCubit();
  });

  tearDown(() {
    cubit.close();
  });

  group('Geçerli girdi', () {
    test('backend fixture değerleri istemci doğrulamasından geçer', () {
      // Bu test iki katmanı birbirine bağlar: backend `RegisterRequestFixture` bu
      // şifreyi geçerli sayıyor, istemci de saymalı.
      expect(cubit.validate(validEmail, validPassword, validPassword, validPhone), isTrue);
      expect(cubit.state.emailError, isNull);
      expect(cubit.state.passwordError, isNull);
      expect(cubit.state.confirmPasswordError, isNull);
      expect(cubit.state.phoneError, isNull);
    });
  });

  group('E-posta doğrulaması', () {
    test('boş e-posta reddedilir', () {
      expect(cubit.validate('', validPassword, validPassword, validPhone), isFalse);
      expect(cubit.state.emailError, isNotNull);
    });

    test('@ içermeyen e-posta reddedilir', () {
      expect(cubit.validate('gecersiz', validPassword, validPassword, validPhone), isFalse);
      expect(cubit.state.emailError, 'Geçerli bir e-posta giriniz.');
    });

    test('alan adı uzantısı olmayan e-posta reddedilir', () {
      expect(cubit.validate('ali@test', validPassword, validPassword, validPhone), isFalse);
      expect(cubit.state.emailError, isNotNull);
    });
  });

  group('Şifre doğrulaması — backend deseniyle aynı kurallar', () {
    test('10 karakterden kısa şifre reddedilir', () {
      expect(cubit.validate(validEmail, 'Pass1!', 'Pass1!', validPhone), isFalse);
      expect(cubit.state.passwordError, isNotNull);
    });

    test('büyük harf içermeyen şifre reddedilir', () {
      expect(cubit.validate(validEmail, 'password123!', 'password123!', validPhone), isFalse);
      expect(cubit.state.passwordError, isNotNull);
    });

    test('rakam içermeyen şifre reddedilir', () {
      expect(cubit.validate(validEmail, 'PasswordAbc!', 'PasswordAbc!', validPhone), isFalse);
      expect(cubit.state.passwordError, isNotNull);
    });

    test('özel karakter içermeyen şifre reddedilir', () {
      expect(cubit.validate(validEmail, 'Password1234', 'Password1234', validPhone), isFalse);
      expect(cubit.state.passwordError, isNotNull);
    });

    test('şifreler uyuşmazsa reddedilir ve yalnızca onay alanı hatalanır', () {
      expect(cubit.validate(validEmail, validPassword, 'Password123?', validPhone), isFalse);
      expect(cubit.state.confirmPasswordError, 'Şifreler uyuşmuyor.');
      // Şifrenin kendisi kurallara uyduğu için o alan hatasız kalmalı.
      expect(cubit.state.passwordError, isNull);
    });
  });

  group('Telefon doğrulaması', () {
    test('boş telefon reddedilir', () {
      expect(cubit.validate(validEmail, validPassword, validPassword, ''), isFalse);
      expect(cubit.state.phoneError, 'Telefon numarası zorunludur.');
    });

    test('10 haneden kısa telefon reddedilir', () {
      expect(cubit.validate(validEmail, validPassword, validPassword, '12345'), isFalse);
      expect(cubit.state.phoneError, isNotNull);
    });
  });

  group('Hata birikmesi', () {
    test('hatalı form düzeltilip yeniden doğrulanınca eski hatalar temizlenir', () {
      cubit.validate('', 'kisa', 'farkli', '');
      expect(cubit.state.emailError, isNotNull);

      expect(cubit.validate(validEmail, validPassword, validPassword, validPhone), isTrue);
      // Eski hatalar kalırsa kullanıcı formu düzeltse bile hata görmeye devam eder.
      expect(cubit.state.emailError, isNull);
      expect(cubit.state.passwordError, isNull);
      expect(cubit.state.confirmPasswordError, isNull);
      expect(cubit.state.phoneError, isNull);
    });
  });

  group('Şifre görünürlüğü', () {
    blocTest<RegisterFormCubit, RegisterFormState>(
      'şifre görünürlüğü değiştirilebilir ve onay alanını etkilemez',
      build: () => RegisterFormCubit(),
      act: (c) => c.togglePasswordVisibility(),
      verify: (c) {
        expect(c.state.isPasswordVisible, isTrue);
        expect(c.state.isConfirmPasswordVisible, isFalse);
      },
    );
  });
}
