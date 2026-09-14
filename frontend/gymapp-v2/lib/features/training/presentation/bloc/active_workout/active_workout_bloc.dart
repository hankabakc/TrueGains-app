import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';
import 'package:gymapp_v2/features/training/models/completed_set_data.dart';
import 'package:gymapp_v2/features/training/models/exercise.dart';
import 'package:gymapp_v2/features/training/repository/training_repository.dart';

import 'package:gymapp_v2/features/training/data/active_workout_store.dart';

part 'active_workout_event.dart';
part 'active_workout_state.dart';

class ActiveWorkoutBloc extends Bloc<ActiveWorkoutEvent, ActiveWorkoutState> {
  final TrainingRepository _trainingRepository;
  final ActiveWorkoutStore _store;
  Timer? _timer;

  ActiveWorkoutBloc({
    required TrainingRepository trainingRepository,
    required ActiveWorkoutStore store,
  })  : _trainingRepository = trainingRepository,
        _store = store,
        super(const ActiveWorkoutState()) {
    on<StartWorkout>(_onStartWorkout);
    on<StartSet>(_onStartSet);
    on<FinishSet>(_onFinishSet);
    on<SkipRest>(_onSkipRest);
    on<Tick>(_onTick);
    on<QuickFinishWorkout>(_onQuickFinishWorkout);
    on<UpdateWorkoutInput>(_onUpdateWorkoutInput);
    on<SkipExercise>(_onSkipExercise);
    on<FinishExercise>(_onFinishExercise);
    on<GoToExercise>(_onGoToExercise);
    on<EditCompletedSet>(_onEditCompletedSet);
    on<DeleteCompletedSet>(_onDeleteCompletedSet);
    on<SubstituteExercise>(_onSubstituteExercise);
    on<RestoreWorkout>(_onRestoreWorkout);
  }

  @override
  void onTransition(Transition<ActiveWorkoutEvent, ActiveWorkoutState> transition) {
    super.onTransition(transition);
    if (transition.event is Tick) return;
    if (transition.event is RestoreWorkout) return;
    _store.save(transition.nextState);
  }

