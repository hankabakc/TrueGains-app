import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/network/offline_cache.dart';
import 'package:gymapp_v2/core/util/app_bloc_observer.dart';
import 'package:gymapp_v2/core/util/app_logger.dart';
import 'package:gymapp_v2/core/theme/app_theme.dart';
import 'package:gymapp_v2/core/navigation/app_router.dart';
import 'package:gymapp_v2/core/navigation/last_route_store.dart';

// BLOC IMPORTS
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/chat_bloc.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/social_bloc.dart';
import 'package:gymapp_v2/features/training/bloc/training_bloc.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/active_workout/active_workout_bloc.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/water/water_bloc.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_entry/diet_entry_bloc.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_entry/diet_entry_event.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gymapp_v2/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:gymapp_v2/features/training/bloc/weekly_progress_cubit.dart';

/// Arka plan bildirim dinleyicisi
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Uçtan uca (integration_test) koşularında hata raporlayıcıyı atlamak için bayrak.
///
/// Yalnızca test komutunda verilir:
///   flutter test integration_test/... --dart-define=SKIP_CRASH_REPORTING=true
///
/// Normal `flutter build`/`flutter run` komutlarında tanımsızdır, varsayılanı `false`
/// olduğu için üretim davranışı değişmez.
const bool kSkipCrashReporting =
    bool.fromEnvironment('SKIP_CRASH_REPORTING', defaultValue: false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dokunmatik öncelikli mobil uygulamada klavye odak-vurgusu gereksizdir. Otomatik
  // (dokunmatik↔klavye) mod değişimini kapatıyoruz: donanım klavyesiyle (özellikle
  // emülatör) bir tuşa basıldığında, odak-vurgu yöneticisi deaktive olmuş InkWell'lerde
  // MediaQuery araması yapıp "Looking up a deactivated widget's ancestor is unsafe"
  // hatasını üretiyordu. alwaysTouch bu döngüyü tamamen engeller.
  FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;

  await initDependencies();

  Future<void> bootstrap() async {
    Bloc.observer = AppBlocObserver();
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await Hive.initFlutter();
    await Hive.openBox<String>('sync_queue');
    await openOfflineCacheBox(sl<FlutterSecureStorage>());
    sl<LastRouteStore>().attach(appRouter);
    // Açılışta oturumu sessizce geri yüklemeyi tetikle ("oturumda kal").
    // Deterministik tek tetikleme: splash AuthBloc'u okumadığından provider
    // içindeki lazy `..add` yerine burada dispatch edilir.
    sl<AuthBloc>().add(AppStarted());
    runApp(const MyApp());
  }

  if (kSkipCrashReporting) {
    // Uçtan uca testlerde hata raporlayıcı devre dışı bırakılır. Sebebi: raporlayıcı
    // `FlutterError.onError`'ı global olarak devralıp geri bırakmıyor; `integration_test`
    // bunu "test bu kancayı devraldı ve geri vermedi" diye reddedip her testi düşürüyor.
    //
    // Bu bayrak SADECE test komutunda verilir (--dart-define). Normal derlemede
    // tanımsızdır ve varsayılanı false olduğu için hata raporlama aynen çalışır.
    await bootstrap();
    return;
  }

  await sl<AppLogger>().init(appRunner: bootstrap);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<AuthBloc>()),
        BlocProvider(create: (context) => sl<TrainingBloc>()),
        BlocProvider(create: (context) => sl<ChatBloc>()),
        BlocProvider(create: (context) => sl<SocialBloc>()),
        BlocProvider(
          create: (context) => sl<ActiveWorkoutBloc>()..add(const RestoreWorkout()),
        ),
        BlocProvider(
          create: (context) => sl<WaterBloc>()..add(const LoadWaterSummary()),
        ),
        BlocProvider(create: (context) => sl<ProfileBloc>()),
        BlocProvider(create: (context) => sl<FinanceBloc>()),
        BlocProvider(create: (context) => sl<WeeklyProgressCubit>()..loadMyProgress()),
        BlocProvider(create: (context) => sl<DietEntryBloc>()..add(const InitializeDietEntry())),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('tr', 'TR')],
        theme: AppTheme.darkTheme,
      ),
    );
  }
}
