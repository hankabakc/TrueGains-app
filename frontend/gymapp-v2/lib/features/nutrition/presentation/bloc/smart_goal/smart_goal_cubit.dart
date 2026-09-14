import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';
import 'package:gymapp_v2/features/auth/data/models/goal.dart';
import 'package:gymapp_v2/core/util/tdee_calculator.dart' as tdee_calc;
import 'smart_goal_state.dart';

class SmartGoalCubit extends Cubit<SmartGoalState> {
  final double? fetchedWeight;
  final double? fetchedHeight;
  final int? fetchedAge;
  final Gender? fetchedGender;
  final ActivityLevel? fetchedActivity;
  final String? fetchedGoal;

  SmartGoalCubit({
    required double initialWeight,
    required double initialHeight,
    required int initialAge,
    required Gender initialGender,
    required ActivityLevel initialActivity,
    required String initialGoal,
    this.fetchedWeight,
    this.fetchedHeight,
    this.fetchedAge,
    this.fetchedGender,
    this.fetchedActivity,
    this.fetchedGoal,
  }) : super(SmartGoalState(
          weight: initialWeight,
          height: initialHeight,
          age: initialAge,
          gender: initialGender,
          activity: initialActivity,
          goal: initialGoal,
          useProfile: fetchedWeight != null,
        ));

  void toggleUseProfile(bool val) {
    if (val) {
      emit(state.copyWith(
        useProfile: true,
        weight: fetchedWeight ?? state.weight,
        height: fetchedHeight ?? state.height,
        age: fetchedAge ?? state.age,
        gender: fetchedGender ?? state.gender,
        activity: fetchedActivity ?? state.activity,
        goal: fetchedGoal ?? state.goal,
      ));
    } else {
      emit(state.copyWith(useProfile: false));
    }
  }

  void updateWeight(double v) => emit(state.copyWith(weight: v));
  void updateHeight(double v) => emit(state.copyWith(height: v));
  void updateAge(int v) => emit(state.copyWith(age: v));
  void updateGender(Gender v) => emit(state.copyWith(gender: v));
  void updateActivity(ActivityLevel v) => emit(state.copyWith(activity: v));
  void updateGoal(String v) => emit(state.copyWith(goal: v));

  double calculateTdee() {
    return tdee_calc.calculateTdee(
      weightKg: state.weight,
      heightCm: state.height,
      age: state.age,
      gender: state.gender,
      activity: state.activity,
      goal: Goal.fromString(state.goal),
    );
  }
}
