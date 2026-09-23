import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_entry_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/food_search/food_search_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockNutritionRepository extends Mock implements NutritionRepository {}

/// Sepetten öğün kaydı (G-83): bekleyen öğünün günlükte görünmesi için her kalem adını ve miktara göre besin
/// değerlerini taşır (sepette gösterilen formül: değer × miktar / varsayılan miktar).
void main() {
  late MockNutritionRepository repository;

  setUpAll(() {
    registerFallbackValue(MealType.kahvalti);
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repository = MockNutritionRepository();
    when(
      () => repository.logMeal(mealType: any(named: 'mealType'), items: any(named: 'items'), date: any(named: 'date')),
    ).thenAnswer((_) async => ApiResponse<MealEntryModel>(success: true, message: '', timestamp: ''));
  });

  test('öğün kaydında kalem adı ve miktara göre besin değerleri gönderilir', () async {
    final FoodSearchCubit cubit = FoodSearchCubit(repository);
    cubit.addIngredientsToBasket(<MealIngredientModel>[
      MealIngredientModel(
        foodId: 5,
        foodName: 'Yulaf',
        amount: 50,
        defaultAmount: 100,
        protein: 13,
        carbs: 60,
        fat: 7,
        calories: 380,
        isBrandVerified: false,
        ignoreOverride: false,
        isOverridden: false,
        sugar: 1,
        fiber: 10,
        sodium: 2,
        potassium: 400,
        cholesterol: 0,
      ),
    ]);

    await cubit.saveAll(mealType: MealType.kahvalti);

    final List<Map<String, dynamic>> items =
        verify(
              () => repository.logMeal(
                mealType: MealType.kahvalti,
                items: captureAny(named: 'items'),
                date: any(named: 'date'),
              ),
            ).captured.single
            as List<Map<String, dynamic>>;
    final Map<String, dynamic> item = items.single;
    expect(item['foodId'], 5);
    expect(item['amount'], 50);
    expect(item['foodName'], 'Yulaf');
    expect(item['calories'], 190);
    expect(item['protein'], 6.5);
    expect(item['potassium'], 200);
    await cubit.close();
  });

  // --- G-87: internetsiz oluşturulan (sunucu kimliği olmayan) özel besin ---

  const FoodModel pendingFood = FoodModel(
    name: 'Ev yoğurdu',
    defaultUnit: 'g',
    defaultAmount: 100,
    calories: 60,
    protein: 4,
    carbs: 5,
    fat: 3,
    isCustom: true,
    localId: 'LF1',
  );

  MealIngredientModel recipeItem() => MealIngredientModel(
        foodName: 'Mercimek çorbası',
        amount: 1,
        defaultAmount: 1,
        protein: 9,
        carbs: 20,
        fat: 4,
        calories: 150,
        isBrandVerified: false,
        ignoreOverride: true,
        isOverridden: false,
        sugar: 0,
        fiber: 0,
        sodium: 0,
        potassium: 0,
        cholesterol: 0,
        recipeId: 3,
      );

  test('bekleyen besin sepete eklenir, kimliği boş tarif kalemiyle karışmaz; ikinci dokunuş yalnız onu çıkarır', () async {
    final FoodSearchCubit cubit = FoodSearchCubit(repository);
    cubit.addIngredientsToBasket(<MealIngredientModel>[recipeItem()]);

    cubit.toggleFoodSelection(pendingFood);

    expect(cubit.state.basket, hasLength(2));
    expect(cubit.state.basket.last.foodId, isNull);
    expect(cubit.state.basket.last.foodLocalId, 'LF1');

    cubit.toggleFoodSelection(pendingFood);

    expect(cubit.state.basket.single.recipeId, 3);
    await cubit.close();
  });

  test('öğün kaydında bekleyen besinin cihaz kimliği gider, diğer kalemde bu alan olmaz', () async {
    final FoodSearchCubit cubit = FoodSearchCubit(repository);
    cubit.addIngredientsToBasket(<MealIngredientModel>[recipeItem()]);
    cubit.toggleFoodSelection(pendingFood);

    await cubit.saveAll(mealType: MealType.kahvalti);

    final List<Map<String, dynamic>> items =
        verify(
              () => repository.logMeal(
                mealType: MealType.kahvalti,
                items: captureAny(named: 'items'),
                date: any(named: 'date'),
              ),
            ).captured.single
            as List<Map<String, dynamic>>;
    expect(items.first.containsKey('foodLocalId'), isFalse);
    expect(items.last['foodLocalId'], 'LF1');
    expect(items.last['foodId'], isNull);
    await cubit.close();
  });
}
