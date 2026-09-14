import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/features/training/data/active_workout_store.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';
import 'package:gymapp_v2/features/training/repository/training_repository.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/active_workout/active_workout_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockTrainingRepository extends Mock implements TrainingRepository {}

class MockActiveWorkoutStore extends Mock implements ActiveWorkoutStore {}

class FakeActiveWorkoutState extends Fake implements ActiveWorkoutState {}

/// Antrenman sırasında girilen set verisi kaybolursa kullanıcı seansı baştan yapmak
/// zorunda kalır ve uygulamaya güvenini kaybeder. Bu testler set kaydının korunmasını,
/// doğru sırayla biriktirilmesini ve her durum geçişinde diske yazılmasını doğrular.
void main() {
  late MockTrainingRepository repository;
  late MockActiveWorkoutStore store;

  WorkoutExercise exercise(int id, String name) => WorkoutExercise(
        id: id,
        exerciseId: id * 10,
        exerciseName: name,
        targetSets: 3,
        orderIndex: 0,
        logs: const [],
      );

  final workoutDay = WorkoutDay(
    id: 1,
    name: 'Pazartesi',
    dayOrder: 1,
    exercises: [exercise(100, 'Bench Press'), exercise(200, 'Squat')],
  );

  setUpAll(() {
    registerFallbackValue(FakeActiveWorkoutState());
  });

  setUp(() {
    repository = MockTrainingRepository();
    store = MockActiveWorkoutStore();
    when(() => store.save(any())).thenReturn(null);
    when(() => store.clear()).thenReturn(null);
    when(() => store.read()).thenReturn(null);
  });

  ActiveWorkoutBloc buildBloc() =>
      ActiveWorkoutBloc(trainingRepository: repository, store: store);

  group('Set kaydı', () {
    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'set bitirildiğinde → girilen ağırlık ve tekrar kaydedilir, dinlenmeye geçilir',
      build: buildBloc,
      act: (bloc) {
        bloc.add(StartWorkout(workoutDay));
        bloc.add(const UpdateWorkoutInput(weight: 80.0, reps: 10));
        bloc.add(const FinishSet());
      },
      verify: (bloc) {
        expect(bloc.state.completedSets, hasLength(1));
        final set = bloc.state.completedSets.first;
        expect(set.weight, 80.0);
        expect(set.reps, 10);
        expect(set.workoutExerciseId, 100);
        expect(bloc.state.status, ActiveWorkoutStatus.resting);
        // Set numaralandırması 1 tabanlıdır; ilk set bitince sıradaki 2 olur.
        // Sıradaki sete geçilmeli, aksi hâlde aynı set tekrar yazılır.
        expect(bloc.state.currentSetIndex, 2);
      },
    );

    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'arka arkaya iki set bitirildiğinde → önceki set silinmez, liste birikir',
      build: buildBloc,
      act: (bloc) {
        bloc.add(StartWorkout(workoutDay));
        bloc.add(const UpdateWorkoutInput(weight: 80.0, reps: 10));
        bloc.add(const FinishSet());
        bloc.add(const UpdateWorkoutInput(weight: 85.0, reps: 8));
        bloc.add(const FinishSet());
      },
      verify: (bloc) {
        expect(bloc.state.completedSets, hasLength(2));
        expect(bloc.state.completedSets[0].weight, 80.0);
        expect(bloc.state.completedSets[1].weight, 85.0);
        // Set sıra numaraları çakışmamalı (1 tabanlı).
        expect(bloc.state.completedSets[0].setIndex, 1);
        expect(bloc.state.completedSets[1].setIndex, 2);
      },
    );

    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'antrenman başlatılmadan set bitirilmeye çalışılırsa → hiçbir kayıt oluşmaz',
      build: buildBloc,
      act: (bloc) => bloc.add(const FinishSet()),
      verify: (bloc) {
        expect(bloc.state.completedSets, isEmpty);
      },
    );
  });

  group('Kaydedilmiş setin düzeltilmesi', () {
    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'yanlış girilen set düzeltildiğinde → yalnızca o set değişir, diğeri korunur',
      build: buildBloc,
      act: (bloc) {
        bloc.add(StartWorkout(workoutDay));
        bloc.add(const UpdateWorkoutInput(weight: 80.0, reps: 10));
        bloc.add(const FinishSet());
        bloc.add(const UpdateWorkoutInput(weight: 85.0, reps: 8));
        bloc.add(const FinishSet());
        bloc.add(const EditCompletedSet(0, 100.0, 5));
      },
      verify: (bloc) {
        expect(bloc.state.completedSets, hasLength(2));
        expect(bloc.state.completedSets[0].weight, 100.0);
        expect(bloc.state.completedSets[0].reps, 5);
        // Egzersiz kimliği düzeltmede kaybolmamalı.
        expect(bloc.state.completedSets[0].workoutExerciseId, 100);
        // İkinci set etkilenmemeli.
        expect(bloc.state.completedSets[1].weight, 85.0);
      },
    );

    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'var olmayan set düzeltilmeye çalışılırsa → mevcut kayıtlar bozulmaz',
      build: buildBloc,
      act: (bloc) {
        bloc.add(StartWorkout(workoutDay));
        bloc.add(const UpdateWorkoutInput(weight: 80.0, reps: 10));
        bloc.add(const FinishSet());
        bloc.add(const EditCompletedSet(99, 999.0, 99));
      },
      verify: (bloc) {
        expect(bloc.state.completedSets, hasLength(1));
        expect(bloc.state.completedSets[0].weight, 80.0);
      },
    );
  });

  group('Çökme koruması', () {
    blocTest<ActiveWorkoutBloc, ActiveWorkoutState>(
      'her durum geçişinde → oturum diske yazılır',
      build: buildBloc,
      act: (bloc) {
        bloc.add(StartWorkout(workoutDay));
        bloc.add(const UpdateWorkoutInput(weight: 80.0, reps: 10));
        bloc.add(const FinishSet());
      },
      verify: (_) {
        // Kalıcılık olmazsa uygulama kapandığında girilen setler tamamen kaybolur.
        verify(() => store.save(any())).called(greaterThan(1));
      },
    );
  });
}
