import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/auth/data/models/goal.dart';
import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';
import 'package:gymapp_v2/features/auth/data/models/experience_level.dart';

class IntroState extends Equatable {
  final int pageIndex;
  final UserRole? role;
  final Goal? goal;
  final Gender? gender;

  /// Yalnız doğum YILI alınır. Uygulama bu alandan sadece yaş türetiyor
  /// (TDEE hesabı ve program zorluğu); gün/ay hiçbir yerde tüketilmiyor.
  final int birthYear;

  /// Arayüz %100 Türkçe ve metrik olduğu için boy yalnız cm, kilo yalnız tam
  /// kilogram tutulur. Hassas takip ölçüm modülünün işidir.
  final int heightCm;
  final int weightKg;

  final ActivityLevel? activityLevel;
  final ExperienceLevel? experienceLevel;

  const IntroState({
    this.pageIndex = 0,
    this.role,
    this.goal,
    this.gender,
    this.birthYear = 2000,
    this.heightCm = 170,
    this.weightKg = 70,
    this.activityLevel,
    this.experienceLevel,
  });

  double get finalHeightCm => heightCm.toDouble();

  double get finalWeightKg => weightKg.toDouble();

  int get age {
    final int computed = DateTime.now().year - birthYear;
    return computed < 1 ? 1 : computed;
  }

  /// Backend `dateOfBirth` alanı için. `@Past` kısıtı sağlanır.
  DateTime get birthDate => DateTime(birthYear, 1, 1);

  IntroState copyWith({
    int? pageIndex,
    UserRole? role,
    Goal? goal,
    Gender? gender,
    int? birthYear,
    int? heightCm,
    int? weightKg,
    ActivityLevel? activityLevel,
    ExperienceLevel? experienceLevel,
  }) {
    return IntroState(
      pageIndex: pageIndex ?? this.pageIndex,
      role: role ?? this.role,
      goal: goal ?? this.goal,
      gender: gender ?? this.gender,
      birthYear: birthYear ?? this.birthYear,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      experienceLevel: experienceLevel ?? this.experienceLevel,
    );
  }

  @override
  List<Object?> get props => [
        pageIndex,
        role,
        goal,
        gender,
        birthYear,
        heightCm,
        weightKg,
        activityLevel,
        experienceLevel,
      ];
}
