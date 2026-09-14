import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/util/app_logger.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/navigation/last_route_store.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/client_gallery_bloc.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_source.dart';
import 'package:gymapp_v2/features/auth/presentation/pages/splash_page.dart';
import 'package:gymapp_v2/features/auth/presentation/pages/login_page.dart';
import 'package:gymapp_v2/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:gymapp_v2/features/auth/presentation/pages/register_form_page.dart';
import 'package:gymapp_v2/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:gymapp_v2/features/membership/presentation/pages/onboarding_page.dart';
import 'package:gymapp_v2/features/membership/presentation/pages/intro_page.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/registration_flow/registration_flow_cubit.dart';
import 'package:gymapp_v2/features/dashboard/presentation/pages/main_wrapper.dart';
import 'package:gymapp_v2/features/social/presentation/pages/discovery_page.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/discovery/discovery_cubit.dart';
import 'package:gymapp_v2/features/social/presentation/pages/chat_detail_page.dart';
import 'package:gymapp_v2/features/social/presentation/pages/coach_profile_detail_page.dart';
import 'package:gymapp_v2/features/social/data/models/conversation_model.dart';
import 'package:gymapp_v2/features/training/ui/pages/training_dashboard_page.dart';
import 'package:gymapp_v2/features/training/ui/pages/create_personal_program_page.dart'
    as gymapp_create;
import 'package:gymapp_v2/features/training/models/training_models.dart';
import 'package:gymapp_v2/features/training/ui/pages/exercise_selection_page.dart';
import 'package:gymapp_v2/features/training/ui/pages/workout_overview_page.dart';
import 'package:gymapp_v2/features/training/ui/pages/active_workout_page.dart';
import 'package:gymapp_v2/features/training/ui/pages/workout_summary_page.dart';
import 'package:gymapp_v2/features/training/ui/pages/workout_history_page.dart';
import 'package:gymapp_v2/features/training/ui/pages/exercise_progress_page.dart';
import 'package:gymapp_v2/features/training/models/completed_set_data.dart';
import 'package:gymapp_v2/features/measurement/ui/pages/measurements_page.dart';
import 'package:gymapp_v2/features/measurement/ui/pages/progress_charts_page.dart';
import 'package:gymapp_v2/features/measurement/ui/pages/shared_measurements_page.dart';
import 'package:gymapp_v2/features/measurement/models/client_measurements_summary.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/diet_dashboard_page.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/diet_entry_page.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/diet_hub_page.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/diet_program_selection_page.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/food_search_page.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/add_custom_food_page.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/add_food/add_custom_food_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/food_details_page.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/nutrition_camera_page.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/gemini_analysis_page.dart';
import 'package:gymapp_v2/features/nutrition/data/models/ocr_scan_response_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/water_consumption_page.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/nutrition_analytics_page.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/diet_goals_page.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/meal_template_editor_page.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/recipe_details_page.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';
import 'package:gymapp_v2/features/profile/presentation/pages/client_profile_detail_page.dart';
import 'package:gymapp_v2/features/profile/presentation/pages/change_password_page.dart';
import 'package:gymapp_v2/features/profile/presentation/pages/about_page.dart';
import 'package:gymapp_v2/features/profile/presentation/pages/client_gallery_page.dart';
import 'package:gymapp_v2/features/profile/data/models/client_profile_response_model.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/coach_diet_templates_page.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/coach_water_tracking_page.dart';
import 'package:gymapp_v2/features/social/presentation/pages/client_360_dashboard_page.dart';
import 'package:gymapp_v2/features/finance/models/finance_models.dart';
import 'package:gymapp_v2/features/finance/ui/pages/package_selection_page.dart';
import 'package:gymapp_v2/features/finance/ui/pages/checkout_page.dart';
import 'package:gymapp_v2/features/finance/ui/pages/client_finance_detail_page.dart';
import 'package:gymapp_v2/features/finance/ui/pages/my_subscription_page.dart';
import 'package:gymapp_v2/features/finance/ui/pages/coach_packages_page.dart';
import 'package:gymapp_v2/features/finance/ui/pages/mock_payment_gateway_page.dart';
import 'package:gymapp_v2/features/finance/ui/pages/payment_result_pages.dart';
import 'package:gymapp_v2/features/training/ui/pages/workout_detail_page.dart';
import 'package:gymapp_v2/features/training/models/workout_session.dart';
import 'package:gymapp_v2/features/dashboard/presentation/bloc/navigation/navigation_cubit.dart';
import 'package:gymapp_v2/features/social/presentation/pages/coach_student_detail_page.dart';
import 'package:gymapp_v2/features/social/presentation/pages/coach_my_clients_page.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/measurement/measurement_bloc.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/measurement/measurement_event.dart';
import 'go_router_refresh_stream.dart';

