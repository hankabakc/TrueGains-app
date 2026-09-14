import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';

class SmartGoalState extends Equatable {
  final double weight;
  final double height;
  final int age;
  final Gender gender;
  final ActivityLevel activity;
  final String goal;
  final bool useProfile;

  const SmartGoalState({
    required this.weight,
    required this.height,
    required this.age,
    required this.gender,
    required this.activity,
    required this.goal,
    this.useProfile = false,
  });

  SmartGoalState copyWith({
    double? weight,
    double? height,
    int? age,
    Gender? gender,
    ActivityLevel? activity,
    String? goal,
    bool? useProfile,
  }) {
    return SmartGoalState(
      weight: weight ?? this.weight,
      height: height ?? this.height,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      activity: activity ?? this.activity,
      goal: goal ?? this.goal,
      useProfile: useProfile ?? this.useProfile,
    );
  }

  @override
  List<Object?> get props =>
      [weight, height, age, gender, activity, goal, useProfile];
}
