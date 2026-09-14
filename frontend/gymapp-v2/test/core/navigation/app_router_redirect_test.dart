import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/navigation/app_router.dart';
import 'package:gymapp_v2/features/auth/data/models/auth_model.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';

void main() {
  final testAuthModel = AuthModel(
    user: UserModel(
      id: 1,
      email: 'test@example.com',
      role: UserRole.CLIENT,
    ),
    accessToken: 'test_token',
    tokenType: 'Bearer',
    expiresIn: 3600,
  );

  group('resolveRedirect Rota Karar Ağacı Birim Testleri', () {
    test('1. AuthInitial ve /splash konumundayken splash ekranında kalır (null döner)', () {
      final redirect = resolveRedirect(
        authState: AuthInitial(),
        matchedLocation: '/splash',
        introSeen: false,
        lastLocation: '/main',
      );
      expect(redirect, isNull);
    });

    test('2. AuthInitial ve /main konumundayken /splash ekranına yönlendirir', () {
      final redirect = resolveRedirect(
        authState: AuthInitial(),
        matchedLocation: '/main',
        introSeen: false,
        lastLocation: '/main',
      );
      expect(redirect, equals('/splash'));
    });

    test('3. AuthAuthenticated ve /splash konumundayken son kaydedilen konuma (/main) yönlendirir', () {
      final redirect = resolveRedirect(
        authState: AuthAuthenticated(testAuthModel),
        matchedLocation: '/splash',
        introSeen: true,
        lastLocation: '/main',
      );
      expect(redirect, equals('/main'));
    });

    test('4. AuthUnauthenticated, /splash ve intro görülmemişse (/intro) yönlendirir', () {
      final redirect = resolveRedirect(
        authState: AuthUnauthenticated(),
        matchedLocation: '/splash',
        introSeen: false,
        lastLocation: '/main',
      );
      expect(redirect, equals('/intro'));
    });

    test('5. AuthUnauthenticated, /splash ve intro görülmüşse (/login) yönlendirir', () {
      final redirect = resolveRedirect(
        authState: AuthUnauthenticated(),
        matchedLocation: '/splash',
        introSeen: true,
        lastLocation: '/main',
      );
      expect(redirect, equals('/login'));
    });

    test('6. AuthUnauthenticated ve korumalı /main konumundayken /login sayfasına yönlendirir', () {
      final redirect = resolveRedirect(
        authState: AuthUnauthenticated(),
        matchedLocation: '/main',
        introSeen: true,
        lastLocation: '/main',
      );
      expect(redirect, equals('/login'));
    });

    test('7. AuthUnauthenticated ve /login konumundayken sayfaya erişime izin verir (null)', () {
      final redirect = resolveRedirect(
        authState: AuthUnauthenticated(),
        matchedLocation: '/login',
        introSeen: true,
        lastLocation: '/main',
      );
      expect(redirect, isNull);
    });

    test('8. AuthUnauthenticated, /onboarding konumundayken pendingRole ve extra yoksa /register sayfasına atar', () {
      final redirect = resolveRedirect(
        authState: AuthUnauthenticated(),
        matchedLocation: '/onboarding',
        introSeen: true,
        lastLocation: '/main',
        pendingRole: null,
        extra: null,
      );
      expect(redirect, equals('/register'));
    });

    test('9. AuthUnauthenticated, /onboarding konumundayken pendingRole seçilmişse izin verir (null)', () {
      final redirect = resolveRedirect(
        authState: AuthUnauthenticated(),
        matchedLocation: '/onboarding',
        introSeen: true,
        lastLocation: '/main',
        pendingRole: UserRole.CLIENT,
      );
      expect(redirect, isNull);
    });

    test('10. AuthUnauthenticated, /verify-otp konumundayken extra dolu ise izin verir (null)', () {
      final redirect = resolveRedirect(
        authState: AuthUnauthenticated(),
        matchedLocation: '/verify-otp',
        introSeen: true,
        lastLocation: '/main',
        pendingRole: null,
        extra: {'email': 'test@example.com'},
      );
      expect(redirect, isNull);
    });

    test('11. AuthAuthenticated iken /login sayfasına erişilirse /main sayfasına yönlendirir', () {
      final redirect = resolveRedirect(
        authState: AuthAuthenticated(testAuthModel),
        matchedLocation: '/login',
        introSeen: true,
        lastLocation: '/main',
      );
      expect(redirect, equals('/main'));
    });

    test('12. AuthAuthenticated iken korumalı /discovery sayfasına erişilirse erişime izin verir (null)', () {
      final redirect = resolveRedirect(
        authState: AuthAuthenticated(testAuthModel),
        matchedLocation: '/discovery',
        introSeen: true,
        lastLocation: '/main',
      );
      expect(redirect, isNull);
    });
  });
}
