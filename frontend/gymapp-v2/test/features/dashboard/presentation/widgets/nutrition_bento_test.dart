import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/widgets/stat_ring.dart';
import 'package:gymapp_v2/features/dashboard/presentation/widgets/nutrition_bento.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_entry_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_source.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_entry/diet_entry_bloc.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_entry/diet_entry_event.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_entry/diet_entry_state.dart';
import 'package:mocktail/mocktail.dart';

class MockDietEntryBloc extends MockBloc<DietEntryEvent, DietEntryState> implements DietEntryBloc {}

void main() {
  late MockDietEntryBloc mockBloc;

  MealIngredientModel ing({
    required int id,
    required double calories,
    required double protein,
  }) {
    return MealIngredientModel(
      id: id,
      foodId: id,
      foodName: 'Besin $id',
      amount: 100,
      defaultAmount: 100,
      protein: protein,
      carbs: 10,
      fat: 5,
      calories: calories,
      isBrandVerified: false,
      ignoreOverride: false,
      isOverridden: false,
      sugar: 0,
      fiber: 0,
      sodium: 0,
      potassium: 0,
      cholesterol: 0,
    );
  }

  setUp(() {
    mockBloc = MockDietEntryBloc();
  });

  Widget buildWidget(DietEntryState state) {
    when(() => mockBloc.state).thenReturn(state);
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<DietEntryBloc>.value(
          value: mockBloc,
          child: const NutritionBento(),
        ),
      ),
    );
  }

  final plannedMeal = PlannedMealModel(
    mealId: 10,
    mealType: MealType.kahvalti,
    isConsumed: false,
    plannedIngredients: [
      ing(id: 1, calories: 300, protein: 20),
      ing(id: 2, calories: 700, protein: 40),
    ],
  );

  testWidgets('işaretli malzeme kalorisi gösterilir, planlanan toplam sızmaz', (tester) async {
    final state = DietEntryState(
      selectedDate: DateTime(2026, 1, 1),
      mainProgram: DietProgramModel(
        id: 1,
        name: 'Test',
        isMain: true,
        isTemplate: false,
        source: DietSource.client,
        createdAt: DateTime(2026, 1, 1),
        dietDays: const [],
        targetCalories: 2000,
      ),
      log: DailyDietLogModel(
        plannedMeals: [plannedMeal],
        extraEntries: const [],
      ),
      localSelections: const {
        10: {1},
      },
    );

    await tester.pumpWidget(buildWidget(state));

    expect(find.text('300'), findsOneWidget);
    expect(find.text('1000'), findsNothing);
    expect(find.textContaining('Hedef 2000 kcal'), findsOneWidget);
    expect(tester.widget<StatRing>(find.byType(StatRing)).color, AppColors.primary);
  });

  testWidgets('hiçbir şey seçilmediğinde 0 kcal gösterilir', (tester) async {
    final state = DietEntryState(
      selectedDate: DateTime(2026, 1, 1),
      mainProgram: DietProgramModel(
        id: 1,
        name: 'Test',
        isMain: true,
        isTemplate: false,
        source: DietSource.client,
        createdAt: DateTime(2026, 1, 1),
        dietDays: const [],
        targetCalories: 2000,
      ),
      log: DailyDietLogModel(
        plannedMeals: [plannedMeal],
        extraEntries: const [],
      ),
      localSelections: const {},
    );

    await tester.pumpWidget(buildWidget(state));

    expect(find.text('0'), findsOneWidget);
    expect(find.textContaining('Hedef 2000 kcal'), findsOneWidget);
  });

  testWidgets('program hedefi yoksa planlanan toplam hedef sayılır', (tester) async {
    final state = DietEntryState(
      selectedDate: DateTime(2026, 1, 1),
      mainProgram: DietProgramModel(
        id: 1,
        name: 'Test',
        isMain: true,
        isTemplate: false,
        source: DietSource.client,
        createdAt: DateTime(2026, 1, 1),
        dietDays: const [],
        targetCalories: 0,
      ),
      log: DailyDietLogModel(
        plannedMeals: [plannedMeal],
        extraEntries: const [],
      ),
      localSelections: const {
        10: {1},
      },
    );

    await tester.pumpWidget(buildWidget(state));

    expect(find.text('300'), findsOneWidget);
    expect(find.textContaining('Hedef 1000 kcal'), findsOneWidget);
  });

  testWidgets('hedef aşıldığında halka kırmızıya döner', (tester) async {
    final state = DietEntryState(
      selectedDate: DateTime(2026, 1, 1),
      mainProgram: DietProgramModel(
        id: 1,
        name: 'Test',
        isMain: true,
        isTemplate: false,
        source: DietSource.client,
        createdAt: DateTime(2026, 1, 1),
        dietDays: const [],
        targetCalories: 300,
      ),
      log: DailyDietLogModel(
        plannedMeals: [plannedMeal],
        extraEntries: const [],
      ),
      localSelections: const {
        10: {1, 2},
      },
    );

    await tester.pumpWidget(buildWidget(state));

    expect(find.text('1000'), findsOneWidget);
    expect(find.textContaining('Hedef 300 kcal'), findsOneWidget);
    expect(tester.widget<StatRing>(find.byType(StatRing)).color, AppColors.error);
  });
}
