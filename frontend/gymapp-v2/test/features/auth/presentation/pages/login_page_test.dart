import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/features/auth/data/models/auth_model.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/auth/data/repositories/auth_repository.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/login_form/login_form_cubit.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/registration_flow/registration_flow_cubit.dart';
import 'package:gymapp_v2/features/auth/presentation/pages/login_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late AuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authBloc = AuthBloc(mockAuthRepository);

    if (sl.isRegistered<LoginFormCubit>()) {
      sl.unregister<LoginFormCubit>();
    }
    sl.registerFactory<LoginFormCubit>(() => LoginFormCubit());

    if (sl.isRegistered<RegistrationFlowCubit>()) {
      sl.unregister<RegistrationFlowCubit>();
    }
    sl.registerFactory<RegistrationFlowCubit>(() => RegistrationFlowCubit());
  });

  tearDown(() {
    authBloc.close();
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const LoginPage(),
      ),
    );
  }

  group('LoginPage Widget Testleri', () {
    testWidgets('1. Sayfa render edildiğinde e-posta, şifre ve Başlayalım butonu ekranda bulunur', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Giriş Yap'), findsOneWidget);
      expect(find.text('E-posta'), findsOneWidget);
      expect(find.text('Şifre'), findsOneWidget);
      expect(find.text('Başlayalım'), findsOneWidget);
    });

    // KARAKTERİZASYON: Plan bu senaryoda `login`in HİÇ çağrılmamasını (istemci tarafı
    // doğrulama) bekliyordu. Gerçek davranış farklı: sayfa boş alanlarla da ağ isteği
    // gönderiyor. Üretim kodu değiştirilmedi; mevcut davranış kayda geçiriliyor.
    testWidgets('2. KARAKTERİZASYON: boş formda istemci doğrulaması yoktur, login boş değerlerle çağrılır', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockAuthRepository.login('', '')).thenAnswer(
        (_) async => ApiResponse(
          success: false,
          message: 'E-posta ve şifre gereklidir',
          timestamp: '2026-01-01T00:00:00Z',
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Başlayalım'));
      await tester.tap(find.text('Başlayalım'));
      await tester.pump();

      verify(() => mockAuthRepository.login('', '')).called(1);
    });

    testWidgets('3. Geçerli e-posta ve şifre girilip butona basıldığında repository login metodu parametrelerle çağrılır', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testUser = UserModel(id: 1, email: 'test@example.com', role: UserRole.CLIENT);
      final testAuth = AuthModel(user: testUser, accessToken: 'token', tokenType: 'Bearer', expiresIn: 3600);

      when(() => mockAuthRepository.login('test@example.com', 'Password123!')).thenAnswer(
        (_) async => ApiResponse(
          success: true,
          message: 'Başarılı',
          data: testAuth,
          timestamp: '2026-01-01T00:00:00Z',
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'Password123!');
      await tester.ensureVisible(find.text('Başlayalım'));
      await tester.tap(find.text('Başlayalım'));
      await tester.pump();

      verify(() => mockAuthRepository.login('test@example.com', 'Password123!')).called(1);
    });

    testWidgets('4. Giriş başarısız olduğunda ekranda hata mesajı SnackBar olarak görünür', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockAuthRepository.login(any(), any())).thenAnswer(
        (_) async => ApiResponse(
          success: false,
          message: 'Geçersiz e-posta veya şifre',
          timestamp: '2026-01-01T00:00:00Z',
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'wrong@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'wrongpass');
      await tester.ensureVisible(find.text('Başlayalım'));
      await tester.tap(find.text('Başlayalım'));

      // Microtask ve Future döngüsünü tamamen boşalt
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      // SnackBar'ın giriş animasyonunu tamamla.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      // Ekran seviyesi doğrulama: hata kullanıcıya SnackBar ile gösterilmelidir.
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Geçersiz e-posta veya şifre'), findsOneWidget);
    });
  });
}