final RouteObserver<PageRoute<dynamic>> routeObserver = RouteObserver<PageRoute<dynamic>>();

/// Bir sayfa kapatıldığında (pop/replace) klavye odağını serbest bırakır.
/// Donanım klavyesiyle (özellikle emülatör) odaklı bir TextField/InkWell varken sayfa
/// kapatılınca framework'ün "Looking up a deactivated widget's ancestor is unsafe"
/// hatasını üretmesini engeller.
class _FocusReleaseObserver extends NavigatorObserver {
  void _release() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _release();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _release();
}

/// Yönlendirme kararını saf bir fonksiyon olarak hesaplar (Unit ve Widget testleri için izole edilebilir).
String? resolveRedirect({
  required AuthState authState,
  required String matchedLocation,
  Object? extra,
  required bool introSeen,
  required String lastLocation,
  UserRole? pendingRole,
}) {
  // Cold start: oturum sessizce geri yüklenirken (AuthInitial) splash'te bekle.
  if (authState is AuthInitial) {
    return matchedLocation == '/splash' ? null : '/splash';
  }

  // Auth durumu çözüldü: artık splash'te kalınmaz, hedefe yönlendir.
  if (matchedLocation == '/splash') {
    if (authState is AuthAuthenticated) {
      return lastLocation;
    }
    if (!introSeen) {
      return '/intro';
    }
    return '/login';
  }

  final bool isAuthFlowUnauthenticatedAllowed = matchedLocation == '/intro' ||
      matchedLocation == '/login' ||
      matchedLocation == '/register' ||
      matchedLocation.startsWith('/register/') ||
      matchedLocation == '/onboarding' ||
      matchedLocation == '/verify-otp' ||
      matchedLocation == '/forgot-password';

  final bool isLoginOrRegisterPage = matchedLocation == '/login' ||
      matchedLocation == '/register' ||
      matchedLocation.startsWith('/register/');

  // 1. Kullanıcı oturum açmamışsa ve korumalı bir sayfadaysa -> /login
  if (authState is AuthUnauthenticated) {
    // Kayıt devam etmiyorken onboarding, OTP veya kayıt formuna girmeye çalışırsa kayıt seçimine at
    if (matchedLocation == '/onboarding' ||
        matchedLocation == '/verify-otp' ||
        matchedLocation == '/register/form') {
      if (pendingRole == null && extra == null) {
        return '/register';
      }
    }
    return isAuthFlowUnauthenticatedAllowed ? null : '/login';
  }

  // 2. Kullanıcı oturum açmışsa ve giriş/kayıt sayfalarındaysa -> /main
  if (authState is AuthAuthenticated) {
    if (isLoginOrRegisterPage) return '/main';
  }

  return null;
}

final NavigatorObserver focusReleaseObserver = _FocusReleaseObserver();

