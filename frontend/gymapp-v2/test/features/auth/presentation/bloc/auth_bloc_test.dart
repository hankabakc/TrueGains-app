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
    'çıkış yapma isteği gönderildiğinde → AuthUnauthenticated durumu yayımlanır',
    build: () => AuthBloc(mockAuthRepository),
    act: (bloc) => bloc.add(LogoutRequested()),
    expect: () => [
      AuthUnauthenticated(),
    ],
  );
}
