import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
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
}
