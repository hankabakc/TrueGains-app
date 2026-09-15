import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/navigation/last_route_store.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/features/auth/data/models/auth_model.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/auth/data/repositories/auth_repository.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/dashboard/presentation/bloc/navigation/navigation_cubit.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/chat_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockChatBloc extends Mock implements ChatBloc {}
class MockNavigationCubit extends Mock implements NavigationCubit {}
class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockAuthRepository mockAuthRepository;

  final testUser = UserModel(
    id: 1,
    email: 'test@example.com',
    role: UserRole.CLIENT,
  );

  final testAuthModel = AuthModel(
    user: testUser,
    accessToken: 'test_token',
    tokenType: 'Bearer',
    expiresIn: 3600,
  );

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    when(() => mockAuthRepository.syncPending()).thenAnswer((_) async {});

    if (sl.isRegistered<ChatBloc>()) {
      sl.unregister<ChatBloc>();
    }
    if (sl.isRegistered<NavigationCubit>()) {
      sl.unregister<NavigationCubit>();
    }
    if (sl.isRegistered<LastRouteStore>()) {
      sl.unregister<LastRouteStore>();
    }

    final mockPrefs = MockSharedPreferences();
    when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);
    when(() => mockPrefs.getString(any())).thenReturn(null);

    sl.registerLazySingleton<ChatBloc>(() => MockChatBloc());
    sl.registerLazySingleton<NavigationCubit>(() => MockNavigationCubit());
    sl.registerSingleton<LastRouteStore>(LastRouteStore(mockPrefs));
  });

  test('BLoC oluşturulduğunda ilk durum AuthInitial durumundadır', () {
    final bloc = AuthBloc(mockAuthRepository);
    expect(bloc.state, equals(AuthInitial()));
    bloc.close();
  });

  blocTest<AuthBloc, AuthState>(
    'başarılı giriş yapıldığında → AuthLoading ve ardından AuthAuthenticated durumları yayımlanır',
    build: () {
      when(() => mockAuthRepository.login('test@example.com', 'Password123!'))
          .thenAnswer((_) async => ApiResponse(
                success: true,
                message: 'Başarılı',
                data: testAuthModel,
                timestamp: DateTime.now().toIso8601String(),
              ));
      return AuthBloc(mockAuthRepository);
    },
    act: (bloc) => bloc.add(const LoginSubmitted('test@example.com', 'Password123!')),
    expect: () => [
      AuthLoading(),
      AuthAuthenticated(testAuthModel),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'başarısız giriş yapıldığında → AuthLoading ve ardından AuthError durumları yayımlanır',
    build: () {
      when(() => mockAuthRepository.login('test@example.com', 'wrong_pass'))
          .thenAnswer((_) async => ApiResponse(
                success: false,
                message: 'Geçersiz e-posta veya şifre',
                timestamp: DateTime.now().toIso8601String(),
              ));
      return AuthBloc(mockAuthRepository);
    },
    act: (bloc) => bloc.add(const LoginSubmitted('test@example.com', 'wrong_pass')),
    expect: () => [
      AuthLoading(),
      const AuthError('Geçersiz e-posta veya şifre'),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'çıkış: repository.logout çağrılır, sonra AuthUnauthenticated yayımlanır',
    setUp: () {
      when(() => mockAuthRepository.logout(syncPending: any(named: 'syncPending')))
          .thenAnswer((_) async {});
    },
    build: () => AuthBloc(mockAuthRepository),
    act: (bloc) => bloc.add(const LogoutRequested()),
    expect: () => [
      AuthUnauthenticated(),
    ],
    verify: (_) {
      verify(() => mockAuthRepository.logout(syncPending: true)).called(1);
    },
  );

  test('çıkış: temizlik bitmeden AuthUnauthenticated yayımlanmaz', () async {
    final completer = Completer<void>();
    when(() => mockAuthRepository.logout(syncPending: any(named: 'syncPending')))
        .thenAnswer((_) => completer.future);

    final bloc = AuthBloc(mockAuthRepository);
    final states = <AuthState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const LogoutRequested());
    await Future<void>.delayed(Duration.zero);

    expect(states, isEmpty);

    completer.complete();
    await Future<void>.delayed(Duration.zero);

    expect(states, [isA<AuthUnauthenticated>()]);

    await sub.cancel();
    await bloc.close();
  });

  blocTest<AuthBloc, AuthState>(
    'oturum düşünce çıkış kuyruğu göndermeden yapılır',
    setUp: () {
      when(() => mockAuthRepository.logout(syncPending: any(named: 'syncPending')))
          .thenAnswer((_) async {});
    },
    build: () => AuthBloc(mockAuthRepository),
    act: (bloc) => bloc.add(const LogoutRequested(syncPending: false)),
    expect: () => [
      AuthUnauthenticated(),
    ],
    verify: (_) {
      verify(() => mockAuthRepository.logout(syncPending: false)).called(1);
    },
  );

  test('giriş başarılıysa bekleyen kayıtlar kullanıcı belli olduktan sonra gönderilir', () async {
    when(() => mockAuthRepository.login('test@example.com', 'Password123!'))
        .thenAnswer((_) async => ApiResponse(
              success: true,
              message: 'Giriş başarılı',
              timestamp: DateTime.now().toIso8601String(),
              data: testAuthModel,
            ));

    final bloc = AuthBloc(mockAuthRepository);
    AuthState? stateAtSync;
    when(() => mockAuthRepository.syncPending()).thenAnswer((_) async {
      stateAtSync = bloc.state;
    });

    bloc.add(const LoginSubmitted('test@example.com', 'Password123!'));
    await Future<void>.delayed(Duration.zero);

    expect(stateAtSync, isA<AuthAuthenticated>());
    verify(() => mockAuthRepository.syncPending()).called(1);
    await bloc.close();
  });

  blocTest<AuthBloc, AuthState>(
    'giriş başarısızsa bekleyen kayıtlar gönderilmez',
    setUp: () {
      when(() => mockAuthRepository.login('test@example.com', 'wrong_pass'))
          .thenAnswer((_) async => ApiResponse(
                success: false,
                message: 'Geçersiz e-posta veya şifre',
                timestamp: DateTime.now().toIso8601String(),
              ));
    },
    build: () => AuthBloc(mockAuthRepository),
    act: (bloc) => bloc.add(const LoginSubmitted('test@example.com', 'wrong_pass')),
    expect: () => [
      AuthLoading(),
      const AuthError('Geçersiz e-posta veya şifre'),
    ],
    verify: (_) {
      verifyNever(() => mockAuthRepository.syncPending());
    },
  );

  blocTest<AuthBloc, AuthState>(
    'açılışta oturum geri gelirse bekleyen kayıtlar gönderilir',
    setUp: () {
      when(() => mockAuthRepository.restoreSession())
          .thenAnswer((_) async => ApiResponse(
                success: true,
                message: 'Oturum geri yüklendi',
                timestamp: DateTime.now().toIso8601String(),
                data: testAuthModel,
              ));
    },
    build: () => AuthBloc(mockAuthRepository),
    act: (bloc) => bloc.add(AppStarted()),
    expect: () => [
      AuthAuthenticated(testAuthModel),
    ],
    verify: (_) {
      verify(() => mockAuthRepository.syncPending()).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'OTP doğrulanınca bekleyen kayıtlar gönderilir',
    build: () => AuthBloc(mockAuthRepository),
    act: (bloc) => bloc.add(AuthVerified(testAuthModel)),
    expect: () => [
      AuthAuthenticated(testAuthModel),
    ],
    verify: (_) {
      verify(() => mockAuthRepository.syncPending()).called(1);
    },
  );
}
