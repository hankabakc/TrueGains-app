import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/auth/data/models/goal.dart';
import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';
import 'package:gymapp_v2/features/auth/data/models/experience_level.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/registration_flow/registration_flow_cubit.dart';
import 'intro_state.dart';

class IntroCubit extends Cubit<IntroState> {
  final RegistrationFlowCubit _registrationFlowCubit;

  IntroCubit(this._registrationFlowCubit) : super(const IntroState());

  void selectRole(UserRole role) {
    _registrationFlowCubit.setRole(role);
    emit(state.copyWith(role: role));
  }

  void selectGoal(Goal v) {
    emit(state.copyWith(goal: v));
  }

  void selectGender(Gender v) {
    emit(state.copyWith(gender: v));
  }

  void setBirthYear(int v) {
    emit(state.copyWith(birthYear: v));
  }

  void setHeight(int cm) {
    emit(state.copyWith(heightCm: cm));
  }

  void setWeight(int kg) {
    emit(state.copyWith(weightKg: kg));
  }

  void selectActivity(ActivityLevel v) {
    emit(state.copyWith(activityLevel: v));
  }

  void selectExperience(ExperienceLevel v) {
    emit(state.copyWith(experienceLevel: v));
  }

  void nextPage() {
    emit(state.copyWith(pageIndex: state.pageIndex + 1));
  }

  bool previousPage() {
    if (state.pageIndex == 0) return false;
    emit(state.copyWith(pageIndex: state.pageIndex - 1));
    return true;
  }

  void commitAnswers() {
    _registrationFlowCubit.setProfileAnswers(
      goal: state.goal,
      gender: state.gender,
      birthDate: state.birthDate,
      heightCm: state.finalHeightCm,
      weightKg: state.finalWeightKg,
      activityLevel: state.activityLevel,
      experienceLevel: state.experienceLevel,
    );
  }
}
