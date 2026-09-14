import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/features/nutrition/data/models/water_intake_model.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/water/water_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockNutritionRepository extends Mock implements NutritionRepository {}

void main() {
  late MockNutritionRepository repository;

  ApiResponse<T> ok<T>(T? data) => ApiResponse<T>(
        success: true,
        message: 'Başarılı',
        data: data,
        timestamp: '2026-01-01T00:00:00Z',
      );

  ApiResponse<T> fail<T>(String message) => ApiResponse<T>(
        success: false,
        message: message,
        timestamp: '2026-01-01T00:00:00Z',
      );

  final sampleSummary = WaterDailySummaryModel(
    totalIntakeMl: 1500,
    targetMl: 2500,
    intakes: [
      WaterIntakeModel(
        id: 1,
        amountMl: 500,
        date: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1, 10, 0),
      ),
    ],
    customGlasses: const [
      CustomGlassModel(
        id: 7,
        name: 'Kupa',
        sizeMl: 350,
      ),
    ],
  );

  final sampleIntake = WaterIntakeModel(
    id: 1,
    amountMl: 250,
    date: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1, 10, 0),
  );

  final sampleHistory = [
    WaterDailyTotalModel(
      date: DateTime(2026, 1, 1),
      totalIntakeMl: 1500,
      targetMl: 2500,
    ),
    WaterDailyTotalModel(
      date: DateTime(2026, 1, 2),
      totalIntakeMl: 2000,
      targetMl: 2500,
    ),
  ];

  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  setUp(() {
    repository = MockNutritionRepository();
  });

  WaterBloc buildBloc() => WaterBloc(repository);

  group('WaterBloc', () {
    blocTest<WaterBloc, WaterState>(
      'özet ve geçmiş birlikte yükleniyor',
      build: () {
        when(() => repository.getDailyWaterSummary(any()))
            .thenAnswer((_) async => ok<WaterDailySummaryModel>(sampleSummary));
        when(() => repository.getWaterRangeSummary(any(), any()))
            .thenAnswer((_) async => ok<List<WaterDailyTotalModel>>(sampleHistory));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadWaterSummary()),
      expect: () => [
        WaterLoading(),
        WaterLoaded(sampleSummary, history: sampleHistory),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<WaterLoaded>());
        final state = bloc.state as WaterLoaded;
        expect(state.summary, sampleSummary);
        expect(state.history, hasLength(2));
      },
    );

    blocTest<WaterBloc, WaterState>(
      'geçmiş çekilemezse ekran yine doluyor',
      build: () {
        when(() => repository.getDailyWaterSummary(any()))
            .thenAnswer((_) async => ok<WaterDailySummaryModel>(sampleSummary));
        when(() => repository.getWaterRangeSummary(any(), any()))
            .thenAnswer((_) async => fail<List<WaterDailyTotalModel>>('Geçmiş alınamadı'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadWaterSummary()),
      expect: () => [
        WaterLoading(),
        WaterLoaded(sampleSummary, history: const []),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<WaterLoaded>());
        final state = bloc.state as WaterLoaded;
        expect(state.summary, sampleSummary);
        expect(state.history, isEmpty);
      },
    );

    blocTest<WaterBloc, WaterState>(
      'su eklenince özet yeniden çekiliyor',
      build: () {
        when(() => repository.addWater(250))
            .thenAnswer((_) async => ok<WaterIntakeModel>(sampleIntake));
        when(() => repository.getDailyWaterSummary(any()))
            .thenAnswer((_) async => ok<WaterDailySummaryModel>(sampleSummary));
        when(() => repository.getWaterRangeSummary(any(), any()))
            .thenAnswer((_) async => ok<List<WaterDailyTotalModel>>(sampleHistory));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AddWaterIntake(250)),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        verify(() => repository.addWater(250)).called(1);
        verify(() => repository.getDailyWaterSummary(any())).called(1);
      },
    );

    blocTest<WaterBloc, WaterState>(
      'yazma başarısızsa ekrandaki veri korunuyor',
      seed: () => WaterLoaded(sampleSummary, history: sampleHistory),
      build: () {
        when(() => repository.addWater(250))
            .thenAnswer((_) async => fail<WaterIntakeModel>('Bağlantı hatası'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AddWaterIntake(250)),
      expect: () => [
        const WaterError('Bağlantı hatası'),
        WaterLoaded(sampleSummary, history: sampleHistory),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<WaterLoaded>());
        final state = bloc.state as WaterLoaded;
        expect(state.summary, sampleSummary);
      },
    );

    blocTest<WaterBloc, WaterState>(
      'reddedilen yazma sonrası tazeleme yapılmıyor',
      seed: () => WaterLoaded(sampleSummary, history: sampleHistory),
      build: () {
        when(() => repository.addWater(250))
            .thenAnswer((_) async => fail<WaterIntakeModel>('Bağlantı hatası'));
        return buildBloc();
      },
      act: (bloc) {
        clearInteractions(repository);
        bloc.add(const AddWaterIntake(250));
      },
      verify: (bloc) {
        verify(() => repository.addWater(250)).called(1);
        verifyNever(() => repository.getDailyWaterSummary(any()));
      },
    );

    blocTest<WaterBloc, WaterState>(
      'özel bardak silinince özet yeniden çekiliyor',
      build: () {
        when(() => repository.deleteCustomGlass(7))
            .thenAnswer((_) async => ok<void>(null));
        when(() => repository.getDailyWaterSummary(any()))
            .thenAnswer((_) async => ok<WaterDailySummaryModel>(sampleSummary));
        when(() => repository.getWaterRangeSummary(any(), any()))
            .thenAnswer((_) async => ok<List<WaterDailyTotalModel>>(sampleHistory));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const DeleteCustomGlass(7)),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        verify(() => repository.deleteCustomGlass(7)).called(1);
        verify(() => repository.getDailyWaterSummary(any())).called(1);
      },
    );
  });
}
