import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/network_info.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_entry_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'package:gymapp_v2/features/nutrition/data/services/analytics_api_service.dart';
import 'package:gymapp_v2/features/nutrition/data/services/diet_api_service.dart';
import 'package:gymapp_v2/features/nutrition/data/services/food_api_service.dart';
import 'package:gymapp_v2/features/nutrition/data/services/water_api_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDietApiService extends Mock implements DietApiService {}

class MockWaterApiService extends Mock implements WaterApiService {}

class MockFoodApiService extends Mock implements FoodApiService {}

class MockAnalyticsApiService extends Mock implements AnalyticsApiService {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockSyncManager extends Mock implements SyncManager {}

/// İnternetsiz öğün ekleme (G-72, KR13): kuyruğa alınır, kalemler cihaz kimliği taşır, gün ekleme anının günüdür.
void main() {
  final RegExp uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
  final List<Map<String, dynamic>> basket = <Map<String, dynamic>>[
    <String, dynamic>{'foodId': 5, 'recipeId': null, 'amount': 120.0, 'note': null},
  ];

  late MockDietApiService diet;
  late MockNetworkInfo networkInfo;
  late MockSyncManager syncManager;
  late NutritionRepository repository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    diet = MockDietApiService();
    networkInfo = MockNetworkInfo();
    syncManager = MockSyncManager();
    repository = NutritionRepository(
      dietService: diet,
      waterService: MockWaterApiService(),
      foodService: MockFoodApiService(),
      analyticsService: MockAnalyticsApiService(),
      networkInfo: networkInfo,
      syncManager: syncManager,
    );
    when(() => syncManager.addToQueue(any(), any())).thenAnswer((_) async {});
    when(
      () => diet.logMeal(
        mealTypeStr: any(named: 'mealTypeStr'),
        items: any(named: 'items'),
        date: any(named: 'date'),
      ),
    ).thenAnswer((_) async => ApiResponse<MealEntryModel>(success: true, message: '', timestamp: ''));
  });

  test('bağlantı yokken öğün kuyruğa alınır, sunucuya gidilmez', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);

    final result = await repository.logMeal(
      mealType: MealType.kahvalti,
      items: basket,
      date: DateTime.utc(2026, 9, 17, 8),
    );

    final Map<String, dynamic> payload =
        verify(() => syncManager.addToQueue(DietApiService.mealLogPath, captureAny())).captured.single
            as Map<String, dynamic>;

    expect(payload['mealType'], 'KAHVALTI');
    expect(payload['takenDatetime'], '2026-09-17T08:00:00.000Z');

    final List<dynamic> itemsList = payload['items'] as List<dynamic>;
    final Map<String, dynamic> item = itemsList.single as Map<String, dynamic>;
    expect(item['foodId'], 5);
    expect(item['localId'], matches(uuidPattern));

    verifyNever(
      () => diet.logMeal(
        mealTypeStr: any(named: 'mealTypeStr'),
        items: any(named: 'items'),
        date: any(named: 'date'),
      ),
    );
    expect(result.success, true);
  });

  test('bağlantı varken öğün kalemleri yerel kimlikle sunucuya gider', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);

    await repository.logMeal(mealType: MealType.kahvalti, items: basket);

    final List<Map<String, dynamic>> sent =
        verify(
              () => diet.logMeal(
                mealTypeStr: 'KAHVALTI',
                items: captureAny(named: 'items'),
                date: any(named: 'date'),
              ),
            ).captured.single
            as List<Map<String, dynamic>>;

    expect(sent.single['localId'], matches(uuidPattern));
    verifyNever(() => syncManager.addToQueue(any(), any()));
  });

  test('tarih verilmeden kuyruğa alınan öğün ekleme anının gününü taşır', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);

    final DateTime before = DateTime.now().toUtc();
    await repository.logMeal(mealType: MealType.kahvalti, items: basket);

    final Map<String, dynamic> payload =
        verify(() => syncManager.addToQueue(DietApiService.mealLogPath, captureAny())).captured.single
            as Map<String, dynamic>;

    expect(
      DateTime.parse(payload['takenDatetime'] as String).difference(before).inMinutes.abs(),
      lessThan(1),
    );
  });
}
