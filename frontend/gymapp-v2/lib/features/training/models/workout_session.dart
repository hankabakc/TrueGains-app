class WorkoutSession {
  final int id;
  final String workoutDayName;
  final int totalSeconds;
  final DateTime createdAt;
  final List<WorkoutSessionLog> logs;

  WorkoutSession({
    required this.id,
    required this.workoutDayName,
    required this.totalSeconds,
    required this.createdAt,
    required this.logs,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: (json['id'] as int?) ?? 0,
      workoutDayName: (json['workout_day_name'] as String?) ?? (json['workoutDayName'] as String?) ?? 'İdman',
      totalSeconds: (json['total_seconds'] as int?) ?? (json['totalSeconds'] as int?) ?? 0,
      createdAt: (json['created_at'] != null)
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : (json['createdAt'] != null)
              ? DateTime.parse(json['createdAt'] as String).toLocal()
              : DateTime.now(),
      logs: (json['logs'] as List?)
              ?.map((e) => WorkoutSessionLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutDayName': workoutDayName,
      'totalSeconds': totalSeconds,
      'createdAt': createdAt.toIso8601String(),
      'logs': logs.map((e) => e.toJson()).toList(),
    };
  }
}

class WorkoutSessionLog {
  final int id;
  final int exerciseId;
  final String exerciseName;
  final int setIndex;
  final double actualWeight;
  final int actualReps;
  final int rpe;
  final int durationSeconds;

  WorkoutSessionLog({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.setIndex,
    required this.actualWeight,
    required this.actualReps,
    required this.rpe,
    required this.durationSeconds,
  });

  factory WorkoutSessionLog.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionLog(
      id: (json['id'] as int?) ?? 0,
      exerciseId: (json['exercise_id'] as int?) ?? (json['exerciseId'] as int?) ?? 0,
      exerciseName: (json['exercise_name'] as String?) ?? (json['exerciseName'] as String?) ?? 'Egzersiz',
      setIndex: (json['set_index'] as int?) ?? (json['setIndex'] as int?) ?? 0,
      actualWeight: (json['actual_weight'] as num?)?.toDouble() ?? (json['actualWeight'] as num?)?.toDouble() ?? 0.0,
      actualReps: (json['actual_reps'] as int?) ?? (json['actualReps'] as int?) ?? 0,
      rpe: (json['rpe'] as int?) ?? 0,
      durationSeconds: (json['duration_seconds'] as int?) ?? (json['durationSeconds'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'setIndex': setIndex,
      'actualWeight': actualWeight,
      'actualReps': actualReps,
      'rpe': rpe,
      'durationSeconds': durationSeconds,
    };
  }
}
