import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_entry_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_entry_model.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_entry/diet_entry_bloc.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_entry/diet_entry_event.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_entry/diet_entry_state.dart';
import 'package:mocktail/mocktail.dart';

class MockNutritionRepository extends Mock implements NutritionRepository {}

/// Öğün işaretleme "iyimser güncelleme" (optimistic update) ile çalışır: arayüz önce
/// hemen güncellenir, sonra backend'e yazılır. Backend reddederse **geri alınmalıdır**;
/// alınmazsa kullanıcı yediğini işaretlediğini sanır ama kayıt sunucuda yoktur ve
/// günlük makro toplamı yanlış kalır.
void main() {
  late MockNutritionRepository repository;

  ApiResponse<T> ok<T>() => ApiResponse<T>(
        success: true,
        message: 'Başarılı',
        timestamp: '2026-01-01T00:00:00Z',
      );

  ApiResponse<T> fail<T>(String message) => ApiResponse<T>(
        success: false,
        message: message,
        timestamp: '2026-01-01T00:00:00Z',
      );

  void stubToggle(ApiResponse<MealEntryModel> response) {
    when(() => repository.togglePlannedMeal(
          date: any(named: 'date'),
          mealId: any(named: 'mealId'),
          consumed: any(named: 'consumed'),
          ingredientIds: any(named: 'ingredientIds'),
        )).thenAnswer((_) async => response);
  }

  setUp(() {
    repository = MockNutritionRepository();
    // Başarılı toggle sonrası bloc günlük logu yeniden çeker. Burada bilinçli olarak
    // başarısız döndürülüyor: böylece sunucudan gelen veri iyimser seçimin üzerine
    // yazmıyor ve testler tam olarak toggle mantığını ölçüyor.
    when(() => repository.getDailyDietLog(any()))
        .thenAnswer((_) async => fail<DailyDietLogModel>('stub: log yüklenmedi'));
  });

  DietEntryBloc buildBloc() => DietEntryBloc(repository);

  group('Malzeme işaretleme — iyimser güncelleme', () {
    blocTest<DietEntryBloc, DietEntryState>(
      'malzeme işaretlendiğinde → yerel seçim güncellenir ve backend consumed:true ile çağrılır',
      build: () {
        stubToggle(ok<MealEntryModel>());
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ToggleIngredient(5, 42)),
      verify: (bloc) {
        expect(bloc.state.localSelections[5], contains(42));
        verify(() => repository.togglePlannedMeal(
              date: any(named: 'date'),
              mealId: 5,
              consumed: true,
              ingredientIds: [42],
            )).called(1);
      },
    );

    blocTest<DietEntryBloc, DietEntryState>(
      'işaretli tek malzeme kaldırıldığında → backend consumed:false ile çağrılır',
      build: () {
        stubToggle(ok<MealEntryModel>());
        return buildBloc();
      },
      act: (bloc) {
        bloc.add(const ToggleIngredient(5, 42));
        bloc.add(const ToggleIngredient(5, 42));
      },
      verify: (bloc) {
        // Öğün tamamen boşaldı: tüketilmedi olarak işaretlenmeli.
        expect(bloc.state.localSelections[5], isEmpty);
        verify(() => repository.togglePlannedMeal(
              date: any(named: 'date'),
              mealId: 5,
              consumed: false,
            )).called(1);
      },
    );

    blocTest<DietEntryBloc, DietEntryState>(
      'backend isteği reddettiğinde → yerel seçim GERİ ALINIR ve hata gösterilir',
      build: () {
        stubToggle(fail<MealEntryModel>('Sunucuya ulaşılamadı.'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ToggleIngredient(5, 42)),
      verify: (bloc) {
        // Geri alma olmazsa arayüz "yendi" gösterir ama sunucuda kayıt yoktur.
        expect(bloc.state.localSelections[5] ?? <int>{}, isEmpty);
        expect(bloc.state.error, 'Sunucuya ulaşılamadı.');
      },
    );

    blocTest<DietEntryBloc, DietEntryState>(
      'ikinci malzeme eklendiğinde → önceki seçim korunur ve ikisi birlikte gönderilir',
      build: () {
        stubToggle(ok<MealEntryModel>());
        return buildBloc();
      },
      act: (bloc) {
        bloc.add(const ToggleIngredient(5, 42));
        bloc.add(const ToggleIngredient(5, 43));
      },
      verify: (bloc) {
        expect(bloc.state.localSelections[5], containsAll(<int>[42, 43]));
        verify(() => repository.togglePlannedMeal(
              date: any(named: 'date'),
              mealId: 5,
              consumed: true,
              ingredientIds: [42, 43],
            )).called(1);
      },
    );

    blocTest<DietEntryBloc, DietEntryState>(
      'başarısız istek sonrası → yalnızca ilgili öğün geri alınır, diğer öğün etkilenmez',
      build: () {
        when(() => repository.togglePlannedMeal(
              date: any(named: 'date'),
              mealId: 5,
              consumed: any(named: 'consumed'),
              ingredientIds: any(named: 'ingredientIds'),
            )).thenAnswer((_) async => ok<MealEntryModel>());
        when(() => repository.togglePlannedMeal(
              date: any(named: 'date'),
              mealId: 9,
              consumed: any(named: 'consumed'),
              ingredientIds: any(named: 'ingredientIds'),
            )).thenAnswer((_) async => fail<MealEntryModel>('Hata'));
        return buildBloc();
      },
      act: (bloc) {
        bloc.add(const ToggleIngredient(5, 42));
        bloc.add(const ToggleIngredient(9, 77));
      },
      verify: (bloc) {
        // Başarılı öğün korunmalı, başarısız olan geri alınmalı.
        expect(bloc.state.localSelections[5], contains(42));
        expect(bloc.state.localSelections[9] ?? <int>{}, isEmpty);
      },
    );
  });

  group('İlk yükleme — tarih bugüne çekilir', () {
    blocTest<DietEntryBloc, DietEntryState>(
      'farklı bir tarih seçiliyken InitializeDietEntry tetiklendiğinde → selectedDate bugüne döner',
      build: () {
        when(() => repository.getMainProgram())
            .thenAnswer((_) async => fail<DietProgramModel>('stub: program yok'));
        return buildBloc();
      },
      seed: () => DietEntryState(selectedDate: DateTime(2020, 1, 1)),
      act: (bloc) => bloc.add(const InitializeDietEntry()),
      verify: (bloc) {
        final now = DateTime.now();
        expect(bloc.state.selectedDate.year, equals(now.year));
        expect(bloc.state.selectedDate.month, equals(now.month));
        expect(bloc.state.selectedDate.day, equals(now.day));
      },
    );

    blocTest<DietEntryBloc, DietEntryState>(
      'init sürerken kullanıcı tarihi değiştirirse → kullanıcının seçimi korunur',
      build: () {
        when(() => repository.getMainProgram()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return fail<DietProgramModel>('stub: program yok');
        });
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const InitializeDietEntry());
        await Future<void>.delayed(const Duration(milliseconds: 5));
        bloc.add(ChangeDate(DateTime(2020, 1, 5)));
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) => expect(bloc.state.selectedDate, DateTime(2020, 1, 5)),
    );

    blocTest<DietEntryBloc, DietEntryState>(
      'başka güne geçildikten sonra dönen log yanıtı state e yazılmaz',
      build: () {
        when(() => repository.getDailyDietLog(DateTime(2020, 1, 1))).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return ApiResponse<DailyDietLogModel>(
            success: true,
            message: 'Başarılı',
            timestamp: '2026-01-01T00:00:00Z',
            data: const DailyDietLogModel(plannedMeals: [], extraEntries: []),
          );
        });
        when(() => repository.getDailyDietLog(DateTime(2020, 1, 2)))
            .thenAnswer((_) async => fail<DailyDietLogModel>('stub: log yok'));
        return buildBloc();
      },
      seed: () => DietEntryState(selectedDate: DateTime(2020, 1, 1)),
      act: (bloc) async {
        bloc.add(LoadDailyLog(DateTime(2020, 1, 1)));
        await Future<void>.delayed(const Duration(milliseconds: 5));
        bloc.add(ChangeDate(DateTime(2020, 1, 2)));
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) => expect(bloc.state.log, isNull,
          reason: '1 Ocak yanıtı 2 Ocak ekranına yazılmamalı'),
    );
  });
}
