import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/features/nutrition/data/models/nutrition_dashboard_model.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/nutrition_analytics/nutrition_analytics_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockNutritionRepository extends Mock implements NutritionRepository {}

/// Beslenme panosu.
///
/// Pano, kullanıcının günlük/haftalık kalori ve makro sayılarını gösterir.
/// Sunucu tarafında bu uç bu oturumda sertleştirildi (başkasının programId'si
/// artık yok sayılıyor); burada istemcinin o kimlikleri doğru ilettiği ve hata
/// hâlinde kullanıcıyı sonsuz yükleme ekranında bırakmadığı doğrulanır.
void main() {
  late MockNutritionRepository repository;

  NutritionDashboardModel dashboard({bool hasProgram = true}) {
    return NutritionDashboardModel(
      dailySummary: const DailySummaryModel(
        calories: 1800,
        protein: 90,
        carbs: 200,
        fat: 60,
        sugar: 30,
        fiber: 25,
        sodium: 2000,
        cholesterol: 200,
        potassium: 3000,
        mealBreakdown: [],
        dailyFoods: [],
      ),
      weeklySummary: const WeeklySummaryModel(
        dailyLogs: [],
        totalCalories: 12600,
        totalProtein: 630,
        totalCarbs: 1400,
        totalFat: 420,
        targetCalories: 14000,
        targetProtein: 700,
        targetCarbs: 1750,
        targetFat: 467,
        targetSugar: 0,
        targetFiber: 0,
        targetSodium: 0,
        targetCholesterol: 0,
        targetPotassium: 0,
      ),
      frequentFoods: const [],
      nutrientAnalysis: const [],
      hasActiveProgram: hasProgram,
    );
  }

  ApiResponse<T> ok<T>(T? data) =>
      ApiResponse<T>(success: true, message: '', data: data, timestamp: '2026-01-01T00:00:00Z');

  setUp(() {
    repository = MockNutritionRepository();
  });

  group('pano verisi', () {
    blocTest<NutritionAnalyticsBloc, NutritionAnalyticsState>(
      'program ve sporcu kimlikleri sunucuya olduğu gibi iletilir',
      build: () {
        when(() => repository.getDashboardData(any(), any()))
            .thenAnswer((_) async => ok(dashboard()));
        return NutritionAnalyticsBloc(repository);
      },
      act: (bloc) => bloc.add(const FetchDashboardData(programId: 7, targetUserId: 50)),
      verify: (_) {
        // Yanlış kimlik gönderilirse kullanıcı başkasının değil, hiç kimsenin
        // verisini görür: sunucu sahibi tutmayan programId'yi yok sayıyor.
        verify(() => repository.getDashboardData(7, 50)).called(1);
      },
    );

    blocTest<NutritionAnalyticsBloc, NutritionAnalyticsState>(
      'başarılı yanıtta pano verisi yayınlanır',
      build: () {
        when(() => repository.getDashboardData(any(), any()))
            .thenAnswer((_) async => ok(dashboard()));
        return NutritionAnalyticsBloc(repository);
      },
      act: (bloc) => bloc.add(const FetchDashboardData()),
      expect: () => [
        isA<NutritionAnalyticsLoading>(),
        isA<NutritionAnalyticsLoaded>(),
      ],
    );

    blocTest<NutritionAnalyticsBloc, NutritionAnalyticsState>(
      'hata durumunda kullanıcı yükleme ekranında bırakılmaz',
      build: () {
        when(() => repository.getDashboardData(any(), any())).thenAnswer(
          (_) async => ApiResponse<NutritionDashboardModel>(
            success: false,
            message: 'Sunucuya ulaşılamadı',
            data: null,
            timestamp: '2026-01-01T00:00:00Z',
          ),
        );
        return NutritionAnalyticsBloc(repository);
      },
      act: (bloc) => bloc.add(const FetchDashboardData()),
      expect: () => [
        isA<NutritionAnalyticsLoading>(),
        isA<NutritionAnalyticsError>(),
      ],
    );

    blocTest<NutritionAnalyticsBloc, NutritionAnalyticsState>(
      'veri gelmeden başarı bildirilirse hata gösterilir',
      build: () {
        // Sunucu başarı deyip boş gövde döndürürse `data!` fırlatır ve hiçbir
        // durum yayınlanmaz; ekran sonsuza kadar yükleniyor kalırdı.
        when(() => repository.getDashboardData(any(), any()))
            .thenAnswer((_) async => ok<NutritionDashboardModel>(null));
        return NutritionAnalyticsBloc(repository);
      },
      act: (bloc) => bloc.add(const FetchDashboardData()),
      expect: () => [
        isA<NutritionAnalyticsLoading>(),
        isA<NutritionAnalyticsError>(),
      ],
    );
  });

  group('görünüm anahtarları', () {
    blocTest<NutritionAnalyticsBloc, NutritionAnalyticsState>(
      'yüzde görünümüne geçmek veriyi yeniden çekmez',
      build: () {
        when(() => repository.getDashboardData(any(), any()))
            .thenAnswer((_) async => ok(dashboard()));
        return NutritionAnalyticsBloc(repository);
      },
      act: (bloc) async {
        bloc.add(const FetchDashboardData());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ToggleDashboardView(true));
      },
      verify: (bloc) {
        // Anahtar sadece görünümü değiştirir; ağ isteği tekrarlanmamalı ve
        // ekrandaki sayılar kaybolmamalı.
        verify(() => repository.getDashboardData(any(), any())).called(1);
        final state = bloc.state as NutritionAnalyticsLoaded;
        expect(state.isPercentageView, isTrue);
        expect(state.dashboardData.dailySummary.calories, 1800);
      },
    );

    blocTest<NutritionAnalyticsBloc, NutritionAnalyticsState>(
      'veri yüklenmeden gelen anahtar olayı durumu bozmaz',
      build: () => NutritionAnalyticsBloc(repository),
      act: (bloc) => bloc.add(const ToggleDashboardView(true)),
      expect: () => <NutritionAnalyticsState>[],
    );
  });
}