  void _ensureTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(Tick());
    });
  }

  void _onRestoreWorkout(RestoreWorkout event, Emitter<ActiveWorkoutState> emit) {
    final ActiveWorkoutState? restored = _store.read();
    if (restored == null) return;
    emit(restored);
    _ensureTimer();
  }

  void _onStartWorkout(StartWorkout event, Emitter<ActiveWorkoutState> emit) {
    _ensureTimer();

    emit(
      ActiveWorkoutState(
        status: ActiveWorkoutStatus.ready,
        workoutDay: event.workoutDay,
        trainingBlockId: event.trainingBlockId,
        currentExerciseIndex: 0,
        currentSetIndex: 1,
        totalWorkoutSeconds: 0,
        completedSets: [],
        sessionRestSeconds: event.restSeconds,
      ),
    );
  }

  void _onStartSet(StartSet event, Emitter<ActiveWorkoutState> emit) {
    if (state.workoutDay == null || state.workoutDay!.exercises.isEmpty) return;
    
    final bool isIndexValid = state.currentExerciseIndex >= 0 &&
        state.currentExerciseIndex < state.workoutDay!.exercises.length;
    if (!isIndexValid) return;

    final currentExercise = state.workoutDay!.exercises[state.currentExerciseIndex];

    // Aynı egzersize ait en son tamamlanan seti bulalım
    CompletedSetData? lastCompletedSet;
    for (var i = state.completedSets.length - 1; i >= 0; i--) {
      if (state.completedSets[i].workoutExerciseId == currentExercise.id) {
        lastCompletedSet = state.completedSets[i];
        break;
      }
    }

    final double defaultWeight = lastCompletedSet != null
        ? lastCompletedSet.weight
        : (currentExercise.targetWeight ?? 0.0);

    int fallbackReps = 10;
    if (currentExercise.targetReps != null && currentExercise.targetReps!.isNotEmpty) {
      final cleanReps = currentExercise.targetReps!.split(RegExp(r'[-/,]')).first.trim();
      fallbackReps = int.tryParse(cleanReps) ?? 10;
    }

    final int defaultReps = lastCompletedSet != null
        ? lastCompletedSet.reps
        : fallbackReps;

    emit(
      state.copyWith(
        status: ActiveWorkoutStatus.preparing,
        preparationSeconds: 3,
        setStopwatchSeconds: 0,
        currentWeight: defaultWeight,
        currentReps: defaultReps,
      ),
    );
  }

  Future<void> _onFinishSet(
    FinishSet event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    if (state.workoutDay == null) return;

    final currentExercise =
        state.workoutDay!.exercises[state.currentExerciseIndex];

    final sub = state.substitutions[currentExercise.id];

    final completedSet = CompletedSetData(
      workoutExerciseId: currentExercise.id,
      exerciseName: sub != null ? sub.name : currentExercise.exerciseName,
      setIndex: state.currentSetIndex,
      weight: state.currentWeight,
      reps: state.currentReps,
      durationSeconds: state.setStopwatchSeconds,
      completedAt: DateTime.now(),
      substituteExerciseId: sub?.id,
    );

    final updatedCompletedSets = List<CompletedSetData>.from(
      state.completedSets,
    )..add(completedSet);

    emit(
      state.copyWith(
        status: ActiveWorkoutStatus.resting,
        restTimerSeconds: state.sessionRestSeconds,
        completedSets: updatedCompletedSets,
        currentSetIndex: state.currentSetIndex + 1,
      ),
    );
  }

  Future<void> _advanceToNextPending(Emitter<ActiveWorkoutState> emit) async {
    if (state.workoutDay == null) return;

    final exercises = state.workoutDay!.exercises;
    int? nextIndex;

    for (int i = 0; i < exercises.length; i++) {
      final id = exercises[i].id;
      if (!state.finishedExerciseIds.contains(id) && !state.skippedExerciseIds.contains(id)) {
        nextIndex = i;
        break;
      }
    }

    if (nextIndex != null) {
      final nextExercise = exercises[nextIndex];
      final int completedSetsCount = state.completedSets
          .where((s) => s.workoutExerciseId == nextExercise.id)
          .length;

      emit(
        state.copyWith(
          currentExerciseIndex: nextIndex,
          currentSetIndex: completedSetsCount + 1,
          status: ActiveWorkoutStatus.ready,
          restTimerSeconds: 0,
        ),
      );
    } else {
      await _finishWorkout(emit, state.completedSets);
    }
  }

  Future<void> _onFinishExercise(
    FinishExercise event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    if (state.workoutDay == null || state.workoutDay!.exercises.isEmpty) return;

    final currentExercise = state.workoutDay!.exercises[state.currentExerciseIndex];
    final updatedFinished = Set<int>.from(state.finishedExerciseIds)..add(currentExercise.id);

    emit(state.copyWith(finishedExerciseIds: updatedFinished));

    await _advanceToNextPending(emit);
  }

  Future<void> _onSkipExercise(
    SkipExercise event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    if (state.workoutDay == null || state.workoutDay!.exercises.isEmpty) return;

    final currentExercise = state.workoutDay!.exercises[state.currentExerciseIndex];
    final updatedSkipped = Set<int>.from(state.skippedExerciseIds)..add(currentExercise.id);

    emit(state.copyWith(skippedExerciseIds: updatedSkipped));

    await _advanceToNextPending(emit);
  }

  void _onGoToExercise(
    GoToExercise event,
    Emitter<ActiveWorkoutState> emit,
  ) {
    if (state.workoutDay == null) return;
    final index = event.index;
    final exercises = state.workoutDay!.exercises;

    if (index >= 0 && index < exercises.length) {
      final targetExercise = exercises[index];
      final updatedFinished = Set<int>.from(state.finishedExerciseIds)..remove(targetExercise.id);
      final updatedSkipped = Set<int>.from(state.skippedExerciseIds)..remove(targetExercise.id);

      final int completedSetsCount = state.completedSets
          .where((s) => s.workoutExerciseId == targetExercise.id)
          .length;

      emit(
        state.copyWith(
          currentExerciseIndex: index,
          currentSetIndex: completedSetsCount + 1,
          status: ActiveWorkoutStatus.ready,
          restTimerSeconds: 0,
          finishedExerciseIds: updatedFinished,
          skippedExerciseIds: updatedSkipped,
        ),
      );
    }
  }

  void _onEditCompletedSet(
    EditCompletedSet event,
    Emitter<ActiveWorkoutState> emit,
  ) {
    final int idx = event.index;
    if (idx >= 0 && idx < state.completedSets.length) {
      final original = state.completedSets[idx];
      final updatedSet = CompletedSetData(
        workoutExerciseId: original.workoutExerciseId,
        exerciseName: original.exerciseName,
        setIndex: original.setIndex,
        weight: event.weight,
        reps: event.reps,
        durationSeconds: original.durationSeconds,
        completedAt: original.completedAt,
        substituteExerciseId: original.substituteExerciseId,
      );

      final updatedList = List<CompletedSetData>.from(state.completedSets);
      updatedList[idx] = updatedSet;

      emit(state.copyWith(completedSets: updatedList));
    }
  }

  void _onDeleteCompletedSet(
    DeleteCompletedSet event,
    Emitter<ActiveWorkoutState> emit,
  ) {
    final int idx = event.index;
    if (idx >= 0 && idx < state.completedSets.length) {
      final targetExerciseId = state.completedSets[idx].workoutExerciseId;

      final updatedList = List<CompletedSetData>.from(state.completedSets)..removeAt(idx);

      int count = 1;
      for (int i = 0; i < updatedList.length; i++) {
        if (updatedList[i].workoutExerciseId == targetExerciseId) {
          final s = updatedList[i];
          updatedList[i] = CompletedSetData(
            workoutExerciseId: s.workoutExerciseId,
            exerciseName: s.exerciseName,
            setIndex: count,
            weight: s.weight,
            reps: s.reps,
            durationSeconds: s.durationSeconds,
            completedAt: s.completedAt,
            substituteExerciseId: s.substituteExerciseId,
          );
          count++;
        }
      }

      final currentExercise = state.workoutDay?.exercises[state.currentExerciseIndex];

      emit(
        state.copyWith(
          completedSets: updatedList,
          currentSetIndex: (currentExercise != null && currentExercise.id == targetExerciseId)
              ? count
              : state.currentSetIndex,
        ),
      );
    }
  }

  void _onSkipRest(SkipRest event, Emitter<ActiveWorkoutState> emit) {
    emit(
      state.copyWith(status: ActiveWorkoutStatus.ready, restTimerSeconds: 0),
    );
  }

  void _onTick(Tick event, Emitter<ActiveWorkoutState> emit) {
    if (state.status == ActiveWorkoutStatus.active) {
      emit(
        state.copyWith(
          totalWorkoutSeconds: state.totalWorkoutSeconds + 1,
          setStopwatchSeconds: state.setStopwatchSeconds + 1,
        ),
      );
    } else if (state.status == ActiveWorkoutStatus.resting) {
      final newRestTime = state.restTimerSeconds - 1;
      if (newRestTime <= 0) {
        emit(
          state.copyWith(
            status: ActiveWorkoutStatus.ready,
            restTimerSeconds: 0,
            totalWorkoutSeconds: state.totalWorkoutSeconds + 1,
          ),
        );
      } else {
        emit(
          state.copyWith(
            restTimerSeconds: newRestTime,
            totalWorkoutSeconds: state.totalWorkoutSeconds + 1,
          ),
        );
      }
    } else if (state.status == ActiveWorkoutStatus.preparing) {
      final nextValue = state.preparationSeconds - 1;
      if (nextValue <= 0) {
        emit(
          state.copyWith(
            status: ActiveWorkoutStatus.active,
            preparationSeconds: 0,
            setStopwatchSeconds: 0,
            totalWorkoutSeconds: state.totalWorkoutSeconds + 1,
          ),
        );
      } else {
        emit(
          state.copyWith(
            preparationSeconds: nextValue,
            totalWorkoutSeconds: state.totalWorkoutSeconds + 1,
          ),
        );
      }
    } else {
      emit(state.copyWith(totalWorkoutSeconds: state.totalWorkoutSeconds + 1));
    }
  }

  void _onUpdateWorkoutInput(
    UpdateWorkoutInput event,
    Emitter<ActiveWorkoutState> emit,
  ) {
    emit(
      state.copyWith(
        currentWeight: event.weight ?? state.currentWeight,
        currentReps: event.reps ?? state.currentReps,
      ),
    );
  }

  Future<void> _onQuickFinishWorkout(
    QuickFinishWorkout event,
    Emitter<ActiveWorkoutState> emit,
  ) async {
    await _finishWorkout(emit, state.completedSets);
  }

  Future<void> _finishWorkout(
    Emitter<ActiveWorkoutState> emit,
    List<CompletedSetData> finalSets,
  ) async {
    _timer?.cancel();

    bool isOffline = false;

    // Verileri backend'e gönder (Async)
    try {
      if (state.workoutDay != null) {
        final response = await _trainingRepository.logWorkoutSession(
          dayName: state.workoutDay!.name,
          totalSeconds: state.totalWorkoutSeconds,
          sets: finalSets,
          trainingBlockId: state.trainingBlockId,
          workoutDayId: state.workoutDay!.id,
        );
        isOffline = response.message == 'Offline kaydedildi.';
      }
    } catch (e) {
      // Hata yönetimi
    }

    emit(
      state.copyWith(
        status: ActiveWorkoutStatus.finished,
        completedSets: finalSets,
        isOfflineSaved: isOffline,
      ),
    );
  }

  void _onSubstituteExercise(
    SubstituteExercise event,
    Emitter<ActiveWorkoutState> emit,
  ) {
    if (state.workoutDay == null || state.workoutDay!.exercises.isEmpty) return;

    final currentExercise = state.workoutDay!.exercises[state.currentExerciseIndex];
    final updated = Map<int, Exercise>.from(state.substitutions)..[currentExercise.id] = event.exercise;
    emit(state.copyWith(substitutions: updated));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
