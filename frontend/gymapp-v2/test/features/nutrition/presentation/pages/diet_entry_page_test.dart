import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_entry_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_source.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_entry_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_entry/diet_entry_bloc.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_entry/diet_entry_event.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_entry/diet_entry_state.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/diet_entry_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class MockDietEntryBloc extends MockBloc<DietEntryEvent, DietEntryState> implements DietEntryBloc {}

/// Günlük ekranındaki ekstra besinler (G-83): 11.05.2026'da kaybolan liste, silme ve ekleme geri geldi; kuyrukta
/// bekleyen besin "Bekliyor" işaretiyle görünür ve günlük toplama girer.
void main() {
  late MockDietEntryBloc bloc;
  Object? searchExtra;

  const MealItemModel elma =
      MealItemModel(id: 7, foodId: 9, foodName: 'Elma', amount: 150, calories: 95, protein: 0, carbs: 25, fat: 0);
  const MealItemModel yulaf = MealItemModel(
    id: 0,
    foodId: 5,
    foodName: 'Yulaf',
    amount: 120,
    calories: 450,
    protein: 15,
    carbs: 70,
    fat: 8,
    localId: 'L1',
    queueKey: 'q1',
  );

  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
  });

  setUp(() {
    bloc = MockDietEntryBloc();
    searchExtra = null;
  });

  DietEntryState stateFor(DateTime day) => DietEntryState(
        selectedDate: day,
        status: DietEntryStatus.success,
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
          plannedMeals: [
            PlannedMealModel(mealId: 10, mealType: MealType.kahvalti, isConsumed: false, plannedIngredients: [
              MealIngredientModel(
                id: 1,
                foodId: 1,
                foodName: 'Yumurta',
                amount: 100,
                defaultAmount: 100,
                protein: 13,
                carbs: 1,
                fat: 10,
                calories: 155,
                isBrandVerified: false,
                ignoreOverride: false,
                isOverridden: false,
                sugar: 0,
                fiber: 0,
                sodium: 0,
                potassium: 0,
                cholesterol: 0,
              ),
            ]),
          ],
          extraEntries: [
            MealEntryModel(
              id: 3,
              clientId: 1,
              takenDatetime: day,
              mealType: MealType.kahvalti,
              items: const [elma],
              calories: 95,
            ),
            MealEntryModel(id: 0, clientId: 0, takenDatetime: day, mealType: MealType.kahvalti, items: const [yulaf]),
          ],
        ),
      );

  Future<void> pumpPage(WidgetTester tester, DietEntryState state) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    when(() => bloc.state).thenReturn(state);

    final GoRouter router = GoRouter(routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState s) =>
            BlocProvider<DietEntryBloc>.value(value: bloc, child: const DietEntryPage()),
      ),
      GoRoute(
        path: '/nutrition/search',
        builder: (BuildContext context, GoRouterState s) {
          searchExtra = s.extra;
          return const Scaffold(body: Text('besin arama'));
        },
      ),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
  }

  Finder deleteButtonOf(String foodName) => find.descendant(
        of: find.ancestor(of: find.text(foodName), matching: find.byType(Row)).first,
        matching: find.byTooltip('Sil'),
      );

  testWidgets('ekstra besinler öğün kartında listelenir, bekleyen işaretlidir ve toplama girer', (tester) async {
    await pumpPage(tester, stateFor(DateTime.now()));

    expect(find.text('EKSTRA'), findsOneWidget);
    expect(find.text('Elma'), findsOneWidget);
    expect(find.text('Yulaf'), findsOneWidget);
    expect(find.text('Bekliyor'), findsOneWidget);
    expect(find.descendant(of: find.ancestor(of: find.text('Elma'), matching: find.byType(Row)).first,
        matching: find.text('Bekliyor')), findsNothing);
    // Planlanan işaretlenmedi: toplam = 95 (sunucudaki) + 450 (bekleyen).
    expect(find.text('545'), findsOneWidget);
  });

  testWidgets('silme onay ister; Vazgeç silmez, Sil kalemi silme olayını gönderir', (tester) async {
    await pumpPage(tester, stateFor(DateTime.now()));

    await tester.tap(deleteButtonOf('Yulaf'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Besini sil'), findsOneWidget);

    await tester.tap(find.text('Vazgeç'));
    await tester.pump(const Duration(milliseconds: 300));
    verifyNever(() => bloc.add(const DeleteExtraItem(yulaf)));

    await tester.tap(deleteButtonOf('Yulaf'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Sil')));
    await tester.pump(const Duration(milliseconds: 300));

    verify(() => bloc.add(const DeleteExtraItem(yulaf))).called(1);
    verifyNever(() => bloc.add(const DeleteExtraItem(elma)));
  });

  testWidgets('bugün Ekstra Besin Ekle öğün türüyle besin aramasını açar', (tester) async {
    await pumpPage(tester, stateFor(DateTime.now()));

    await tester.tap(find.text('Ekstra Besin Ekle'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('besin arama'), findsOneWidget);
    expect((searchExtra as Map<String, dynamic>)['mealType'], MealType.kahvalti);
  });

  testWidgets('geçmiş günde Ekstra Besin Ekle görünmez (sepet bugüne yazar)', (tester) async {
    await pumpPage(tester, stateFor(DateTime.now().subtract(const Duration(days: 1))));

    expect(find.text('Ekstra Besin Ekle'), findsNothing);
    expect(find.text('Elma'), findsOneWidget);
  });

  testWidgets('günlük açıkken çıkan hata kullanıcıya gösterilir', (tester) async {
    final DietEntryState state = stateFor(DateTime.now());
    whenListen(
      bloc,
      Stream<DietEntryState>.fromIterable(<DietEntryState>[state.copyWith(error: 'Bu kayıt size ait değil!')]),
      initialState: state,
    );

    await pumpPage(tester, state);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Bu kayıt size ait değil!'), findsOneWidget);
  });
}
