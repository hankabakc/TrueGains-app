import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_source.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_goals/diet_goals_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_goals/diet_goals_state.dart';
import 'package:mocktail/mocktail.dart';

class MockNutritionRepository extends Mock implements NutritionRepository {}

/// Beslenme hedefi ekranı.
///
/// Buradaki sayılar kullanıcının günlük kalori ve makro hedefidir; yanlış
/// kaydedilirse kullanıcı aylarca yanlış hedefe göre beslenir. Ekran iki kipte
/// çalışır (yüzde / gram) ve sunucuya **her zaman gram** gönderilir — bu
/// dönüşüm testlerin asıl konusudur.
void main() {
  late MockNutritionRepository repository;

  DietProgramModel program({
    double calories = 0,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
  }) {
    return DietProgramModel(
      id: 1,
      name: 'Program',
      isMain: true,
      isTemplate: false,
      source: DietSource.client,
      createdAt: DateTime(2026, 1, 1),
      dietDays: const [],
      targetCalories: calories,
      targetProtein: protein,
      targetCarbs: carbs,
      targetFat: fat,
    );
  }

  /// Kaydetme çağrısını yakalar; sunucuya giden gerçek sayıları görebilmek için.
  Map<Symbol, dynamic> captureSave(Invocation invocation) => invocation.namedArguments;

  setUp(() {
    repository = MockNutritionRepository();
  });

  group('kip değiştirme', () {
    test('yüzdeden grama ve geri dönüşte değerler korunur', () {
      final cubit = DietGoalsCubit(repository);
      cubit.initialize(program(calories: 2000, protein: 100, carbs: 250, fat: 67));

      final beforeProtein = cubit.state.protein;
      final beforeCarbs = cubit.state.carbs;
      final beforeFat = cubit.state.fat;

      cubit.toggleMode(); // grama
      cubit.toggleMode(); // yüzdeye

      // Kullanıcı kipi her açıp kapattığında hedefleri kaymamalı.
      expect(cubit.state.protein, closeTo(beforeProtein, 0.001));
      expect(cubit.state.carbs, closeTo(beforeCarbs, 0.001));
      expect(cubit.state.fat, closeTo(beforeFat, 0.001));
    });

    test('gram kipinde makro değişince kalori yeniden hesaplanır', () {
      final cubit = DietGoalsCubit(repository);
      cubit.initialize(program(calories: 2000, protein: 100, carbs: 250, fat: 67));
      cubit.toggleMode(); // gram kipi

      cubit.updateNutrient('protein', 150);

      // 150*4 + karbonhidrat*4 + yağ*9
      final expected =
          (150 * 4) + (cubit.state.carbs * 4) + (cubit.state.fat * 9);
      expect(cubit.state.calories, closeTo(expected, 0.001));
    });
  });

  group('kaydetme', () {
    test('yüzde kipinde sunucuya gram gönderilir', () async {
      final cubit = DietGoalsCubit(repository);
      cubit.initialize(program(calories: 2000, protein: 100, carbs: 250, fat: 67));

      Map<Symbol, dynamic>? sent;
      when(() => repository.updateProgramGoals(any(),
          targetCalories: any(named: 'targetCalories'),
          targetProtein: any(named: 'targetProtein'),
          targetCarbs: any(named: 'targetCarbs'),
          targetFat: any(named: 'targetFat'),
          targetSugar: any(named: 'targetSugar'),
          targetFiber: any(named: 'targetFiber'),
          targetSodium: any(named: 'targetSodium'),
          targetCholesterol: any(named: 'targetCholesterol'),
          targetPotassium: any(named: 'targetPotassium'))).thenAnswer((invocation) async {
        sent = captureSave(invocation);
        return ApiResponse<void>(
            success: true, message: '', data: null, timestamp: '2026-01-01T00:00:00Z');
      });

      await cubit.save(1);

      // 2000 kcal'in %20'si protein = 400 kcal = 100 g
      expect(sent![#targetCalories] as double, closeTo(2000, 0.001));
      expect(sent![#targetProtein] as double, closeTo(100, 0.01));
      expect(sent![#targetCarbs] as double, closeTo(250, 0.01));
      expect(sent![#targetFat] as double, closeTo(67, 0.05));
      expect(cubit.state.status, DietGoalsStatus.success);
    });

    test('makro yüzdeleri 100 etmiyorsa kaydedilmez', () async {
      final cubit = DietGoalsCubit(repository);
      cubit.initialize(program(calories: 2000));
      cubit.updateNutrient('protein', 50); // 50 + 50 + 30 = 130

      await cubit.save(1);

      // Yanlış dağılım sessizce kaydedilirse kullanıcı yanlış hedefe göre beslenir.
      expect(cubit.state.error, 'Toplam makro yüzdesi 100 olmalıdır!');
      verifyNever(() => repository.updateProgramGoals(any(),
          targetCalories: any(named: 'targetCalories'),
          targetProtein: any(named: 'targetProtein'),
          targetCarbs: any(named: 'targetCarbs'),
          targetFat: any(named: 'targetFat'),
          targetSugar: any(named: 'targetSugar'),
          targetFiber: any(named: 'targetFiber'),
          targetSodium: any(named: 'targetSodium'),
          targetCholesterol: any(named: 'targetCholesterol'),
          targetPotassium: any(named: 'targetPotassium')));
    });

    test('yuvarlamadan gelen küçük sapma kabul edilir', () async {
      final cubit = DietGoalsCubit(repository);
      cubit.initialize(program(calories: 2000));
      cubit.updateNutrient('protein', 21); // 21 + 50 + 30 = 101

      when(() => repository.updateProgramGoals(any(),
          targetCalories: any(named: 'targetCalories'),
          targetProtein: any(named: 'targetProtein'),
          targetCarbs: any(named: 'targetCarbs'),
          targetFat: any(named: 'targetFat'),
          targetSugar: any(named: 'targetSugar'),
          targetFiber: any(named: 'targetFiber'),
          targetSodium: any(named: 'targetSodium'),
          targetCholesterol: any(named: 'targetCholesterol'),
          targetPotassium: any(named: 'targetPotassium'))).thenAnswer((_) async =>
          ApiResponse<void>(
              success: true, message: '', data: null, timestamp: '2026-01-01T00:00:00Z'));

      await cubit.save(1);

      // Gramlardan türeyen yüzdeler tam 100 olmayabilir; ±1.5 tolerans bilinçli.
      expect(cubit.state.status, DietGoalsStatus.success);
    });

    test('kalori sıfırsa kaydedilmez', () async {
      final cubit = DietGoalsCubit(repository);
      cubit.initialize(program(calories: 2000));
      cubit.updateNutrient('calories', 0);

      await cubit.save(1);

      expect(cubit.state.error, "Kalori hedefi 0'dan büyük olmalıdır.");
      expect(cubit.state.status, isNot(DietGoalsStatus.success));
    });
  });

  group('hazır hedef', () {
    test('yüzde kipinde 20/50/30 dağılımı uygulanır', () {
      final cubit = DietGoalsCubit(repository);
      cubit.initialize(program(calories: 2000));

      cubit.applySmartGoal(2500);

      expect(cubit.state.calories, 2500);
      expect(cubit.state.protein, 20);
      expect(cubit.state.carbs, 50);
      expect(cubit.state.fat, 30);
    });

    test('gram kipinde aynı dağılımın gram karşılığı uygulanır', () {
      final cubit = DietGoalsCubit(repository);
      cubit.initialize(program(calories: 2000));
      cubit.toggleMode();

      cubit.applySmartGoal(2000);

      // İki kip aynı dağılımı vermeli: %20 protein = 400 kcal = 100 g
      expect(cubit.state.protein, closeTo(100, 0.001));
      expect(cubit.state.carbs, closeTo(250, 0.001));
      expect(cubit.state.fat, closeTo(66.67, 0.01));
    });
  });

  group('program yükleme', () {
    test('kayıtlı gram hedefleri yüzdeye çevrilir', () {
      final cubit = DietGoalsCubit(repository);

      cubit.initialize(program(calories: 2000, protein: 100, carbs: 250, fat: 67));

      expect(cubit.state.protein, closeTo(20, 0.01));
      expect(cubit.state.carbs, closeTo(50, 0.01));
      expect(cubit.state.fat, closeTo(30.15, 0.01));
    });

    test('hedefi olmayan programda varsayılan dağılım kullanılır', () {
      final cubit = DietGoalsCubit(repository);

      cubit.initialize(program());

      expect(cubit.state.calories, 2000);
      expect(cubit.state.protein, 20);
      expect(cubit.state.carbs, 50);
      expect(cubit.state.fat, 30);
    });
  });
}
