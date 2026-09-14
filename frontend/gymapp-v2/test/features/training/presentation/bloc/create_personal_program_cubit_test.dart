import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/features/training/models/exercise.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/create_program/create_personal_program_cubit.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/create_program/create_personal_program_state.dart';
import 'package:gymapp_v2/features/training/repository/training_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockTrainingRepository extends Mock implements TrainingRepository {}

class _FakeTrainingBlock extends Fake implements TrainingBlock {}

ApiResponse<T> ok<T>(T? data) =>
    ApiResponse<T>(success: true, message: '', data: data, timestamp: '2026-01-01T00:00:00Z');

ApiResponse<T> fail<T>(String message) =>
    ApiResponse<T>(success: false, message: message, data: null, timestamp: '2026-01-01T00:00:00Z');

/// Program oluşturma ekranının veri davranışı.
///
/// Bu ekranda kullanıcı 7 günü, günlerin egzersizlerini ve sıralamalarını
/// dakikalarca düzenler. Buradaki en pahalı hata **emeğin kaybolmasıdır**:
/// kaydetme başarısız olduğunda taslak durmalı, gün sıralaması değiştiğinde
/// günlerle bayrakları birbirinden ayrılmamalıdır.
void main() {
  late MockTrainingRepository repository;

  WorkoutExercise exercise(int id, {int order = 0, MuscleGroup? group}) {
    return WorkoutExercise(
      id: id,
      exerciseId: id,
      exerciseName: 'Egzersiz $id',
      targetSets: 3,
      targetReps: '10',
      orderIndex: order,
      logs: const [],
      muscleGroup: group,
    );
  }

  setUpAll(() {
    registerFallbackValue(_FakeTrainingBlock());
  });

  setUp(() {
    repository = MockTrainingRepository();
    when(() => repository.getAllExercises()).thenAnswer((_) async => ok(<Exercise>[]));
  });

  Future<CreatePersonalProgramCubit> newCubit() async {
    final cubit = CreatePersonalProgramCubit(repository: repository);
    await Future<void>.delayed(Duration.zero);
    return cubit;
  }

  group('kaydetme', () {
    test('başarısız olduğunda taslak silinmez', () async {
      final cubit = await newCubit();
      cubit.addExercises(0, [exercise(1), exercise(2)]);

      when(() => repository.createPersonalProgram(any()))
          .thenAnswer((_) async => fail<TrainingBlock>('Sunucuya ulaşılamadı'));

      await cubit.saveProgram('Program A');

      // Kullanıcı dakikalarca program kurdu; hata ekranı emeğini silmemeli.
      expect(cubit.state.status, CreatePersonalProgramStatus.failure);
      expect(cubit.state.draftDays[0].exercises, hasLength(2));
      expect(cubit.state.error, 'Sunucuya ulaşılamadı');
      await cubit.close();
    });

    test('dinlenme günü işaretlenmişse o gün sunucuya boş gider', () async {
      final cubit = await newCubit();
      cubit.addExercises(1, [exercise(1)]);
      cubit.toggleOffDay(1);

      TrainingBlock? sent;
      when(() => repository.createPersonalProgram(any())).thenAnswer((invocation) async {
        sent = invocation.positionalArguments.first as TrainingBlock;
        return ok<TrainingBlock>(null);
      });

      await cubit.saveProgram('Program A');

      expect(sent!.workoutDays[1].exercises, isEmpty);
      // Taslakta durmalı: kullanıcı fikrini değiştirip işareti kaldırabilir.
      expect(cubit.state.draftDays[1].exercises, hasLength(1));
      await cubit.close();
    });
  });

  group('gün sıralaması', () {
    test('günler taşınınca dinlenme ve mıknatıs bayrakları da taşınır', () async {
      final cubit = await newCubit();
      cubit.addExercises(0, [exercise(1)]);
      cubit.toggleOffDay(2); // Çarşamba dinlenme günü

      cubit.reorderDays(2, 0); // Çarşamba'yı en başa al

      // Bayraklar günlerle birlikte taşınmazsa yanlış günün egzersizleri
      // kaydetme sırasında silinir.
      expect(cubit.state.draftDays[0].name, 'Çarşamba');
      expect(cubit.state.isOffDays[0], isTrue);
      expect(cubit.state.isOffDays[1], isFalse);
      await cubit.close();
    });

    test('taşınan günün egzersizleri kendisiyle gelir', () async {
      final cubit = await newCubit();
      cubit.addExercises(3, [exercise(7)]);

      cubit.reorderDays(3, 0);

      expect(cubit.state.draftDays[0].exercises.single.exerciseId, 7);
      await cubit.close();
    });

    test('gün aşağı taşınınca istenen yere oturur', () async {
      final cubit = await newCubit();
      cubit.addExercises(0, [exercise(1)]);
      cubit.reorderDays(0, 2);
      expect(cubit.state.draftDays[2].exercises.single.exerciseId, 1);
      expect(cubit.state.draftDays.map((d) => d.dayOrder).toList(), [1, 2, 3, 4, 5, 6, 7]);
      expect(cubit.state.selectedDayIndex, 2);
      await cubit.close();
    });
  });

  group('egzersiz sıralaması', () {
    test('egzersiz aşağı taşınınca istenen yere oturur', () async {
      final cubit = await newCubit();
      cubit.addExercises(0, [exercise(1), exercise(2), exercise(3)]);
      final ids = cubit.state.draftDays[0].exercises.map((e) => e.exerciseId).toList();

      cubit.reorderExercises(0, 0, 2);

      final newIds = cubit.state.draftDays[0].exercises.map((e) => e.exerciseId).toList();
      expect(newIds, [ids[1], ids[2], ids[0]]);
      final orders = cubit.state.draftDays[0].exercises.map((e) => e.orderIndex).toList();
      expect(orders, [0, 1, 2]);
      await cubit.close();
    });

    test('kas grubu aşağı taşınınca istenen yere oturur', () async {
      final cubit = await newCubit();
      cubit.addExercises(0, [
        exercise(1, group: MuscleGroup.CHEST),
        exercise(2, group: MuscleGroup.BACK),
        exercise(3, group: MuscleGroup.SHOULDERS),
      ]);
      final names = cubit.state.draftDays[0].exercises.map((e) => e.muscleGroup!.turkishName).toList();

      cubit.reorderMuscleGroups(0, 0, 2);

      final newNames = cubit.state.draftDays[0].exercises.map((e) => e.muscleGroup!.turkishName).toList();
      expect(newNames, [names[1], names[2], names[0]]);
      await cubit.close();
    });

    test('grup içinde aşağı taşıma istenen yere oturur', () async {
      final cubit = await newCubit();
      cubit.addExercises(0, [
        exercise(1, group: MuscleGroup.CHEST),
        exercise(2, group: MuscleGroup.CHEST),
        exercise(3, group: MuscleGroup.CHEST),
      ]);
      final ids = cubit.state.draftDays[0].exercises.map((e) => e.exerciseId).toList();

      cubit.reorderExerciseInGroup(0, 'Göğüs', 0, 1);
      expect(
        cubit.state.draftDays[0].exercises.map((e) => e.exerciseId).toList(),
        [ids[1], ids[0], ids[2]],
      );

      cubit.reorderExerciseInGroup(0, 'Göğüs', 0, 2);
      expect(
        cubit.state.draftDays[0].exercises.map((e) => e.exerciseId).toList(),
        [ids[0], ids[2], ids[1]],
      );
      await cubit.close();
    });

    test('grup içi taşıma diğer grubun egzersizlerine dokunmaz', () async {
      final cubit = await newCubit();
      cubit.addExercises(0, [
        exercise(1, group: MuscleGroup.CHEST),
        exercise(2, group: MuscleGroup.CHEST),
        exercise(3, group: MuscleGroup.BACK),
      ]);
      final chest = cubit.state.draftDays[0].exercises
          .where((e) => e.muscleGroup == MuscleGroup.CHEST)
          .map((e) => e.exerciseId)
          .toList();
      final back = cubit.state.draftDays[0].exercises
          .where((e) => e.muscleGroup == MuscleGroup.BACK)
          .map((e) => e.exerciseId)
          .toList();

      cubit.reorderExerciseInGroup(0, 'Göğüs', 0, 1);

      final newChest = cubit.state.draftDays[0].exercises
          .where((e) => e.muscleGroup == MuscleGroup.CHEST)
          .map((e) => e.exerciseId)
          .toList();
      final newBack = cubit.state.draftDays[0].exercises
          .where((e) => e.muscleGroup == MuscleGroup.BACK)
          .map((e) => e.exerciseId)
          .toList();

      expect(newChest, [chest[1], chest[0]]);
      expect(newBack, [back[0]]);
      expect(cubit.state.draftDays[0].exercises, hasLength(3));
      await cubit.close();
    });
  });

  group('egzersiz düzenleme', () {
    test('eklenen egzersizler sıra numarası alır', () async {
      final cubit = await newCubit();
      cubit.addExercises(0, [exercise(1), exercise(2)]);
      cubit.addExercises(0, [exercise(3)]);

      final orders = cubit.state.draftDays[0].exercises.map((e) => e.orderIndex).toList();
      expect(orders, [0, 1, 2]);
      await cubit.close();
    });

    test('bir egzersiz silinince diğerleri kalır', () async {
      final cubit = await newCubit();
      cubit.addExercises(0, [exercise(1), exercise(2), exercise(3)]);

      cubit.deleteExercise(0, 1);

      final ids = cubit.state.draftDays[0].exercises.map((e) => e.exerciseId).toList();
      expect(ids, [1, 3]);
      await cubit.close();
    });

    test('boş günde mıknatıs anahtarı açılabilir', () async {
      final cubit = await newCubit();
      cubit.toggleMagnet(0, false);

      cubit.toggleMagnet(0, true);

      // Sıralanacak egzersiz yokken de anahtar durumu yayınlanmalı; aksi hâlde
      // ekranda anahtar kendiliğinden geri kapanır.
      expect(cubit.state.isMagnetEnabled[0], isTrue);
      await cubit.close();
    });
  });
}
