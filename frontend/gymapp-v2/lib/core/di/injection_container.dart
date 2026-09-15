import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

// CORE / UTIL
import '../util/app_logger.dart';
import '../util/sentry_logger_impl.dart';
import '../util/notification_service.dart';
import '../network/network_info.dart';
import '../network/sync_manager.dart';
import '../network/offline_cache.dart';
import '../network/cache_status.dart';
import '../network/dio_client.dart';
import '../navigation/last_route_store.dart';
import '../../features/training/data/active_workout_store.dart';

// DATA LAYERS
import '../../features/auth/data/services/auth_api_service.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/training/data/services/training_api_service.dart';
import '../../features/training/repository/training_repository.dart';
import '../../features/social/data/services/social_api_service.dart';
import '../../features/social/data/services/chat_api_service.dart';
import '../../features/social/data/services/file_api_service.dart';
import '../../features/social/data/services/client_gallery_api_service.dart';
import '../../features/social/data/services/coach_student_progress_api_service.dart';
import 'package:gymapp_v2/features/social/data/services/coach_profile_api_service.dart';
import '../../features/social/data/repositories/social_repository.dart';
import '../../features/social/data/repositories/chat_repository.dart';
import '../../features/social/data/repositories/client_gallery_repository.dart';
import '../../features/social/data/repositories/coach_student_progress_repository.dart';
import '../../features/measurement/repository/measurement_repository.dart';
import '../../features/nutrition/data/repositories/nutrition_repository.dart';
import '../../features/nutrition/data/services/diet_api_service.dart';
import '../../features/nutrition/data/services/water_api_service.dart';
import '../../features/nutrition/data/services/food_api_service.dart';
import '../../features/nutrition/data/services/analytics_api_service.dart';
import '../../features/profile/data/repositories/profile_repository.dart';
import '../../features/finance/data/services/finance_api_service.dart';
import '../../features/finance/repository/finance_repository.dart';

// PRESENTATION LAYERS
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/training/bloc/training_bloc.dart';
import '../../features/social/presentation/bloc/chat_bloc.dart';
import '../../features/social/presentation/bloc/social_bloc.dart';
import '../../features/social/presentation/bloc/client_gallery_bloc.dart';
import '../../features/social/presentation/bloc/coach_student_progress_bloc.dart';
import '../../features/training/presentation/bloc/active_workout/active_workout_bloc.dart';
import '../../features/nutrition/presentation/bloc/water/water_bloc.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/client_profile_view/client_profile_view_cubit.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/coach_profile/coach_profile_bloc.dart';

