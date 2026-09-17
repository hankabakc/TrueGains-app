import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:gymapp_v2/core/widgets/sync_on_resume.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'package:gymapp_v2/features/training/models/exercise.dart';
import 'package:gymapp_v2/features/training/repository/training_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncManager extends Mock implements SyncManager {}
class MockNutritionRepository extends Mock implements NutritionRepository {}
class MockTrainingRepository extends Mock implements TrainingRepository {}

void main() {
  late MockSyncManager syncManager;
  late MockNutritionRepository nutrition;
  late MockTrainingRepository training;

  setUp(() {
    syncManager = MockSyncManager();
    when(() => syncManager.syncPendingData()).thenAnswer((_) async {});
    GetIt.instance.registerSingleton<SyncManager>(syncManager);

    nutrition = MockNutritionRepository();
    training = MockTrainingRepository();
    when(() => nutrition.refreshFoodCatalog()).thenAnswer(
      (_) async => ApiResponse<List<FoodModel>>(success: true, message: '', data: <FoodModel>[], timestamp: ''),
    );
    when(() => training.getAllExercises()).thenAnswer(
      (_) async => ApiResponse<List<Exercise>>(success: true, message: '', data: <Exercise>[], timestamp: ''),
    );
    GetIt.instance.registerSingleton<NutritionRepository>(nutrition);
    GetIt.instance.registerSingleton<TrainingRepository>(training);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('uygulama öne gelince bekleyen kayıtlar gönderilir', (tester) async {
    await tester.pumpWidget(const SyncOnResume(child: SizedBox()));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    verify(() => syncManager.syncPendingData()).called(1);
  });

  testWidgets('arka plana geçişte gönderim yapılmaz', (tester) async {
    await tester.pumpWidget(const SyncOnResume(child: SizedBox()));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

    verifyNever(() => syncManager.syncPendingData());
  });

  testWidgets('açılışta besin kataloğu ve egzersiz kütüphanesi indirilir', (WidgetTester tester) async {
    await tester.pumpWidget(const SyncOnResume(child: SizedBox()));
    verify(() => nutrition.refreshFoodCatalog()).called(1);
    verify(() => training.getAllExercises()).called(1);
  });

  testWidgets('öne gelince besin kataloğu ve egzersiz kütüphanesi tazelenir', (WidgetTester tester) async {
    await tester.pumpWidget(const SyncOnResume(child: SizedBox()));
    clearInteractions(nutrition);
    clearInteractions(training);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    verify(() => nutrition.refreshFoodCatalog()).called(1);
    verify(() => training.getAllExercises()).called(1);
  });
}
