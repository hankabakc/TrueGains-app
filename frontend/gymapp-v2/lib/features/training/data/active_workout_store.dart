import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';
import 'package:gymapp_v2/features/training/models/completed_set_data.dart';
import 'package:gymapp_v2/features/training/models/exercise.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/active_workout/active_workout_bloc.dart';

class ActiveWorkoutStore {
  final SharedPreferences _prefs;

  ActiveWorkoutStore(this._prefs);

  static const String _kKey = 'active_workout_snapshot';

  void save(ActiveWorkoutState state) {
    if (state.workoutDay == null || state.status == ActiveWorkoutStatus.finished) {
      clear();
      return;
    }

    final map = <String, dynamic>{
      'savedAtEpochMs': DateTime.now().millisecondsSinceEpoch,
      'workoutDay': state.workoutDay!.toJson(),
      'trainingBlockId': state.trainingBlockId,
      'currentExerciseIndex': state.currentExerciseIndex,
      'currentSetIndex': state.currentSetIndex,
      'totalWorkoutSeconds': state.totalWorkoutSeconds,
      'completedSets': state.completedSets.map((e) => e.toRestoreJson()).toList(),
      'currentWeight': state.currentWeight,
      'currentReps': state.currentReps,
      'skippedExerciseIds': state.skippedExerciseIds.toList(),
      'finishedExerciseIds': state.finishedExerciseIds.toList(),
      'substitutions': state.substitutions.map((k, v) => MapEntry(k.toString(), v.toJson())),
      'sessionRestSeconds': state.sessionRestSeconds,
    };

    _prefs.setString(_kKey, jsonEncode(map));
  }

  ActiveWorkoutState? read() {
    final String? raw = _prefs.getString(_kKey);
    if (raw == null) return null;

    try {
      final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;

      final int savedAt = (map['savedAtEpochMs'] as num?)?.toInt() ?? 0;
      int elapsed = (DateTime.now().millisecondsSinceEpoch - savedAt) ~/ 1000;
      if (elapsed < 0) elapsed = 0;

      final workoutDay = WorkoutDay.fromJson(map['workoutDay'] as Map<String, dynamic>);
      final trainingBlockId = (map['trainingBlockId'] as num?)?.toInt();
      final currentExerciseIndex = (map['currentExerciseIndex'] as num?)?.toInt() ?? 0;
      final currentSetIndex = (map['currentSetIndex'] as num?)?.toInt() ?? 1;
      final totalWorkoutSeconds = ((map['totalWorkoutSeconds'] as num?)?.toInt() ?? 0) + elapsed;
      final completedSets = (map['completedSets'] as List? ?? const [])
          .map((e) => CompletedSetData.fromRestoreJson(e as Map<String, dynamic>))
          .toList();
      final currentWeight = (map['currentWeight'] as num?)?.toDouble() ?? 0.0;
      final currentReps = (map['currentReps'] as num?)?.toInt() ?? 0;
      final skippedExerciseIds = (map['skippedExerciseIds'] as List? ?? const [])
          .map((e) => (e as num).toInt())
          .toSet();
      final finishedExerciseIds = (map['finishedExerciseIds'] as List? ?? const [])
          .map((e) => (e as num).toInt())
          .toSet();
      final rawSubs = (map['substitutions'] as Map<String, dynamic>?) ?? const {};
      final substitutions = rawSubs.map((k, v) => MapEntry(int.parse(k), Exercise.fromJson(v as Map<String, dynamic>)));
      final sessionRestSeconds = (map['sessionRestSeconds'] as num?)?.toInt() ?? 90;

      return ActiveWorkoutState(
        status: ActiveWorkoutStatus.ready,
        workoutDay: workoutDay,
        trainingBlockId: trainingBlockId,
        currentExerciseIndex: currentExerciseIndex,
        currentSetIndex: currentSetIndex,
        totalWorkoutSeconds: totalWorkoutSeconds,
        completedSets: completedSets,
        currentWeight: currentWeight,
        currentReps: currentReps,
        skippedExerciseIds: skippedExerciseIds,
        finishedExerciseIds: finishedExerciseIds,
        substitutions: substitutions,
        sessionRestSeconds: sessionRestSeconds,
        setStopwatchSeconds: 0,
        restTimerSeconds: 0,
        preparationSeconds: 3,
      );
    } catch (_) {
      clear();
      return null;
    }
  }

  void clear() {
    _prefs.remove(_kKey);
  }
}
