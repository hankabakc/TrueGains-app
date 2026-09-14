import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

// Mock model classes for testing
class WorkoutExercise {
  final int? targetSets;
  final String? targetReps;

  WorkoutExercise({this.targetSets, this.targetReps});

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      targetSets: (json['target_sets'] as num?)?.toInt(),
      targetReps: json['target_reps'] as String?,
    );
  }
}

void main() {
  test('WorkoutExercise JSON Mapping Test (snake_case & num casting)', () {
    const jsonStr = '{"target_sets": 4, "target_reps": "10-12"}';
    final Map<String, dynamic> jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;
    
    final exercise = WorkoutExercise.fromJson(jsonData);
    
    expect(exercise.targetSets, 4);
    expect(exercise.targetReps, '10-12');
  });

  test('WorkoutExercise JSON Mapping Test (null safety)', () {
    const jsonStr = '{"target_sets": null, "target_reps": null}';
    final Map<String, dynamic> jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;
    
    final exercise = WorkoutExercise.fromJson(jsonData);
    
    expect(exercise.targetSets, isNull);
    expect(exercise.targetReps, isNull);
  });
}
