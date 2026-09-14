import 'package:equatable/equatable.dart';

class CompletedSetData extends Equatable {
  final int workoutExerciseId;
  final String exerciseName;
  final int setIndex;
  final double weight;
  final int reps;
  final int durationSeconds;
  final DateTime completedAt;
  final int? substituteExerciseId;

  const CompletedSetData({
    required this.workoutExerciseId,
    required this.exerciseName,
    required this.setIndex,
    required this.weight,
    required this.reps,
    required this.durationSeconds,
    required this.completedAt,
    this.substituteExerciseId,
  });

  Map<String, dynamic> toJson() {
    return {
      'workoutExerciseId': workoutExerciseId,
      'setIndex': setIndex,
      'weight': weight,
      'reps': reps,
      'durationSeconds': durationSeconds,
      'completedAt': completedAt.toIso8601String(),
      'substituteExerciseId': substituteExerciseId,
    };
  }

  Map<String, dynamic> toRestoreJson() {
    return {
      'workoutExerciseId': workoutExerciseId,
      'exerciseName': exerciseName,
      'setIndex': setIndex,
      'weight': weight,
      'reps': reps,
      'durationSeconds': durationSeconds,
      'completedAt': completedAt.toIso8601String(),
      'substituteExerciseId': substituteExerciseId,
    };
  }

  factory CompletedSetData.fromRestoreJson(Map<String, dynamic> json) {
    return CompletedSetData(
      workoutExerciseId: (json['workoutExerciseId'] as num?)?.toInt() ?? 0,
      exerciseName: json['exerciseName'] as String? ?? '',
      setIndex: (json['setIndex'] as num?)?.toInt() ?? 1,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ?? DateTime.now(),
      substituteExerciseId: (json['substituteExerciseId'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [
    workoutExerciseId,
    exerciseName,
    setIndex,
    weight,
    reps,
    durationSeconds,
    completedAt,
    substituteExerciseId,
  ];
}
