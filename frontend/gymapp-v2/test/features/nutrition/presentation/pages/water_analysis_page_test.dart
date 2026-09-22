import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:gymapp_v2/features/nutrition/data/models/water_intake_model.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/water/water_bloc.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/water_analysis/water_analysis_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/pages/water_analysis_page.dart';
import 'package:mocktail/mocktail.dart';

class MockWaterBloc extends MockBloc<WaterEvent, WaterState> implements WaterBloc {}

/// Bugünkü su kayıtları (G-86): kuyrukta bekleyen kayıt işaretlidir; silinince sunucuya silme gitmez, kuyruktan çıkar.
void main() {
  late MockWaterBloc bloc;

  final WaterLoaded state = WaterLoaded(
    WaterDailySummaryModel(
      totalIntakeMl: 550,
      targetMl: 3000,
      intakes: <WaterIntakeModel>[
        WaterIntakeModel(id: 10, amountMl: 300, date: DateTime(2026, 9, 18), createdAt: DateTime(2026, 9, 18, 9)),
        WaterIntakeModel(
          id: 0,
          amountMl: 250,
          date: DateTime(2026, 9, 18),
          createdAt: DateTime(2026, 9, 18, 10, 15),
          queueKey: 'q1',
        ),
      ],
      customGlasses: const <CustomGlassModel>[],
    ),
  );

  setUp(() {
    bloc = MockWaterBloc();
    GetIt.instance.registerFactory<WaterAnalysisCubit>(() => WaterAnalysisCubit());
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    when(() => bloc.state).thenReturn(state);
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<WaterBloc>.value(value: bloc, child: WaterAnalysisPage(state: state)),
    ));
    await tester.pump();
  }

  Finder logRow(String amount) => find.ancestor(of: find.text(amount), matching: find.byType(Row)).first;

  Future<void> deleteAndConfirm(WidgetTester tester, String amount) async {
    await tester.tap(find.descendant(of: logRow(amount), matching: find.byTooltip('Sil')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('SİL'));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('kuyrukta bekleyen su kaydı işaretlidir, sunucudaki değildir', (tester) async {
    await pumpPage(tester);

    expect(find.descendant(of: logRow('250 ml'), matching: find.text('Bekliyor')), findsOneWidget);
    expect(find.descendant(of: logRow('300 ml'), matching: find.text('Bekliyor')), findsNothing);
  });

  testWidgets('bekleyen kayıt silinince kuyruktan çıkar, sunucuya silme gitmez', (tester) async {
    await pumpPage(tester);

    await deleteAndConfirm(tester, '250 ml');

    verify(() => bloc.add(const DiscardPendingWaterIntake('q1'))).called(1);
    verifyNever(() => bloc.add(const DeleteWaterIntake(0)));
  });

  testWidgets('sunucudaki kayıt silinince kimliğiyle silme gider', (tester) async {
    await pumpPage(tester);

    await deleteAndConfirm(tester, '300 ml');

    verify(() => bloc.add(const DeleteWaterIntake(10))).called(1);
  });
}
