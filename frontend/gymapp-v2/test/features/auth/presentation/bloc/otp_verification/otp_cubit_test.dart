import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/features/auth/data/models/auth_model.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/auth/data/repositories/auth_repository.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/otp_verification/otp_cubit.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/otp_verification/otp_state.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  final testAuth = AuthModel(
    user: UserModel(id: 1, email: 'test@example.com', role: UserRole.CLIENT),
    accessToken: 'token',
    tokenType: 'Bearer',
    expiresIn: 3600,
  );

  ApiResponse<T> ok<T>(T? data) => ApiResponse<T>(
        success: true,
        message: 'Başarılı',
        data: data,
        timestamp: '2026-01-01T00:00:00Z',
      );

  ApiResponse<T> fail<T>(String message) => ApiResponse<T>(
        success: false,
        message: message,
        timestamp: '2026-01-01T00:00:00Z',
      );

  setUp(() {
    repository = MockAuthRepository();
  });

  group('OtpCubit doğrulama', () {
    blocTest<OtpCubit, OtpState>(
      '6 haneden kısa kod girildiğinde → ağ isteği yapılmaz, hata mesajı gösterilir',
      build: () => OtpCubit(repository),
      act: (cubit) => cubit.verifyOtp('test@example.com', '123'),
      verify: (cubit) {
        expect(cubit.state.status, OtpStatus.failure);
        expect(cubit.state.error, 'Doğrulama kodu 6 haneli olmalıdır.');
        // İstemci tarafı koruma: eksik kod backend'e hiç gitmemeli.
        verifyNever(() => repository.verifyOtp(any(), any()));
      },
    );

    blocTest<OtpCubit, OtpState>(
      'geçerli kod doğrulandığında → success durumu ve oturum bilgisi taşınır',
      build: () {
        when(() => repository.verifyOtp('test@example.com', '123456'))
            .thenAnswer((_) async => ok<AuthModel>(testAuth));
        return OtpCubit(repository);
      },
      act: (cubit) => cubit.verifyOtp('test@example.com', '123456'),
      verify: (cubit) {
        expect(cubit.state.status, OtpStatus.success);
        expect(cubit.state.auth, testAuth);
      },
    );

    blocTest<OtpCubit, OtpState>(
      'backend kodu reddettiğinde → failure durumu ve backend mesajı gösterilir',
      build: () {
        when(() => repository.verifyOtp('test@example.com', '999999'))
            .thenAnswer((_) async => fail<AuthModel>('Geçersiz doğrulama kodu.'));
        return OtpCubit(repository);
      },
      act: (cubit) => cubit.verifyOtp('test@example.com', '999999'),
      verify: (cubit) {
        expect(cubit.state.status, OtpStatus.failure);
        expect(cubit.state.error, 'Geçersiz doğrulama kodu.');
        // Hatalı kodda oturum bilgisi kesinlikle set edilmemeli.
        expect(cubit.state.auth, isNull);
      },
    );
  });

  group('OtpCubit yeniden gönderim kilidi', () {
    test('cubit oluşturulduğunda geri sayım 60 saniyeden başlar', () {
      final cubit = OtpCubit(repository);
      expect(cubit.state.resendTimer, 60);
      cubit.close();
    });

    blocTest<OtpCubit, OtpState>(
      'geri sayım sürerken yeniden gönderim istenirse → istek gönderilmez',
      build: () => OtpCubit(repository),
      act: (cubit) => cubit.resendOtp('test@example.com'),
      verify: (cubit) {
        // Backend'deki 60 sn soğuma süresinin (R4) istemci tarafı karşılığı.
        // Bu kilit olmasaydı kullanıcı butona basarak SMS bombardımanı tetikleyebilirdi.
        verifyNever(() => repository.resendOtp(any()));
      },
    );
  });

  // BİLİNEN SINIR: "geri sayım bittikten sonra yeniden gönderim çalışır" senaryosu
  // yazılmadı. Sayaç gerçek `Timer.periodic` ile 60 saniye sürüyor ve cubit dışarıdan
  // sıfırlanamıyor; test etmek için `fake_async` bağımlılığı veya üretim kodunda
  // saat enjeksiyonu gerekir. İkisi de bu turun kapsamı dışında bırakıldı.
}
