import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:gymapp_v2/core/constants/storage_keys.dart';
import 'package:gymapp_v2/core/constants/network_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import '../models/diet_program_model.dart';
import '../models/diet_entry_model.dart';
import '../models/diet_assignment_model.dart';
import '../models/meal_template_model.dart';
import '../models/food_model.dart';
import '../models/water_intake_model.dart';
import '../models/client_water_tracking_model.dart';
import '../models/ocr_scan_response_model.dart';
import '../models/meal_entry_model.dart';
import '../models/meal_history_model.dart';
import '../models/nutrition_dashboard_model.dart';
import '../models/recipe_model.dart';
import '../models/ai_recipe_suggestion_response_model.dart';
import 'package:uuid/uuid.dart';
import 'package:gymapp_v2/core/network/network_info.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import '../services/diet_api_service.dart';
import '../services/water_api_service.dart';
import '../services/food_api_service.dart';
import '../services/analytics_api_service.dart';

class NutritionRepository {
  /// Öğün kaydı isteğinin kalem alanları (`LogMealItemRequest`); kalanı yalnızca cihazda gösterilir (G-83).
  static const Set<String> _serverItemKeys = <String>{'foodId', 'recipeId', 'amount', 'note', 'localId'};

  final DietApiService _dietService;
  final WaterApiService _waterService;
  final FoodApiService _foodService;
  final AnalyticsApiService _analyticsService;
  final NetworkInfo _networkInfo;
  final SyncManager _syncManager;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  StompClient? _stompClient;

  NutritionRepository({
    required DietApiService dietService,
    required WaterApiService waterService,
    required FoodApiService foodService,
    required AnalyticsApiService analyticsService,
    required NetworkInfo networkInfo,
    required SyncManager syncManager,
  })  : _dietService = dietService,
        _waterService = waterService,
        _foodService = foodService,
        _analyticsService = analyticsService,
        _networkInfo = networkInfo,
        _syncManager = syncManager;

  Future<ApiResponse<OcrScanResponseModel>> scanFoodImage(XFile imageFile) {
    return _foodService.scanFoodImage(imageFile);
  }

  Future<ApiResponse<DailyDietLogModel>> getDailyDietLog(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final ApiResponse<DailyDietLogModel> res = await _dietService.getDailyDietLog(dateStr);
    if (!res.success || res.data == null) return res;
    return ApiResponse<DailyDietLogModel>(
      success: true,
      message: res.message,
      timestamp: res.timestamp,
      data: _withQueued(res.data!, date),
    );
  }

  /// Kuyruğu güne yansıtır (KR13, G-83): o güne ait bekleyen öğün ekstra giriş olarak eklenir, silinmeyi
  /// bekleyen kalem gizlenir. Günlük toplam cihazda bu listeden hesaplanır.
  // ponytail: gönderim bittiği an ekran kendiliğinden tazelenmez; bir sonraki yüklemede bekleyen işareti kalkar.
  DailyDietLogModel _withQueued(DailyDietLogModel log, DateTime date) {
    final List<PendingRecord> queued = _syncManager.pendingRecords();
    const String deletePrefix = '${DietApiService.mealItemsPath}/';
    final Set<int> deletedIds = <int>{
      for (final PendingRecord r in queued)
        if (r.method == SyncManager.methodDelete && r.endpoint.startsWith(deletePrefix))
          int.tryParse(r.endpoint.substring(deletePrefix.length)) ?? -1,
    };

    final List<MealEntryModel> entries = <MealEntryModel>[];
    for (final MealEntryModel entry in log.extraEntries) {
      if (!entry.items.any((MealItemModel i) => deletedIds.contains(i.id))) {
        entries.add(entry);
        continue;
      }
      final List<MealItemModel> kept = entry.items.where((MealItemModel i) => !deletedIds.contains(i.id)).toList();
      // Toplamlar verilmez: MealEntryModel kalan kalemlerden toplar; sunucunun eski toplamı silineni içeriyor.
      if (kept.isNotEmpty) {
        entries.add(MealEntryModel(
          id: entry.id,
          clientId: entry.clientId,
          takenDatetime: entry.takenDatetime,
          mealType: entry.mealType,
          items: kept,
        ));
      }
    }

    for (final PendingRecord r in queued) {
      if (r.endpoint != DietApiService.mealLogPath) continue;
      final DateTime? taken = DateTime.tryParse((r.payload['takenDatetime'] as String?) ?? '')?.toLocal();
      if (taken == null || taken.year != date.year || taken.month != date.month || taken.day != date.day) continue;
      // G-83 öncesi kuyruğa girmiş öğünde önizleme yok; kalemler ad ve değer olmadan gösterilir.
      final List<dynamic> source =
          r.preview.isNotEmpty ? r.preview : (r.payload['items'] as List<dynamic>?) ?? const <dynamic>[];
      entries.add(MealEntryModel(
        id: 0,
        clientId: 0,
        takenDatetime: taken,
        mealType: MealTypeExtension.fromString((r.payload['mealType'] as String?) ?? ''),
        items: <MealItemModel>[
          for (final dynamic p in source)
            MealItemModel.fromJson(p as Map<String, dynamic>)
                .copyWith(localId: p['localId'] as String?, queueKey: r.key),
        ],
      ));
    }

    return DailyDietLogModel(plannedMeals: log.plannedMeals, extraEntries: entries);
  }

