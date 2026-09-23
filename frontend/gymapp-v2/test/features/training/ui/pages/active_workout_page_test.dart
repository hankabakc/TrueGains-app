import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:gymapp_v2/features/training/models/completed_set_data.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/active_workout/active_workout_bloc.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/analytics/exercise_analytics_cubit.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/analytics/exercise_analytics_state.dart';
import 'package:gymapp_v2/features/training/ui/pages/active_workout_page.dart';
import 'package:mocktail/mocktail.dart';

class MockActiveWorkoutBloc extends MockBloc<ActiveWorkoutEvent, ActiveWorkoutState> implements ActiveWorkoutBloc {}

class MockExerciseAnalyticsCubit extends MockCubit<ExerciseAnalyticsState> implements ExerciseAnalyticsCubit {}

class FakeActiveWorkoutEvent extends Fake implements ActiveWorkoutEvent {}

void main() {
  late MockActiveWorkoutBloc mockBloc;
  late MockExerciseAnalyticsCubit mockAnalyticsCubit;

  final WorkoutExercise ex = WorkoutExercise(
    id: 10,
    exerciseId: 100,
    exerciseName: 'Bench Press',
    targetSets: 3,
    targetReps: '10',
    targetWeight: 60,
    orderIndex: 0,
    logs: const [],
  );

  setUpAll(() {
    registerFallbackValue(FakeActiveWorkoutEvent());
  });

  setUp(() {
    mockBloc = MockActiveWorkoutBloc();
    mockAnalyticsCubit = MockExerciseAnalyticsCubit();
    when(() => mockAnalyticsCubit.state).thenReturn(const ExerciseAnalyticsState());
    when(() => mockAnalyticsCubit.loadExerciseProgress(any())).thenAnswer((_) async {});

    if (GetIt.instance.isRegistered<ExerciseAnalyticsCubit>()) {
      GetIt.instance.unregister<ExerciseAnalyticsCubit>();
    }
    GetIt.instance.registerFactory<ExerciseAnalyticsCubit>(() => mockAnalyticsCubit);
  });

  tearDown(() {
    if (GetIt.instance.isRegistered<ExerciseAnalyticsCubit>()) {
      GetIt.instance.unregister<ExerciseAnalyticsCubit>();
    }
  });

  Future<void> pumpActiveWorkoutPage(WidgetTester tester, WorkoutDay day, {int? blockId}) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.reset();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ActiveWorkoutBloc>.value(
          value: mockBloc,
          child: ActiveWorkoutPage(
            workoutDay: day,
            trainingBlockId: blockId,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('K1-08: Yarım antrenman setlerinin korunması', () {
    testWidgets(
      'internetsiz programın negatif geçici kimlikli günü sürerken sunucudan gelen aynı gün açılınca StartWorkout çağrılmaz',
      (WidgetTester tester) async {
        // Cihazda negatif geçici kimlikli günle başlayan ve devam eden seans
        final ongoingDay = WorkoutDay(
          id: -11,
          name: '1. Gün - Göğüs',
          dayOrder: 1,
          exercises: [ex],
        );

        when(() => mockBloc.state).thenReturn(
          ActiveWorkoutState(
            status: ActiveWorkoutStatus.active,
            workoutDay: ongoingDay,
            trainingBlockId: 0,
            completedSets: [
              CompletedSetData(
                workoutExerciseId: -110,
                exerciseName: 'Bench Press',
                setIndex: 1,
                weight: 80.0,
                reps: 10,
                durationSeconds: 45,
                completedAt: DateTime(2026, 9, 23, 10, 0),
              ),
            ],
          ),
        );

        // Program sunucuya gidip liste yenilendikten sonra panelden açılan aynı gün (id artık pozitif 42)
        final syncedDay = WorkoutDay(
          id: 42,
          name: '1. Gün - Göğüs',
          dayOrder: 1,
          exercises: [ex],
        );

        await pumpActiveWorkoutPage(tester, syncedDay, blockId: 5);

        // StartWorkout çağrılmamalı, mevcut setler ve seans korunmalı
        verifyNever(() => mockBloc.add(any(that: isA<StartWorkout>())));
      },
    );

    testWidgets(
      'farklı bir gün açıldığında StartWorkout çağrılır',
      (WidgetTester tester) async {
        final ongoingDay = WorkoutDay(
          id: -11,
          name: '1. Gün - Göğüs',
          dayOrder: 1,
          exercises: [ex],
        );

        when(() => mockBloc.state).thenReturn(
          ActiveWorkoutState(
            status: ActiveWorkoutStatus.active,
            workoutDay: ongoingDay,
            trainingBlockId: 0,
          ),
        );

        // Farklı gün (2. gün) açıldığında yeni antrenman başlar
        final differentDay = WorkoutDay(
          id: 43,
          name: '2. Gün - Bacak',
          dayOrder: 2,
          exercises: [ex],
        );

        await pumpActiveWorkoutPage(tester, differentDay, blockId: 5);

        verify(() => mockBloc.add(any(that: isA<StartWorkout>()))).called(1);
      },
    );

    testWidgets(
      'başka programın aynı sıradaki günü farklı egzersizlerle açılınca yeni antrenman başlar',
      (WidgetTester tester) async {
        final ongoingDay = WorkoutDay(
          id: -11,
          name: '1. Gün - Göğüs',
          dayOrder: 1,
          exercises: [ex],
        );

        when(() => mockBloc.state).thenReturn(
          ActiveWorkoutState(
            status: ActiveWorkoutStatus.active,
            workoutDay: ongoingDay,
            trainingBlockId: 0,
            completedSets: [
              CompletedSetData(
                workoutExerciseId: -110,
                exerciseName: 'Bench Press',
                setIndex: 1,
                weight: 80.0,
                reps: 10,
                durationSeconds: 45,
                completedAt: DateTime(2026, 9, 23, 10, 0),
              ),
            ],
          ),
        );

        final differentProgramDay = WorkoutDay(
          id: 77,
          name: '1. Gün - Göğüs',
          dayOrder: 1,
          exercises: [
            WorkoutExercise(
              id: 770,
              exerciseId: 200,
              exerciseName: 'Incline Press',
              targetSets: 3,
              targetReps: '10',
              targetWeight: 50,
              orderIndex: 0,
              logs: const [],
            ),
          ],
        );

        await pumpActiveWorkoutPage(tester, differentProgramDay, blockId: 5);

        verify(() => mockBloc.add(any(that: isA<StartWorkout>()))).called(1);
      },
    );

    testWidgets(
      'önceki antrenman bitmişse (finished) aynı gün açılsa bile yeni StartWorkout başlatılır',
      (WidgetTester tester) async {
        final finishedDay = WorkoutDay(
          id: 42,
          name: '1. Gün - Göğüs',
          dayOrder: 1,
          exercises: [ex],
        );

        when(() => mockBloc.state).thenReturn(
          ActiveWorkoutState(
            status: ActiveWorkoutStatus.finished,
            workoutDay: finishedDay,
            trainingBlockId: 5,
          ),
        );

        await pumpActiveWorkoutPage(tester, finishedDay, blockId: 5);

        verify(() => mockBloc.add(any(that: isA<StartWorkout>()))).called(1);
      },
    );
  });
}
