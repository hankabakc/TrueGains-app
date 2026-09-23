import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_history_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/recipe_model.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/food_search/food_search_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/food_search_page.dart';
import 'package:mocktail/mocktail.dart';

class MockNutritionRepository extends Mock implements NutritionRepository {}

/// Manuel eklediklerim (G-87): internetsiz oluşturulan özel besin "BEKLİYOR" işaretlidir; sunucu kimliği olmadığı için
/// ayrıntı düğmesi yoktur.
void main() {
  late MockNutritionRepository repository;

  ApiResponse<T> ok<T>(T data) => ApiResponse<T>(success: true, message: '', timestamp: '', data: data);

  const FoodModel pending = FoodModel(
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
  const FoodModel saved = FoodModel(
    id: 5,
    name: 'Kefir',
    defaultUnit: 'ml',
    defaultAmount: 100,
    calories: 50,
    protein: 3,
    carbs: 4,
    fat: 2,
    isCustom: true,
  );

  setUp(() {
    repository = MockNutritionRepository();
    when(() => repository.getRecentGroupedFoods()).thenAnswer((_) async => ok<List<MealHistoryModel>>(const []));
    when(() => repository.getTemplates()).thenAnswer((_) async => ok<List<MealTemplateModel>>(const []));
    when(() => repository.getOverriddenFoods()).thenAnswer((_) async => ok<List<FoodModel>>(const []));
    when(() => repository.getRecipes()).thenAnswer((_) async => ok<List<RecipeModel>>(const []));
    when(() => repository.getMyCustomFoods()).thenAnswer((_) async => ok<List<FoodModel>>(const [pending, saved]));
    GetIt.instance.registerFactory<FoodSearchCubit>(() => FoodSearchCubit(repository));
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Finder tileOf(String name) => find.ancestor(of: find.text(name), matching: find.byType(ListTile));

  testWidgets('bekleyen özel besin işaretlidir ve ayrıntı düğmesi yoktur; kayıtlı olanda vardır', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: FoodSearchPage(mealType: MealType.kahvalti)));
    await tester.pump();
    await tester.tap(find.text('DÜZENLENENLER'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.descendant(of: tileOf('Ev yoğurdu'), matching: find.text('BEKLİYOR')), findsOneWidget);
    expect(find.descendant(of: tileOf('Ev yoğurdu'), matching: find.byIcon(Icons.info_outline_rounded)), findsNothing);
    expect(find.descendant(of: tileOf('Kefir'), matching: find.text('MANUEL')), findsOneWidget);
    expect(find.descendant(of: tileOf('Kefir'), matching: find.byIcon(Icons.info_outline_rounded)), findsOneWidget);
  });
}
