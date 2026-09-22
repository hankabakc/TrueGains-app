import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/network_info.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_entry_model.dart';
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
/// İnternetsiz silme ve bekleyenlerin güne yansıması (G-83).
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
    when(
      () => syncManager.addToQueue(any(), any(), method: any(named: 'method'), preview: any(named: 'preview')),
    ).thenAnswer((_) async {});
    when(
      () => diet.logMeal(
        mealTypeStr: any(named: 'mealTypeStr'),
        items: any(named: 'items'),
        date: any(named: 'date'),
      ),
    ).thenAnswer((_) async => ApiResponse<MealEntryModel>(success: true, message: '', timestamp: ''));
    when(() => diet.deleteMealItem(any()))
        .thenAnswer((_) async => ApiResponse<void>(success: true, message: 'Silindi', timestamp: ''));
  });

  test('bağlantı yokken öğün kuyruğa alınır, sunucuya gidilmez', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);

    final result = await repository.logMeal(
      mealType: MealType.kahvalti,
      items: basket,
      date: DateTime.utc(2026, 9, 17, 8),
    );

    final Map<String, dynamic> payload =
        verify(
              () => syncManager.addToQueue(
                DietApiService.mealLogPath,
                captureAny(),
                method: any(named: 'method'),
                preview: any(named: 'preview'),
              ),
            ).captured.single
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
    verifyNever(
      () => syncManager.addToQueue(any(), any(), method: any(named: 'method'), preview: any(named: 'preview')),
    );
  });

  test('tarih verilmeden kuyruğa alınan öğün ekleme anının gününü taşır', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);

    final DateTime before = DateTime.now().toUtc();
    await repository.logMeal(mealType: MealType.kahvalti, items: basket);

    final Map<String, dynamic> payload =
        verify(
              () => syncManager.addToQueue(
                DietApiService.mealLogPath,
                captureAny(),
                method: any(named: 'method'),
                preview: any(named: 'preview'),
              ),
            ).captured.single
            as Map<String, dynamic>;

    expect(
      DateTime.parse(payload['takenDatetime'] as String).difference(before).inMinutes.abs(),
      lessThan(1),
    );
  });

  // --- G-83 ---

  final List<Map<String, dynamic>> basketWithPreview = <Map<String, dynamic>>[
    <String, dynamic>{
      'foodId': 5,
      'recipeId': null,
      'amount': 120.0,
      'note': null,
      'foodName': 'Yulaf',
      'calories': 450.0,
      'protein': 15.0,
    },
  ];

  test('bağlantı yokken sepetteki ad ve değerler yüke girmez, önizlemede aynı kimlikle kalır', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);

    await repository.logMeal(mealType: MealType.kahvalti, items: basketWithPreview, date: DateTime.utc(2026, 9, 18, 8));

    final List<dynamic> captured = verify(
      () => syncManager.addToQueue(
        DietApiService.mealLogPath,
        captureAny(),
        method: any(named: 'method'),
        preview: captureAny(named: 'preview'),
      ),
    ).captured;
    final Map<String, dynamic> item =
        ((captured[0] as Map<String, dynamic>)['items'] as List<dynamic>).single as Map<String, dynamic>;
    final Map<String, dynamic> preview = (captured[1] as List<Map<String, dynamic>>).single;

    expect(item.keys, unorderedEquals(<String>['foodId', 'recipeId', 'amount', 'note', 'localId']));
    expect(preview['foodName'], 'Yulaf');
    expect(preview['calories'], 450.0);
    expect(preview['localId'], item['localId']);
  });

  test('bağlantı varken sunucuya ad ve besin değerleri gitmez', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);

    await repository.logMeal(mealType: MealType.kahvalti, items: basketWithPreview);

    final List<Map<String, dynamic>> sent =
        verify(
              () => diet.logMeal(mealTypeStr: 'KAHVALTI', items: captureAny(named: 'items'), date: any(named: 'date')),
            ).captured.single
            as List<Map<String, dynamic>>;

    expect(sent.single.keys, unorderedEquals(<String>['foodId', 'recipeId', 'amount', 'note', 'localId']));
  });

  test('bağlantı yokken silme DELETE olarak kuyruğa girer, sunucuya gidilmez', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);

    final ApiResponse<void> result = await repository.deleteMealItem(7);

    verify(
      () => syncManager.addToQueue(
        '/nutrition/meal-logs/items/7',
        <String, dynamic>{},
        method: SyncManager.methodDelete,
        preview: any(named: 'preview'),
      ),
    ).called(1);
    verifyNever(() => diet.deleteMealItem(any()));
    expect(result.success, isTrue);
  });

  test('bağlantı varken silme doğrudan sunucuya gider, kuyruğa girmez', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);

    await repository.deleteMealItem(7);

    verify(() => diet.deleteMealItem(7)).called(1);
    verifyNever(
      () => syncManager.addToQueue(any(), any(), method: any(named: 'method'), preview: any(named: 'preview')),
    );
  });

  ApiResponse<DailyDietLogModel> serverLog(List<MealEntryModel> extras) => ApiResponse<DailyDietLogModel>(
        success: true,
        message: '',
        timestamp: '',
        data: DailyDietLogModel(plannedMeals: const <PlannedMealModel>[], extraEntries: extras),
      );

  PendingRecord queuedMeal(String key, DateTime takenLocal) => PendingRecord(
        key: key,
        endpoint: DietApiService.mealLogPath,
        method: SyncManager.methodPost,
        payload: <String, dynamic>{
          'mealType': 'KAHVALTI',
          'items': <Map<String, dynamic>>[
            <String, dynamic>{'foodId': 5, 'amount': 120.0, 'localId': 'L-$key'},
          ],
          'takenDatetime': takenLocal.toUtc().toIso8601String(),
        },
        preview: <Map<String, dynamic>>[
          <String, dynamic>{'foodId': 5, 'amount': 120.0, 'foodName': 'Yulaf', 'calories': 450.0, 'localId': 'L-$key'},
        ],
      );

  test('kuyruktaki öğün yalnızca kendi gününün günlüğüne bekleyen ekstra olarak girer', () async {
    when(() => diet.getDailyDietLog(any())).thenAnswer((_) async => serverLog(const <MealEntryModel>[]));
    when(() => syncManager.pendingRecords()).thenReturn(<PendingRecord>[
      queuedMeal('q1', DateTime(2026, 9, 18, 9)),
      queuedMeal('q2', DateTime(2026, 9, 17, 9)),
    ]);

    final ApiResponse<DailyDietLogModel> result = await repository.getDailyDietLog(DateTime(2026, 9, 18));

    final MealEntryModel entry = result.data!.extraEntries.single;
    final MealItemModel item = entry.items.single;
    expect(entry.mealType, MealType.kahvalti);
    expect(item.foodName, 'Yulaf');
    expect(item.isPending, isTrue);
    expect(item.queueKey, 'q1');
    expect(item.localId, 'L-q1');
    expect(entry.totalCalories, 450.0);
  });

  test('silinmeyi bekleyen kalem günlükte gizlenir ve öğün toplamından düşer', () async {
    when(() => diet.getDailyDietLog(any())).thenAnswer(
      (_) async => serverLog(<MealEntryModel>[
        MealEntryModel(
          id: 3,
          clientId: 1,
          takenDatetime: DateTime(2026, 9, 18, 8),
          mealType: MealType.kahvalti,
          calories: 500,
          items: const <MealItemModel>[
            MealItemModel(id: 7, foodId: 5, foodName: 'Yulaf', amount: 100, calories: 300, protein: 10, carbs: 50, fat: 5),
            MealItemModel(id: 8, foodId: 6, foodName: 'Süt', amount: 200, calories: 200, protein: 7, carbs: 10, fat: 8),
          ],
        ),
      ]),
    );
    when(() => syncManager.pendingRecords()).thenReturn(const <PendingRecord>[
      PendingRecord(
        key: 'd1',
        endpoint: '/nutrition/meal-logs/items/7',
        method: SyncManager.methodDelete,
        payload: <String, dynamic>{},
      ),
    ]);

    final ApiResponse<DailyDietLogModel> result = await repository.getDailyDietLog(DateTime(2026, 9, 18));

    final MealEntryModel entry = result.data!.extraEntries.single;
    expect(entry.items.map((MealItemModel i) => i.id).toList(), <int>[8]);
    expect(entry.totalCalories, 200.0);
  });
}
