import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/navigation/last_route_store.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/registration_flow/registration_flow_cubit.dart';
import 'package:gymapp_v2/features/membership/presentation/bloc/intro/intro_cubit.dart';
import 'package:gymapp_v2/features/membership/presentation/pages/intro_page.dart';
import 'package:mocktail/mocktail.dart';

class MockLastRouteStore extends Mock implements LastRouteStore {}

/// Uygulamayı silip yeniden kuran kullanıcının giriş ekranına ulaşabilmesi.
///
/// Cihazda "intro görüldü" kaydı olmadığı için yönlendirici bu kullanıcıyı soru
/// akışına düşürüyor. Hesabı sunucuda duruyor ama bu bağlantı olmadan giriş ekranına
/// ulaşmasının **hiçbir yolu yok** — anketi baştan doldurmak zorunda kalıyor.
void main() {
  late MockLastRouteStore lastRouteStore;

  setUp(() {
    lastRouteStore = MockLastRouteStore();
    when(() => lastRouteStore.markIntroSeen()).thenReturn(null);

    if (sl.isRegistered<LastRouteStore>()) sl.unregister<LastRouteStore>();
    if (sl.isRegistered<IntroCubit>()) sl.unregister<IntroCubit>();

    sl.registerSingleton<LastRouteStore>(lastRouteStore);
    sl.registerFactory<IntroCubit>(() => IntroCubit(RegistrationFlowCubit()));
  });

  tearDown(() {
    if (sl.isRegistered<LastRouteStore>()) sl.unregister<LastRouteStore>();
    if (sl.isRegistered<IntroCubit>()) sl.unregister<IntroCubit>();
  });

  Future<GoRouter> pumpIntro(WidgetTester tester) async {
    final GoRouter router = GoRouter(
      initialLocation: '/intro',
      routes: [
        GoRoute(path: '/intro', builder: (_, __) => const IntroPage()),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('GIRIS EKRANI')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(const Duration(milliseconds: 400));
    return router;
  }

  testWidgets('ilk adımda giriş bağlantısı görünür', (tester) async {
    await pumpIntro(tester);

    expect(find.text('Zaten hesabın var mı?'), findsOneWidget);
    expect(find.text('Giriş yap'), findsOneWidget);
  });

  testWidgets('bağlantı giriş ekranına götürür', (tester) async {
    await pumpIntro(tester);

    await tester.tap(find.text('Giriş yap'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('GIRIS EKRANI'), findsOneWidget);
  });

  testWidgets('giriş seçildiğinde intro görülmüş sayılır', (tester) async {
    // İşaretlenmezse kullanıcı çıkış yapıp uygulamayı tekrar açtığında yine soru
    // akışına düşer.
    await pumpIntro(tester);

    await tester.tap(find.text('Giriş yap'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    verify(() => lastRouteStore.markIntroSeen()).called(1);
  });
}
