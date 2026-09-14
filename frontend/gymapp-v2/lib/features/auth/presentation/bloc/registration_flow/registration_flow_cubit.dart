import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/auth/data/models/goal.dart';
import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';
import 'package:gymapp_v2/features/auth/data/models/experience_level.dart';
import 'registration_flow_state.dart';

class RegistrationFlowCubit extends Cubit<RegistrationFlowState> {
  RegistrationFlowCubit() : super(const RegistrationFlowState());

  void setRole(UserRole role) {
    emit(state.copyWith(role: role));
  }

  void setCredentials({
    required String email,
    required String password,
    required String phoneNumber,
    required UserRole role,
  }) {
    emit(state.copyWith(
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      role: role,
    ));
  }

  void setProfileAnswers({
    Goal? goal,
    Gender? gender,
    DateTime? birthDate,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activityLevel,
    ExperienceLevel? experienceLevel,
  }) {
    emit(state.copyWith(
      goal: goal,
      gender: gender,
      birthDate: birthDate,
      heightCm: heightCm,
      weightKg: weightKg,
      activityLevel: activityLevel,
      experienceLevel: experienceLevel,
    ));
  }

  /// Doğrulanmamış bir hesapla giriş denendiğinde, OTP ekranının ihtiyaç duyduğu
  /// e-postayı ayarlar (kayıt akışı dışından gelen doğrulama için).
  void setEmailForVerification(String email) {
    emit(state.copyWith(email: email));
  }

  void clear() {
    emit(const RegistrationFlowState());
  }
}