import '../../features/training/presentation/bloc/create_program/create_personal_program_cubit.dart';
import '../../features/training/presentation/bloc/workout_history/workout_history_cubit.dart';
import '../../features/training/presentation/bloc/exercise_library/exercise_library_cubit.dart';
import '../../features/training/presentation/bloc/assigned_programs/assigned_programs_cubit.dart';
import '../../features/nutrition/presentation/bloc/diet_dashboard/diet_dashboard_cubit.dart';
import '../../features/nutrition/presentation/bloc/diet_goals/diet_goals_cubit.dart';
import '../../features/nutrition/presentation/bloc/diet_program_selection/diet_program_selection_cubit.dart';
import '../../features/nutrition/presentation/bloc/coach_diet_templates/coach_diet_templates_cubit.dart';
import '../../features/nutrition/presentation/bloc/coach_water_tracking/coach_water_tracking_cubit.dart';
import '../../features/nutrition/presentation/bloc/recipe_details/recipe_details_cubit.dart';
import '../../features/nutrition/presentation/bloc/food_details/food_details_cubit.dart';
import '../../features/nutrition/presentation/bloc/food_search/food_search_cubit.dart';
import '../../features/nutrition/presentation/bloc/add_food/add_custom_food_cubit.dart';
import '../../features/nutrition/presentation/bloc/meal_template_editor/meal_template_editor_cubit.dart';
import '../../features/nutrition/presentation/bloc/water_analysis/water_analysis_cubit.dart';
import '../../features/nutrition/presentation/bloc/food_picker/food_picker_cubit.dart';
import '../../features/nutrition/presentation/bloc/gemini_analysis/gemini_analysis_cubit.dart';
import '../../features/nutrition/presentation/bloc/barcode_scanner/barcode_scanner_cubit.dart';
import '../../features/nutrition/presentation/bloc/nutrition_camera/nutrition_camera_cubit.dart';
import '../../features/nutrition/presentation/bloc/save_recipe_modal/save_recipe_modal_cubit.dart';
import '../../features/social/presentation/bloc/discovery/discovery_cubit.dart';
import '../../features/membership/presentation/bloc/onboarding/onboarding_cubit.dart';
import '../../features/auth/presentation/bloc/register_form/register_form_cubit.dart';
import '../../features/auth/presentation/bloc/otp_verification/otp_cubit.dart';
import '../../features/auth/presentation/bloc/login_form/login_form_cubit.dart';
import '../../features/auth/presentation/bloc/forgot_password/forgot_password_cubit.dart';
import '../../features/auth/presentation/bloc/registration_flow/registration_flow_cubit.dart';
import '../../features/membership/presentation/bloc/intro/intro_cubit.dart';
import '../../features/finance/presentation/bloc/finance_bloc.dart';
import '../../features/training/bloc/weekly_progress_cubit.dart';
import '../../features/training/presentation/bloc/analytics/exercise_analytics_cubit.dart';
import '../../features/dashboard/presentation/bloc/dashboard/dashboard_cubit.dart';
import '../../features/measurement/presentation/bloc/measurement/measurement_bloc.dart';
import '../../features/measurement/presentation/bloc/add_measurement/add_measurement_cubit.dart';
import '../../features/measurement/presentation/bloc/shared_measurements/shared_measurements_bloc.dart';
import '../../features/nutrition/presentation/bloc/diet_entry/diet_entry_bloc.dart';
import '../../features/dashboard/presentation/bloc/navigation/navigation_cubit.dart';
import '../../features/dashboard/presentation/bloc/coach_dashboard/coach_dashboard_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // --- EXTERNAL ---
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);
  sl.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());
  sl.registerSingleton<Connectivity>(Connectivity());
  sl.registerLazySingleton<LastRouteStore>(() => LastRouteStore(sl<SharedPreferences>()));
  sl.registerLazySingleton<ActiveWorkoutStore>(() => ActiveWorkoutStore(sl<SharedPreferences>()));

  // --- CORE / UTIL ---
  sl.registerLazySingleton<AppLogger>(() => SentryLoggerImpl());
  sl.registerLazySingleton<DioClient>(
    () => DioClient(),
  );
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl<Connectivity>()),
  );
  sl.registerLazySingleton<SyncManager>(
    () => SyncManager(
      networkInfo: sl<NetworkInfo>(),
      dioClient: sl<DioClient>(),
      syncBox: Hive.box<String>('sync_queue'),
    ),
  );
  sl.registerLazySingleton<OfflineCache>(() => OfflineCache());
  sl.registerLazySingleton<CacheStatusNotifier>(() => CacheStatusNotifier());
  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(sl<DioClient>()),
  );

  // --- SERVICES / REPOSITORIES ---
  sl.registerLazySingleton(() => AuthApiService(sl<DioClient>(), sl<FlutterSecureStorage>()));
  sl.registerLazySingleton(() => AuthRepository(sl<AuthApiService>(), sl<SyncManager>(), sl<OfflineCache>()));
  sl.registerLazySingleton(() => TrainingApiService(sl<DioClient>()));
  sl.registerLazySingleton(
    () => TrainingRepository(
      apiService: sl<TrainingApiService>(),
      networkInfo: sl<NetworkInfo>(),
      syncManager: sl<SyncManager>(),
    ),
  );
  sl.registerLazySingleton(() => ChatApiService(sl<DioClient>()));
  sl.registerLazySingleton(() => SocialApiService(sl<DioClient>()));
  sl.registerLazySingleton(() => FileApiService(sl<DioClient>()));
  sl.registerLazySingleton(() => ClientGalleryApiService(sl<DioClient>()));
  sl.registerLazySingleton(() => CoachStudentProgressApiService(sl<DioClient>()));
  sl.registerLazySingleton(() => CoachProfileApiService(sl<DioClient>()));
  sl.registerLazySingleton(
    () => ChatRepository(
      sl<ChatApiService>(),
      sl<FileApiService>(),
      sl<NetworkInfo>(),
      sl<SyncManager>(),
    ),
  );
  sl.registerLazySingleton(() => SocialRepository(sl<SocialApiService>()));
  sl.registerLazySingleton(() => ClientGalleryRepository(sl<ClientGalleryApiService>()));
  sl.registerLazySingleton(() => CoachStudentProgressRepository(sl<CoachStudentProgressApiService>()));
  sl.registerLazySingleton(() => MeasurementRepository(sl<DioClient>()));
  sl.registerLazySingleton(() => DietApiService(sl<DioClient>()));
  sl.registerLazySingleton(() => WaterApiService(sl<DioClient>()));
  sl.registerLazySingleton(() => FoodApiService(sl<DioClient>()));
  sl.registerLazySingleton(() => AnalyticsApiService(sl<DioClient>()));
  sl.registerLazySingleton(
    () => NutritionRepository(
      dietService: sl<DietApiService>(),
      waterService: sl<WaterApiService>(),
      foodService: sl<FoodApiService>(),
      analyticsService: sl<AnalyticsApiService>(),
    ),
  );
  sl.registerLazySingleton(() => ProfileRepository(sl<DioClient>()));
  sl.registerLazySingleton(() => FinanceApiService(sl<DioClient>()));
  sl.registerLazySingleton(() => FinanceRepository(sl<FinanceApiService>()));

  // --- BLOCS / CUBITS ---
  sl.registerLazySingleton(() => AuthBloc(sl<AuthRepository>()));
  sl.registerFactory(() => TrainingBloc(sl<TrainingRepository>()));
  sl.registerLazySingleton(() => ChatBloc(sl<ChatRepository>()));
  sl.registerFactory(() => SocialBloc(sl<SocialRepository>()));
  sl.registerFactory(() => ClientGalleryBloc(sl<ClientGalleryRepository>(), sl<FileApiService>()));
  sl.registerFactory(() => CoachStudentProgressBloc(sl<CoachStudentProgressRepository>(), sl<FileApiService>()));
  sl.registerFactory(() => ActiveWorkoutBloc(trainingRepository: sl<TrainingRepository>(), store: sl<ActiveWorkoutStore>()));
  sl.registerFactory(() => WaterBloc(sl<NutritionRepository>()));
  sl.registerFactory(() => ProfileBloc(sl<ProfileRepository>(), sl<FileApiService>()));
  sl.registerFactory(() => ClientProfileViewCubit(sl<ProfileRepository>()));
  // BlocProvider(create:) bu bloc'u dispose'da close() ediyor
  // (coach_profile_detail_page.dart:215). Tekil kayit olursa ikinci acilista
  // kapatilmis ornek geri doner ve "Cannot add new events after calling close"
  // ile cokerdi. Her sayfa kendi ornegini almali.
  sl.registerFactory(() => CoachProfileBloc(sl<CoachProfileApiService>()));

  sl.registerFactory(() => CreatePersonalProgramCubit(repository: sl<TrainingRepository>()));
  sl.registerFactory(() => WorkoutHistoryCubit(sl<TrainingRepository>()));
  sl.registerFactory(() => ExerciseLibraryCubit(sl<TrainingRepository>()));
  sl.registerFactory(() => AssignedProgramsCubit(sl<TrainingRepository>()));
  sl.registerFactory(() => DietDashboardCubit(repository: sl<NutritionRepository>()));
  sl.registerFactory(() => DietGoalsCubit(sl<NutritionRepository>()));
  sl.registerFactory(() => DietProgramSelectionCubit(sl<NutritionRepository>()));
  sl.registerFactory(() => CoachDietTemplatesCubit(sl<NutritionRepository>()));
  sl.registerFactory(() => CoachWaterTrackingCubit(nutritionRepository: sl<NutritionRepository>()));
  sl.registerFactory(() => RecipeDetailsCubit(sl<NutritionRepository>()));
  sl.registerFactory(() => FoodDetailsCubit(sl<NutritionRepository>()));
  sl.registerFactory(() => FoodSearchCubit(sl<NutritionRepository>()));
  sl.registerFactory(() => AddCustomFoodCubit(sl<NutritionRepository>()));
  sl.registerFactory(() => MealTemplateEditorCubit(sl<NutritionRepository>()));
  sl.registerFactory(() => WaterAnalysisCubit());
  sl.registerFactory(() => FoodPickerCubit(sl<NutritionRepository>()));
  sl.registerFactory(() => GeminiAnalysisCubit(sl<NutritionRepository>()));
  sl.registerFactory(() => BarcodeScannerCubit(sl<NutritionRepository>()));
  sl.registerFactory(() => NutritionCameraCubit(sl<NutritionRepository>()));
  sl.registerFactory(() => SaveRecipeModalCubit());
  sl.registerFactory(() => DiscoveryCubit(sl<SocialRepository>(), sl<ProfileRepository>()));
  sl.registerFactory(() => OnboardingCubit());
  sl.registerFactory(() => RegisterFormCubit());
  sl.registerFactory(() => OtpCubit(sl<AuthRepository>()));
  sl.registerFactory(() => LoginFormCubit());
  sl.registerFactory(() => ForgotPasswordCubit(sl<AuthRepository>()));
  sl.registerFactory(() => FinanceBloc(repository: sl<FinanceRepository>()));
  sl.registerFactory(() => WeeklyProgressCubit(sl<TrainingRepository>()));
  sl.registerFactory(() => ExerciseAnalyticsCubit(sl<TrainingRepository>()));
  sl.registerFactory(() => DashboardCubit());
  sl.registerFactory(() => MeasurementBloc(sl<MeasurementRepository>()));
  sl.registerFactory(() => AddMeasurementCubit(sl<MeasurementRepository>()));
  sl.registerFactory(() => SharedMeasurementsBloc(sl<MeasurementRepository>()));
  sl.registerFactory(() => DietEntryBloc(sl<NutritionRepository>()));
  sl.registerLazySingleton(() => NavigationCubit(sl<LastRouteStore>()));
  sl.registerLazySingleton(() => RegistrationFlowCubit());
  sl.registerFactory(() => IntroCubit(sl<RegistrationFlowCubit>()));
  sl.registerFactory(() => CoachDashboardCubit(sl<FinanceRepository>()));
}
