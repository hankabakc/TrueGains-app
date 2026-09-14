import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/training/models/exercise.dart';

class TrainingBlock extends Equatable {
  final int id;
  final String name;
  final String? description;
  final int? coachId;
  final String coachName;
  final int clientId;
  final String clientName;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool isPersonal;
  final bool isTemplate;
  final bool isOrphaned;
  final List<WorkoutDay> workoutDays;
  final int? version;
  final int durationWeeks;

  const TrainingBlock({
    required this.id,
    required this.name,
    this.description,
    this.coachId,
    required this.coachName,
    required this.clientId,
    required this.clientName,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.isPersonal,
    this.isTemplate = false,
    this.isOrphaned = false,
    required this.workoutDays,
    this.version,
    this.durationWeeks = 4,
  });

  factory TrainingBlock.fromJson(Map<String, dynamic> json) {
    try {
      return TrainingBlock(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: (json['name'] as String?) ?? 'İsimsiz Program',
        description: json['description'] as String?,
        coachId: (json['coach_id'] as num?)?.toInt(),
        coachName: (json['coach_name'] as String?) ?? 'Kişisel Program',
        clientId: (json['client_id'] as num?)?.toInt() ?? 0,
        clientName: (json['client_name'] as String?) ?? '',
        startDate: json['start_date'] != null
            ? DateTime.parse(json['start_date'] as String)
            : DateTime.now(),
        endDate: json['end_date'] != null
            ? DateTime.parse(json['end_date'] as String)
            : DateTime.now().add(const Duration(days: 30)),
        isActive: (json['is_active'] as bool?) ?? true,
        isPersonal: (json['is_personal'] as bool?) ?? false,
        isTemplate: (json['is_template'] as bool?) ?? false,
        isOrphaned: (json['is_orphaned'] as bool?) ?? false,
        workoutDays:
            (json['workout_days'] as List?)
                ?.map((d) => WorkoutDay.fromJson(d as Map<String, dynamic>))
                .toList() ??
            [],
        version: (json['version'] as num?)?.toInt(),
        durationWeeks: (json['duration_weeks'] as num?)?.toInt() ?? 4,
      );
    } catch (e) {
      // JSON ayrıştırma hatası durumunda hatayı yukarı fırlat
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'coach_id': coachId,
      'client_id': clientId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'is_personal': isPersonal,
      'is_template': isTemplate,
      'is_orphaned': isOrphaned,
      'workout_days': workoutDays.map((d) => d.toJson()).toList(),
      'version': version,
      'duration_weeks': durationWeeks,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    coachId,
    coachName,
    clientId,
    clientName,
    startDate,
    endDate,
    isActive,
    isPersonal,
    isTemplate,
    isOrphaned,
    workoutDays,
    version,
    durationWeeks,
  ];
}

class WorkoutDay extends Equatable {
  final int id;
  final String name;
  final int dayOrder;
  final bool isMagnetEnabled;
  final List<WorkoutExercise> exercises;

  const WorkoutDay({
    required this.id,
    required this.name,
    required this.dayOrder,
    this.isMagnetEnabled = true,
    required this.exercises,
  });

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    try {
      final int order = (json['day_order'] as num?)?.toInt() ?? 1;
      final String originalName = (json['name'] as String?) ?? 'İsimsiz Gün';
      
      // GÜN 1, GÜN 2 gibi isimleri haftalık gün isimlerine dönüştür
      String displayName = originalName;
      if (order >= 1 && order <= 7) {
        const dayNames = [
          'Pazartesi',
          'Salı',
          'Çarşamba',
          'Perşembe',
          'Cuma',
          'Cumartesi',
          'Pazar'
        ];
        displayName = dayNames[order - 1];
      }

      return WorkoutDay(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: displayName,
        dayOrder: order,
        isMagnetEnabled: (json['is_magnet_enabled'] as bool?) ?? true,
        exercises:
            (json['exercises'] as List?)
                ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
    } catch (e) {
      // JSON ayrıştırma hatası durumunda hatayı yukarı fırlat
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'day_order': dayOrder,
      'is_magnet_enabled': isMagnetEnabled,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, name, dayOrder, isMagnetEnabled, exercises];
}

class WorkoutExercise extends Equatable {
  final int id;
  final int exerciseId;
  final String exerciseName;
  final MuscleGroup? muscleGroup; // Renk etiketi için kas grubu
  final int? targetSets;
  final String? targetReps;
  final double? targetWeight;
  final int? restTimeSeconds;
  final String? supersetGroupId;
  final int orderIndex;
  final String? coachNotes;
  final bool isToFailure;
  final List<WorkoutLog> logs;