  Future<ApiResponse<MealEntryModel>> togglePlannedMeal({
    required DateTime date,
    required int mealId,
    required bool consumed,
    List<int>? ingredientIds,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    return _dietService.togglePlannedMeal(dateStr, mealId, consumed, ingredientIds: ingredientIds);
  }

  Future<ApiResponse<void>> deleteMealItem(int itemId) async {
    if (await _networkInfo.isConnected) {
      return _dietService.deleteMealItem(itemId);
    }

    // KR13 (G-83): bağlantı yoksa silme kuyruğa girer; günlük kalemi hemen gizler.
    await _syncManager.addToQueue(
      '${DietApiService.mealItemsPath}/$itemId',
      <String, dynamic>{},
      method: SyncManager.methodDelete,
    );
    return ApiResponse<void>(
      success: true,
      message: 'Bağlantı yok. Silme internet geldiğinde sunucuya iletilecek.',
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  /// Sunucuya henüz gitmemiş öğün kalemini kuyruktan çıkarır; kullanıcı onayıyla çağrılır (G-83).
  Future<void> discardPendingMealItem(String queueKey, String localId) {
    return _syncManager.removeQueuedItem(queueKey, localId);
  }

  Future<ApiResponse<void>> deleteMealEntry(int entryId) {
    return _dietService.deleteMealEntry(entryId);
  }

  Future<ApiResponse<List<FoodModel>>> searchFood(String query) async {
    return _foodService.searchFood(query);
  }

  /// Telefondaki besin kataloğunu indirir / tazeler (KR16, G-71); yanıtı okuma önbelleği saklar.
  Future<ApiResponse<List<FoodModel>>> refreshFoodCatalog() {
    return _foodService.getCatalog();
  }

  Future<ApiResponse<FoodModel>> createFood(FoodModel food) {
    return _foodService.createFood(food);
  }

  Future<ApiResponse<FoodModel>> getFoodDetails(int id, {bool ignoreOverride = false}) {
    return _foodService.getFoodDetails(id, ignoreOverride: ignoreOverride);
  }

  Future<ApiResponse<FoodModel>> getFoodByBarcode(String barcode) {
    return _foodService.getFoodByBarcode(barcode);
  }

  Future<ApiResponse<FoodModel>> overrideFood(int id, FoodModel food) {
    return _foodService.overrideFood(id, food);
  }

  Future<ApiResponse<void>> deleteOverride(int id) {
    return _foodService.deleteOverride(id);
  }

  // --- Diet Management ---

  Future<ApiResponse<List<DietProgramModel>>> getMyPrograms() {
    return _dietService.getMyPrograms();
  }

  Future<ApiResponse<DietProgramModel>> getMainProgram() {
    return _dietService.getMainProgram();
  }

  Future<ApiResponse<DietProgramModel>> getProgramById(int id) {
    return _dietService.getProgramById(id);
  }

  Future<ApiResponse<DietProgramModel>> createProgram(
    String name,
    bool isMain,
  ) {
    return _dietService.createProgram(name, isMain);
  }

  Future<ApiResponse<DietProgramModel>> addIngredientsBulk(int mealId, List<MealIngredientModel> items) {
    final List<Map<String, dynamic>> requests = items.map((item) => {
      'foodId': item.foodId,
      'recipeId': item.recipeId,
      'amount': item.amount,
      'note': item.note,
      'ignoreOverride': item.ignoreOverride,
    }).toList();

    return _dietService.addIngredientsBulk(mealId, requests);
  }

  Future<ApiResponse<DietProgramModel>> addIngredient(
    int mealId,
    double amount, {
    int? foodId,
    int? recipeId,
    String? note,
    bool ignoreOverride = false,
  }) {
    return _dietService.addIngredient(
      mealId,
      amount,
      foodId: foodId,
      recipeId: recipeId,
      note: note,
      ignoreOverride: ignoreOverride,
    );
  }

  Future<ApiResponse<DietProgramModel>> updateDietRecipeIngredient(int ingredientId, RecipeModel updatedRecipe) {
    return _dietService.updateDietRecipeIngredient(ingredientId, updatedRecipe.toJson());
  }

  Future<ApiResponse<DietProgramModel>> deleteMeal(int mealId) {
    return _dietService.deleteMeal(mealId);
  }

  Future<ApiResponse<DietProgramModel>> renameProgram(int id, String name) {
    return _dietService.renameProgram(id, name);
  }

  Future<ApiResponse<DietProgramModel>> deleteMealIngredient(int ingredientId) {
    return _dietService.deleteMealIngredient(ingredientId);
  }

  Future<ApiResponse<DietProgramModel>> updateMealIngredientAmount(
    int ingredientId,
    double amount,
  ) {
    return _dietService.updateMealIngredientAmount(ingredientId, amount);
  }

  Future<ApiResponse<List<MealHistoryModel>>> getRecentGroupedFoods() {
    return _foodService.getRecentGroupedFoods();
  }

  Future<ApiResponse<List<FoodModel>>> getRecentFoods() {
    return _foodService.getRecentFoods();
  }

  Future<ApiResponse<List<FoodModel>>> getOverriddenFoods() {
    return _foodService.getOverriddenFoods();
  }

  Future<ApiResponse<List<FoodModel>>> getMyCustomFoods() {
    return _foodService.getMyCustomFoods();
  }

  // --- Meal Templates ---

  Future<ApiResponse<List<MealTemplateModel>>> getTemplates() {
    return _foodService.getTemplates();
  }

  Future<ApiResponse<MealTemplateDetailModel>> getTemplateDetail(int id) {
    return _foodService.getTemplateDetail(id);
  }

  Future<ApiResponse<MealTemplateModel>> createTemplate(String name) {
    return _foodService.createTemplate(name);
  }

  Future<ApiResponse<void>> updateTemplate(int id, String name, List<MealType> applicableMealTypes, List<MealIngredientModel> ingredients) {
    return _foodService.updateTemplate(id, {
      'name': name,
      'applicableMealTypes': applicableMealTypes.map((e) => e.toBackendString()).toList(),
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
    });
  }

  Future<ApiResponse<void>> deleteTemplate(int id) {
    return _foodService.deleteTemplate(id);
  }

  // --- Meal Logging (Daily) ---

  Future<ApiResponse<MealEntryModel>> logMeal({
    required MealType mealType,
    required List<Map<String, dynamic>> items,
    DateTime? date,
  }) async {
    // Tekrar koruması (G-72): her kalem cihazda kimlik alır; çevrimiçi ve kuyruk yolu aynı kimliği taşır.
    final List<Map<String, dynamic>> itemsWithId = items
        .map((Map<String, dynamic> item) => <String, dynamic>{...item, 'localId': const Uuid().v4()})
        .toList();
    // G-83: sunucuya yalnızca istek alanları gider; ad ve besin değerleri bekleyen öğünün gösterimi içindir.
    final List<Map<String, dynamic>> serverItems = <Map<String, dynamic>>[
      for (final Map<String, dynamic> item in itemsWithId)
        <String, dynamic>{
          for (final MapEntry<String, dynamic> e in item.entries)
            if (_serverItemKeys.contains(e.key)) e.key: e.value,
        },
    ];

    if (await _networkInfo.isConnected) {
      return _dietService.logMeal(mealTypeStr: mealType.toBackendString(), items: serverItems, date: date);
    }

    // KR13 (G-72): bağlantı yoksa öğün kuyruğa alınır. Gün, eklendiği anın günüdür; gönderim anının değil.
    await _syncManager.addToQueue(
      DietApiService.mealLogPath,
      <String, dynamic>{
        'mealType': mealType.toBackendString(),
        'items': serverItems,
        'takenDatetime': (date ?? DateTime.now()).toUtc().toIso8601String(),
      },
      preview: itemsWithId,
    );
    return ApiResponse<MealEntryModel>(
      success: true,
      message: 'Bağlantı yok. Öğün internet geldiğinde kaydedilecek.',
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  Future<ApiResponse<MealEntryModel>> addFoodToMealLog({
    required MealType mealType,
    required int foodId,
    required double amount,
    bool ignoreOverride = false,
  }) {
    return _dietService.addFoodToMealLog(
      mealTypeStr: mealType.toBackendString(),
      foodId: foodId,
      amount: amount,
      ignoreOverride: ignoreOverride,
    );
  }

  Future<ApiResponse<List<MealEntryModel>>> getDailyMealLogs([DateTime? date]) {
    return _dietService.getDailyMealLogs(date);
  }

  // --- Water Intake ---

  Future<ApiResponse<WaterIntakeModel>> addWater(int amountMl) {
    return _waterService.addWater(amountMl);
  }

  Future<ApiResponse<WaterDailySummaryModel>> getDailyWaterSummary([
    DateTime? date,
  ]) {
    return _waterService.getDailyWaterSummary(date);
  }

  Future<ApiResponse<List<WaterDailyTotalModel>>> getWaterRangeSummary(
    DateTime start,
    DateTime end,
  ) {
    return _waterService.getWaterRangeSummary(start, end);
  }

  Future<ApiResponse<void>> updateWaterTarget(int targetMl) {
    return _waterService.updateWaterTarget(targetMl);
  }

  Future<ApiResponse<CustomGlassModel>> addCustomGlass(
    String name,
    int sizeMl,
  ) {
    return _waterService.addCustomGlass(name, sizeMl);
  }

  Future<ApiResponse<void>> deleteCustomGlass(int id) {
    return _waterService.deleteCustomGlass(id);
  }

  Future<ApiResponse<void>> deleteWaterIntake(int id) {
    return _waterService.deleteWaterIntake(id);
  }

  // --- Analytics & Dashboard ---

  Future<ApiResponse<NutritionDashboardModel>> getDashboardData([int? programId, int? targetUserId]) {
    return _analyticsService.getDashboardData(programId, targetUserId);
  }

  Future<ApiResponse<void>> deleteProgram(int id) {
    return _dietService.deleteProgram(id);
  }

  Future<ApiResponse<void>> activateProgram(int id) {
    return _dietService.activateProgram(id);
  }

  Future<ApiResponse<DietProgramModel>> approveOrphan(int id, bool keep) {
    return _dietService.approveOrphan(id, keep);
  }

  Future<ApiResponse<void>> updateProgramGoals(
    int id, {
    double? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
    double? targetSugar,
    double? targetFiber,
    double? targetSodium,
    double? targetCholesterol,
    double? targetPotassium,
  }) {
    return _dietService.updateProgramGoals(
      id,
      {
        if (targetCalories != null) 'targetCalories': targetCalories,
        if (targetProtein != null) 'targetProtein': targetProtein,
        if (targetCarbs != null) 'targetCarbs': targetCarbs,
        if (targetFat != null) 'targetFat': targetFat,
        if (targetSugar != null) 'targetSugar': targetSugar,
        if (targetFiber != null) 'targetFiber': targetFiber,
        if (targetSodium != null) 'targetSodium': targetSodium,
        if (targetCholesterol != null) 'targetCholesterol': targetCholesterol,
        if (targetPotassium != null) 'targetPotassium': targetPotassium,
      },
    );
  }

  Future<ApiResponse<void>> updateNutritionGoals({
    double? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
    double? targetSugar,
    double? targetFiber,
    double? targetSodium,
    double? targetCholesterol,
    double? targetPotassium,
  }) {
    return _analyticsService.updateNutritionGoals(
      {
        if (targetCalories != null) 'targetCalories': targetCalories,
        if (targetProtein != null) 'targetProtein': targetProtein,
        if (targetCarbs != null) 'targetCarbs': targetCarbs,
        if (targetFat != null) 'targetFat': targetFat,
        if (targetSugar != null) 'targetSugar': targetSugar,
        if (targetFiber != null) 'targetFiber': targetFiber,
        if (targetSodium != null) 'targetSodium': targetSodium,
        if (targetCholesterol != null) 'targetCholesterol': targetCholesterol,
        if (targetPotassium != null) 'targetPotassium': targetPotassium,
      },
    );
  }

  // --- Recipes ---

  Future<ApiResponse<List<RecipeModel>>> getRecipes([String? query]) {
    return _foodService.getRecipes(query);
  }

  Future<ApiResponse<RecipeModel>> getRecipeById(int id) {
    return _foodService.getRecipeById(id);
  }

  // --- AI Recipes ---

  Future<ApiResponse<AiRecipeSuggestionResponseModel?>> getLastAiSuggestion() {
    return _analyticsService.getLastAiSuggestion();
  }

  Future<ApiResponse<AiRecipeSuggestionResponseModel>> suggestRecipe({int? programId}) {
    return _analyticsService.suggestRecipe(programId: programId);
  }

  Future<ApiResponse<DietProgramModel>> saveRecipe(int mealId, int recipeId) {
    return _analyticsService.saveRecipe(mealId, recipeId);
  }

  // --- Coach Diet Templates ---

  Future<ApiResponse<List<DietProgramModel>>> getCoachDietTemplates() {
    return _dietService.getCoachDietTemplates();
  }

  Future<ApiResponse<DietProgramModel>> createDietTemplate(String name) {
    return _dietService.createDietTemplate(name);
  }

  Future<ApiResponse<DietProgramModel>> assignDietTemplate(int templateId, int clientId) {
    return _dietService.assignDietTemplate(templateId, clientId);
  }

  Future<ApiResponse<List<DietAssignmentModel>>> getTemplateAssignments(int templateId) {
    return _dietService.getTemplateAssignments(templateId);
  }

  Future<ApiResponse<List<DietAssignmentModel>>> fetchDietAssignments() {
    return _dietService.fetchDietAssignments();
  }

  Future<ApiResponse<void>> unassignTemplate(int templateId, int clientId) {
    return _dietService.unassignTemplate(templateId, clientId);
  }

  Future<ApiResponse<List<ClientWaterTrackingModel>>> getCoachStudentsWaterIntake() {
    return _waterService.getCoachStudentsWaterIntake();
  }

  // --- WebSocket (Stomp) Abonelik ---
  Future<void> subscribeToDietUpdates({
    required int clientId,
    required String wsUrl,
    required void Function() onUpdateReceived,
  }) async {
    _stompClient?.deactivate();

    final token = await _storage.read(key: StorageKeys.accessToken);

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        stompConnectHeaders: {
          if (token != null)
            NetworkConstants.authorizationHeader:
                '${NetworkConstants.bearerPrefix}$token',
        },
        webSocketConnectHeaders: {
          if (token != null)
            NetworkConstants.authorizationHeader:
                '${NetworkConstants.bearerPrefix}$token',
        },
        onConnect: (frame) {
          _stompClient?.subscribe(
            destination: '/topic/diet/$clientId',
            callback: (frame) {
              if (frame.body == 'REFRESH_REQUIRED') {
                onUpdateReceived();
              }
            },
          );
        },
        onWebSocketError: (error) {},
        onStompError: (frame) {},
      ),
    );
    _stompClient?.activate();
  }

  void unsubscribeFromDietUpdates() {
    _stompClient?.deactivate();
    _stompClient = null;
  }
}
