import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/features/membership/presentation/pages/onboarding_page.dart';
import 'package:gymapp_v2/features/membership/presentation/bloc/onboarding/onboarding_cubit.dart';
import 'package:gymapp_v2/features/social/data/services/file_api_service.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/auth/data/repositories/auth_repository.dart';
import 'package:gymapp_v2/features/auth/data/models/auth_model.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';

class MockDioClient extends Mock implements DioClient {}

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeFileApiService extends FileApiService {
  FakeFileApiService() : super(MockDioClient());

  @override
  Future<ApiResponse<Map<String, String>>> uploadFile(
    String filePath,
    String fileName,
  ) async {
    return ApiResponse<Map<String, String>>(
      success: true,
      message: 'Başarılı',
      timestamp: DateTime.now().toIso8601String(),
      data: {'url': 'https://example.com/photo.jpg'},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockAuthRepository;
  late AuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    sl.reset();

    mockAuthRepository = MockAuthRepository();

    when(() => mockAuthRepository.register(any())).thenAnswer(
      (_) async => ApiResponse<AuthModel>(
        success: true,
        message: 'Başarılı',
        timestamp: DateTime.now().toIso8601String(),
        data: null,
      ),
    );

    sl.registerFactory<OnboardingCubit>(() => OnboardingCubit());
    sl.registerLazySingleton<FileApiService>(() => FakeFileApiService());

    authBloc = AuthBloc(mockAuthRepository);
  });

  tearDown(() async {
    await authBloc.close();
    await sl.reset();
  });

  void setupMockImagePicker() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/image_picker'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'pickImage') {
          return 'fake_path/image.png';
        }
        return null;
      },
    );
  }

  testWidgets('Koç Rolü - Biyografi Eksik Olduğunda Hata Verir ve İlerleyemez', (WidgetTester tester) async {
    setupMockImagePicker();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const OnboardingPage(
            email: 'koc@test.com',
            password: 'Password123',
            phoneNumber: '+905555555555',
            role: UserRole.COACH,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Fill first name and last name, leave biography empty
    await tester.enterText(find.byType(TextField).at(0), 'Ahmet');
    await tester.enterText(find.byType(TextField).at(1), 'Yılmaz');

    // Tap forward button
    await tester.tap(find.widgetWithText(PremiumButton, 'DEVAM'));
    await tester.pumpAndSettle();

    // Verify error message is shown
    expect(find.text('Danışanların seni tanıyabilmesi için bu alan zorunlu.'), findsOneWidget);
  });

  testWidgets('Koç Rolü - Tüm Alanlar Dolu Olduğunda Başarıyla İlerler', (WidgetTester tester) async {
    setupMockImagePicker();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const OnboardingPage(
            email: 'koc@test.com',
            password: 'Password123',
            phoneNumber: '+905555555555',
            role: UserRole.COACH,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Fill first name, last name, and biography
    await tester.enterText(find.byType(TextField).at(0), 'Ahmet');
    await tester.enterText(find.byType(TextField).at(1), 'Yılmaz');
    await tester.enterText(find.byType(TextField).at(2), '20 yıllık fitness ve vücut geliştirme tecrübesine sahibim.');

    // Tap forward button
    await tester.tap(find.widgetWithText(PremiumButton, 'DEVAM'));
    await tester.pumpAndSettle();

    // Verify it moves forward to photo step without error
    expect(find.text('Danışanların seni tanıyabilmesi için bu alan zorunlu.'), findsNothing);
    expect(find.text('Profil fotoğrafın'), findsOneWidget);
  });

  testWidgets('Üye (Client) Rolü - Biyografi Boş Olsa Bile Başarıyla İlerler', (WidgetTester tester) async {
    setupMockImagePicker();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const OnboardingPage(
            email: 'uye@test.com',
            password: 'Password123',
            phoneNumber: '+905555555555',
            role: UserRole.CLIENT,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Fill first name and last name for client, leave bio empty
    await tester.enterText(find.byType(TextField).at(0), 'Can');
    await tester.enterText(find.byType(TextField).at(1), 'Demir');

    // Tap forward button
    await tester.tap(find.widgetWithText(PremiumButton, 'DEVAM'));
    await tester.pumpAndSettle();

    // Verify it moves forward to photo step without error
    expect(find.text('Danışanların seni tanıyabilmesi için bu alan zorunlu.'), findsNothing);
    expect(find.text('Profil fotoğrafın'), findsOneWidget);
  });
}
