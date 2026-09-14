import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/auth/data/models/goal.dart';
import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';
import 'package:gymapp_v2/features/auth/data/models/experience_level.dart';

class RegistrationFlowState extends Equatable {
  final String? email;
  final String? password;
  final String? phoneNumber;
  final UserRole? role;
  final Goal? goal;
  final Gender? gender;
  final DateTime? birthDate;
  final double? heightCm;
  final double? weightKg;
  final ActivityLevel? activityLevel;
  final ExperienceLevel? experienceLevel;

  const RegistrationFlowState({
    this.email,
    this.password,
    this.phoneNumber,
    this.role,
    this.goal,
    this.gender,
    this.birthDate,
    this.heightCm,
    this.weightKg,
    this.activityLevel,
    this.experienceLevel,
  });

  RegistrationFlowState copyWith({
    String? email,
    String? password,
    String? phoneNumber,
    UserRole? role,
    Goal? goal,
    Gender? gender,
    DateTime? birthDate,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activityLevel,
    ExperienceLevel? experienceLevel,
  }) {
    return RegistrationFlowState(
      email: email ?? this.email,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      goal: goal ?? this.goal,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      experienceLevel: experienceLevel ?? this.experienceLevel,
    );
  }

  @override
  List<Object?> get props => [
        email,
        password,
        phoneNumber,
        role,
        goal,
        gender,
        birthDate,
        heightCm,
        weightKg,
        activityLevel,
        experienceLevel,
      ];
}