  const WorkoutExercise({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    this.muscleGroup,
    this.targetSets,
    this.targetReps,
    this.targetWeight,
    this.restTimeSeconds,
    this.supersetGroupId,
    required this.orderIndex,
    this.coachNotes,
    this.isToFailure = false,
    required this.logs,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    try {
      return WorkoutExercise(
        id: (json['id'] as num?)?.toInt() ?? 0,
        exerciseId: (json['exercise_id'] as num?)?.toInt() ?? 0,
        exerciseName:
            (json['exercise_name'] as String?) ?? 'Bilinmeyen Egzersiz',
        muscleGroup:
            json['muscle_group'] != null
                ? MuscleGroup.fromString(json['muscle_group'] as String?)
                : null,
        targetSets: (json['target_sets'] as num?)?.toInt(),
        targetReps: json['target_reps'] as String?,
        targetWeight: (json['target_weight'] as num?)?.toDouble(),
        restTimeSeconds: (json['rest_time_seconds'] as num?)?.toInt(),
        supersetGroupId: json['superset_group_id'] as String?,
        orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
        coachNotes: json['coach_notes'] as String?,
        isToFailure: (json['is_to_failure'] as bool?) ?? false,
        logs:
            (json['logs'] as List?)
                ?.map((l) => WorkoutLog.fromJson(l as Map<String, dynamic>))
                .toList() ??
            [],
      );
    } catch (e) {
      // JSON ayrıştırma hatası durumunda hatayı yukarı fırlat
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      if (muscleGroup != null)
        'muscle_group': muscleGroup!.name.toUpperCase().replaceAll(
          'BODY',
          'BODY',
        ),
      'target_sets': targetSets,
      'target_reps': targetReps,
      if (targetWeight != null) 'target_weight': targetWeight,
      if (restTimeSeconds != null) 'rest_time_seconds': restTimeSeconds,
      if (supersetGroupId != null) 'superset_group_id': supersetGroupId,
      'order_index': orderIndex,
      if (coachNotes != null) 'coach_notes': coachNotes,
      'is_to_failure': isToFailure,
    };
  }

  @override
  List<Object?> get props => [
    id,
    exerciseId,
    exerciseName,
    muscleGroup,
    targetSets,
    targetReps,
    targetWeight,
    restTimeSeconds,
    supersetGroupId,
    orderIndex,
    coachNotes,
    isToFailure,
    logs,
  ];
}

class WorkoutLog extends Equatable {
  final int? id;
  final int setIndex;
  final double actualWeight;
  final int actualReps;
  final int? rpe;
  final int? durationSeconds;
  final DateTime? createdAt;

  const WorkoutLog({
    this.id,
    required this.setIndex,
    required this.actualWeight,
    required this.actualReps,
    this.rpe,
    this.durationSeconds,
    this.createdAt,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    try {
      return WorkoutLog(
        id: (json['id'] as num?)?.toInt(),
        setIndex: (json['set_index'] as num?)?.toInt() ?? 0,
        actualWeight: (json['actual_weight'] as num?)?.toDouble() ?? 0.0,
        actualReps: (json['actual_reps'] as num?)?.toInt() ?? 0,
        rpe: (json['rpe'] as num?)?.toInt(),
        durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
        createdAt:
            json['created_at'] != null
                ? DateTime.parse(json['created_at'] as String)
                : null,
      );
    } catch (e) {
      // JSON ayrıştırma hatası durumunda hatayı yukarı fırlat
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'set_index': setIndex,
      'actual_weight': actualWeight,
      'actual_reps': actualReps,
      'rpe': rpe,
      'duration_seconds': durationSeconds,
    };
  }

  @override
  List<Object?> get props => [
    id,
    setIndex,
    actualWeight,
    actualReps,
    rpe,
    durationSeconds,
    createdAt,
  ];
}