/// GYMAPP-V2 Merkezi Rota Konfigürasyonu.
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  refreshListenable: GoRouterRefreshStream(sl<AuthBloc>().stream),
  redirect: (context, state) {
    return resolveRedirect(
      authState: sl<AuthBloc>().state,
      matchedLocation: state.matchedLocation,
      extra: state.extra,
      introSeen: sl<LastRouteStore>().readIntroSeen(),
      lastLocation: sl<LastRouteStore>().readLocation(),
      pendingRole: sl<RegistrationFlowCubit>().state.role,
    );
  },
  observers: [
    if (GetIt.instance.isRegistered<AppLogger>() &&
        GetIt.instance<AppLogger>().getNavigatorObserver()
            is NavigatorObserver)
      GetIt.instance<AppLogger>().getNavigatorObserver() as NavigatorObserver,
    routeObserver,
    focusReleaseObserver,
  ],
  errorBuilder: (context, state) => Scaffold(
    backgroundColor: AppColors.background,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SelectableText(
              state.error?.toString() ?? 'Bilinmeyen hata',
              style: const TextStyle(color: AppColors.error, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/main'),
              child: const Text('ANA SAYFAYA DÖN'),
            ),
          ],
        ),
      ),
    ),
  ),
  routes: [
    // --- AUTH ---
    GoRoute(
      path: '/intro',
      name: 'intro',
      builder: (context, state) => const IntroPage(),
    ),
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const IntroPage(),
    ),
    GoRoute(
      path: '/register/form',
      name: 'register-form',
      builder: (context, state) {
        final role = (state.extra is UserRole)
            ? (state.extra as UserRole)
            : (sl<RegistrationFlowCubit>().state.role ?? UserRole.CLIENT);
        return RegisterFormPage(role: role);
      },
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) {
        final registrationState = sl<RegistrationFlowCubit>().state;
        return OnboardingPage(
          email: registrationState.email ?? '',
          password: registrationState.password ?? '',
          phoneNumber: registrationState.phoneNumber ?? '',
          role: registrationState.role ?? UserRole.CLIENT,
        );
      },
    ),
    GoRoute(
      path: '/verify-otp',
      name: 'verify-otp',
      builder: (context, state) {
        final registrationState = sl<RegistrationFlowCubit>().state;
        return OtpVerificationPage(
          email: registrationState.email ?? '',
          onVerified: (innerContext) {
            sl<RegistrationFlowCubit>().clear();
            innerContext.go('/main');
          },
        );
      },
    ),

    // --- MAIN HUB ---
    GoRoute(
      path: '/main',
      name: 'main',
      builder: (context, state) {
        final authState = sl<AuthBloc>().state;
        final extra = state.extra as Map<String, dynamic>?;

        final UserRole finalRole = authState is AuthAuthenticated
            ? authState.auth.role
            : (extra?['role'] is UserRole
                ? extra!['role'] as UserRole
                : UserRole.fromString(extra?['role'] as String?));

        final int finalUserId = authState is AuthAuthenticated
            ? authState.auth.id
            : (extra?['userId'] as int? ?? 0);

        return MainWrapper(
          role: finalRole,
          userId: finalUserId,
          accessToken: extra?['accessToken'] as String?,
          navigationCubit: sl<NavigationCubit>(),
        );
      },
    ),

    // --- SOSYAL ---
    GoRoute(
      path: '/discovery',
      name: 'discovery',
      builder: (context, state) => BlocProvider<DiscoveryCubit>(
        create: (context) => sl<DiscoveryCubit>(),
        child: DiscoveryPage(currentUserId: state.extra as int),
      ),
    ),

    GoRoute(
      path: '/coach-diet-templates',
      name: 'coach-diet-templates',
      builder: (context, state) => const CoachDietTemplatesPage(),
    ),
    GoRoute(
      path: '/coach-profile/:coachId',
      name: 'coach-profile',
      builder: (context, state) {
        final coachId = int.parse(state.pathParameters['coachId']!);
        final coachName = state.uri.queryParameters['name'] ?? 'Antrenör';
        return CoachProfileDetailPage(
          coachId: coachId,
          coachName: coachName,
        );
      },
    ),
    GoRoute(
      path: '/chat',
      name: 'chat',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return ChatDetailPage(
          conversation: data['conversation'] as ConversationModel,
          currentUserId: data['currentUserId'] as int,
          stagedPackage: data['stagedPackage'] as SubscriptionPackageModel?,
        );
      },
    ),

    GoRoute(
      path: '/coach/my-clients',
      name: 'coach-my-clients',
      builder: (context, state) {
        final userId = state.extra as int?;
        return CoachMyClientsPage(
          userId: userId,
        );
      },
    ),

    GoRoute(
      path: '/coach/student-detail/:id',
      name: 'coach-student-detail',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        final data = state.extra as Map<String, dynamic>?;
        final studentName = data?['studentName'] as String? ?? 'Öğrenci';
        final summary = data?['measurementSummary'] as ClientMeasurementsSummary?;
        return CoachStudentDetailPage(
          studentId: id,
          studentName: studentName,
          measurementSummary: summary,
        );
      },
    ),

    // --- ANTRENMAN VE KÜTÜPHANE ---
    GoRoute(
      path: '/training',
      name: 'training',
      builder: (context, state) {
        int? targetStudentId;
        final extra = state.extra;
        if (extra is Map<String, dynamic>) {
          targetStudentId = extra['targetStudentId'] as int?;
        }
        return TrainingDashboardPage(targetStudentId: targetStudentId);
      },
    ),
    GoRoute(
      path: '/workout-overview',
      name: 'workout-overview',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return WorkoutOverviewPage(
          program: extra['program'] as TrainingBlock,
          workoutDay: extra['day'] as WorkoutDay,
        );
      },
    ),
    GoRoute(
      path: '/active-workout',
      name: 'active-workout',
      builder: (context, state) {
        if (state.extra is Map<String, dynamic>) {
          final extra = state.extra as Map<String, dynamic>;
          return ActiveWorkoutPage(
            workoutDay: extra['day'] as WorkoutDay,
            trainingBlockId: extra['trainingBlockId'] as int?,
            restSeconds: (extra['restSeconds'] as int?) ?? 90,
          );
        }
        return ActiveWorkoutPage(workoutDay: state.extra as WorkoutDay);
      },
    ),
    GoRoute(
      path: '/workout-summary',
      name: 'workout-summary',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return WorkoutSummaryPage(
          completedSets: data['completedSets'] as List<CompletedSetData>,
          isOfflineSaved: data['isOfflineSaved'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      path: '/create-personal-program',
      name: 'create-personal-program',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is TrainingBlock) {
          final authState = context.read<AuthBloc>().state;
          final isClient = authState is AuthAuthenticated && authState.auth.role == UserRole.CLIENT;
          final isReadOnly = isClient && extra.coachId != null;
          return gymapp_create.CreatePersonalProgramPage(
            initialBlock: extra,
            isReadOnly: isReadOnly,
          );
        } else if (extra is Map<String, dynamic>) {
          final program = extra['program'] as TrainingBlock?;
          final isReadOnly = extra['isReadOnly'] as bool? ?? false;
          final isTemplateMode = extra['isTemplateMode'] as bool? ?? false;
          return gymapp_create.CreatePersonalProgramPage(
            initialBlock: program,
            isReadOnly: isReadOnly,
            isTemplateMode: isTemplateMode,
          );
        } else if (extra is String && extra == 'template') {
          return const gymapp_create.CreatePersonalProgramPage(
            isTemplateMode: true,
          );
        }
        return const gymapp_create.CreatePersonalProgramPage();
      },
    ),
    GoRoute(
      path: '/nutrition/templates/editor',
      name: 'meal-template-editor',
      builder: (context, state) {
        final template = state.extra as MealTemplateModel?;
        return MealTemplateEditorPage(template: template);
      },
    ),
    GoRoute(
      path: '/exercises',
      name: 'exercises',
      builder:
          (context, state) =>
              const ExerciseSelectionPage(isSelectionMode: false),
    ),

    // --- ÖLÇÜM VE ANALİZ (BAĞIMSIZ ROTALAR) ---
    GoRoute(
      path: '/workout-history',
      name: 'workout-history',
      builder: (context, state) {
        final clientId = state.extra as int?;
        return WorkoutHistoryPage(targetClientId: clientId);
      },
    ),
    GoRoute(
      path: '/workout-detail',
      name: 'workout-detail',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is WorkoutSession) {
          return WorkoutDetailPage(session: extra);
        } else if (extra is Map<String, dynamic>) {
          if (extra['session'] is WorkoutSession) {
            return WorkoutDetailPage(
              session: extra['session'] as WorkoutSession,
              clientId: extra['clientId'] as int?,
            );
          }
          return WorkoutDetailPage(session: WorkoutSession.fromJson(extra));
        }
        throw Exception('WorkoutDetailPage için geçersiz session parametresi');
      },
    ),
    GoRoute(
      path: '/exercise-progress',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return ExerciseProgressPage(
          exerciseId: data['exerciseId'] as int,
          exerciseName: data['exerciseName'] as String,
          clientId: data['clientId'] as int?,
        );
      },
    ),
    GoRoute(
      path: '/shared-measurements',
      name: 'shared-measurements',
      builder: (context, state) => const SharedMeasurementsPage(),
    ),
    GoRoute(
      path: '/measurements',
      name: 'measurements',
      builder: (context, state) {
        final clientId = state.extra as int?;
        return BlocProvider<MeasurementBloc>(
          create: (context) => sl<MeasurementBloc>()..add(LoadMeasurements(clientId: clientId)),
          child: MeasurementsPage(targetClientId: clientId),
        );
      },
    ),
    GoRoute(
      path: '/progress-charts',
      name: 'progress-charts',
      builder: (context, state) {
        final clientId = state.extra as int?;
        return BlocProvider<MeasurementBloc>(
          create: (context) => sl<MeasurementBloc>()..add(LoadMeasurements(clientId: clientId)),
          child: ProgressChartsPage(targetClientId: clientId),
        );
      },
    ),

    // --- NUTRITION ---
    GoRoute(
      path: '/nutrition',
      name: 'nutrition',
      builder: (context, state) => const DietHubPage(),
    ),
    GoRoute(
      path: '/nutrition/entry',
      name: 'diet-entry',
      builder: (context, state) => const DietEntryPage(),
    ),
    GoRoute(
      path: '/nutrition/list/:source',
      name: 'nutrition-list',
      builder: (context, state) {
        final source = state.pathParameters['source'];
        return DietProgramSelectionPage(sourceFilter: DietSource.fromString(source));
      },
    ),
    GoRoute(
      path: '/nutrition/dashboard/:id',
      name: 'nutrition-dashboard',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return DietDashboardPage(programId: id);
      },
    ),
    GoRoute(
      path: '/nutrition/search',
      name: 'nutrition-search',
      builder: (context, state) {
        int? mealId;
        MealType? mealType;
        bool isTemplateMode = false;

        // 1. Önce EXTRA nesnesini kontrol et (En güvenilir kaynak)
        final extra = state.extra;
        if (extra is int) {
          mealId = extra;
        } else if (extra is Map<String, dynamic>) {
          mealId = extra['mealId'] as int?;
          isTemplateMode = extra['isTemplateMode'] as bool? ?? false;

          final rawMealType = extra['mealType'];
          if (rawMealType is MealType) {
            mealType = rawMealType;
          } else if (rawMealType is String) {
            mealType = MealTypeExtension.fromString(rawMealType);
          }
        }

        // 2. Query parametreleri (Fallback/Yedek kaynak)
        if (state.uri.queryParameters['mealId'] != null) {
          mealId = int.tryParse(state.uri.queryParameters['mealId']!);
        }
        if (state.uri.queryParameters['mealType'] != null) {
          mealType = MealTypeExtension.fromString(state.uri.queryParameters['mealType']!);
        }
        if (state.uri.queryParameters['isTemplateMode'] == 'true') {
          isTemplateMode = true;
        }

        return FoodSearchPage(
          mealId: mealId,
          mealType: mealType,
          isTemplateMode: isTemplateMode,
        );
      },
    ),
    GoRoute(
      path: '/nutrition/add-food',
      name: 'nutrition-add-food',
      builder: (context, state) {
        final prefill = state.extra as String?;
        return BlocProvider(
          create: (_) => sl<AddCustomFoodCubit>(),
          child: AddCustomFoodPage(prefillName: prefill),
        );
      },
    ),
    GoRoute(
      path: '/nutrition/scan',
      name: 'nutrition-scan',
      builder: (context, state) {
        bool returnToBasket = false;
        final extra = state.extra;
        if (extra is Map<String, dynamic>) {
          returnToBasket = extra['returnToBasket'] as bool? ?? false;
        }
        return NutritionCameraPage(returnToBasket: returnToBasket);
      },
    ),
    GoRoute(
      path: '/nutrition/gemini-analysis',
      name: 'gemini-analysis',
      builder: (context, state) {
        OcrScanResponseModel? responseData;
        int? programId;

        if (state.extra is OcrScanResponseModel) {
          responseData = state.extra as OcrScanResponseModel;
        } else if (state.extra is Map<String, dynamic>) {
          final extra = state.extra as Map<String, dynamic>;
          responseData = extra['responseData'] as OcrScanResponseModel?;
          programId = extra['programId'] as int?;
        }

        return GeminiAnalysisPage(responseData: responseData, programId: programId);
      },
    ),
    GoRoute(
      path: '/nutrition/food-details/:id',
      name: 'food-details',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        final barcode = state.uri.queryParameters['barcode'];
        final isReadOnly = state.uri.queryParameters['readOnly'] == 'true';
        final ignoreOverride = state.uri.queryParameters['ignoreOverride'] == 'true';
        final extraFood = state.extra as FoodModel?;

        return FoodDetailsPage(
          foodId: id,
          barcode: barcode,
          isReadOnly: isReadOnly,
          ignoreOverride: ignoreOverride,
          extraFood: extraFood,
        );
      },
    ),
    GoRoute(
      path: '/nutrition/recipe-details/:id',
      name: 'recipe-details',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);

        bool isReadOnly = false;

        if (state.extra is bool) {
          isReadOnly = state.extra as bool;
        } else if (state.extra is Map<String, dynamic>) {
          final data = state.extra as Map<String, dynamic>;
          isReadOnly = data['isReadOnly'] as bool? ?? false;
        }

        return RecipeDetailsPage(
          recipeId: id,
          isReadOnly: isReadOnly,
        );
      },
    ),
    GoRoute(
      path: '/water-tracking',
      name: 'water-tracking',
      builder: (context, state) => const WaterConsumptionPage(),
    ),
    GoRoute(
      path: '/coach-water-tracking',
      name: 'coach-water-tracking',
      builder: (context, state) => const CoachWaterTrackingPage(),
    ),
    GoRoute(
      path: '/nutrition/analytics',
      name: 'nutrition-analytics',
      builder: (context, state) {
        int? programId;
        int? targetUserId;
        final extra = state.extra;
        if (extra is int) {
          programId = extra;
        } else if (extra is Map<String, dynamic>) {
          programId = extra['programId'] as int?;
          targetUserId = extra['targetUserId'] as int?;
        }
        if (state.uri.queryParameters['programId'] != null) {
          programId = int.tryParse(state.uri.queryParameters['programId']!);
        }
        if (state.uri.queryParameters['targetUserId'] != null) {
          targetUserId = int.tryParse(state.uri.queryParameters['targetUserId']!);
        }
        return NutritionAnalyticsPage(programId: programId, targetUserId: targetUserId);
      },
    ),
    GoRoute(
      path: '/nutrition/diet-goals',
      name: 'diet-goals',
      builder: (context, state) {
        final program = state.extra as DietProgramModel;
        return DietGoalsPage(program: program);
      },
    ),
    GoRoute(
      path: '/profile/detail',
      name: 'client-profile-detail',
      builder: (context, state) {
        final extra = state.extra;
        final ClientProfileResponseModel profileData;
        final bool readOnly;
        if (extra is Map) {
          profileData = extra['profileData'] as ClientProfileResponseModel;
          readOnly = extra['readOnly'] as bool? ?? false;
        } else {
          profileData = extra as ClientProfileResponseModel;
          readOnly = false;
        }
        return ClientProfileDetailPage(
          profileData: profileData,
          readOnly: readOnly,
        );
      },
    ),
    GoRoute(
      path: '/profile/change-password',
      name: 'change-password',
      builder: (context, state) => const ChangePasswordPage(),
    ),
    GoRoute(
      path: '/profile/about',
      name: 'about',
      builder: (context, state) => const AboutPage(),
    ),
    GoRoute(
      path: '/profile/gallery',
      name: 'client-gallery',
      builder: (context, state) => BlocProvider(
        create: (context) => sl<ClientGalleryBloc>(),
        child: const ClientGalleryPage(),
      ),
    ),
    GoRoute(
      path: '/client-360/:id',
      name: 'client-360',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        final data = state.extra as Map<String, dynamic>?;
        final studentName = data?['studentName'] as String? ?? 'Danışan';
        final summary = data?['measurementSummary'] as ClientMeasurementsSummary?;
        return Client360DashboardPage(
          studentId: id,
          studentName: studentName,
          measurementSummary: summary,
        );
      },
    ),
    GoRoute(
      path: '/packages/:coachId',
      name: 'packages',
      builder: (context, state) {
        final coachId = int.parse(state.pathParameters['coachId']!);
        return PackageSelectionPage(coachId: coachId);
      },
    ),
    GoRoute(
      path: '/checkout',
      name: 'checkout',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final package = extra['package'] as SubscriptionPackageModel;
        final transactionId = extra['transactionId'] as int;
        return CheckoutPage(package: package, transactionId: transactionId);
      },
    ),
    GoRoute(
      path: '/checkout/gateway',
      name: 'checkout-gateway',
      builder: (context, state) {
        final sessionId = state.uri.queryParameters['session_id'] ?? '';
        return MockPaymentGatewayPage(sessionId: sessionId);
      },
    ),
    GoRoute(
      path: '/checkout/success',
      name: 'checkout-success',
      builder: (context, state) => const PaymentSuccessPage(),
    ),
    GoRoute(
      path: '/checkout/failure',
      name: 'checkout-failure',
      builder: (context, state) => const PaymentFailurePage(),
    ),
    GoRoute(
      path: '/my-subscription',
      name: 'my-subscription',
      builder: (context, state) => const MySubscriptionPage(),
    ),
    GoRoute(
      path: '/coach/packages',
      name: 'coach-packages',
      builder: (context, state) => const CoachPackagesPage(),
    ),
    GoRoute(
      path: '/coach/student-finance/:clientId',
      name: 'student-finance',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['clientId']!);
        final data = state.extra as Map<String, dynamic>?;
        final studentName = data?['studentName'] as String? ?? 'Danışan';
        return ClientFinanceDetailPage(clientId: id, clientName: studentName);
      },
    ),
  ],
);
