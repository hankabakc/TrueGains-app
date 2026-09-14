import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/goal.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';

double calculateTdee({
  required double weightKg,
  required double heightCm,
  required int age,
  required Gender gender,
  required ActivityLevel activity,
  Goal? goal,
}) {
  double bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age);

  // Mifflin-St Jeor cinsiyet sabiti. `other` (ve backend'den bilinmeyen bir değer
  // geldiğinde düşülen varsayılan) daha önce kadın sabitini alıyordu; cinsiyetini
  // belirtmeyen kullanıcı sistematik olarak düşük kalori hedefi görüyordu. İki sabitin
  // ortası, formülün dışına çıkmadan tarafsız bir varsayılan veriyor.
  bmr += switch (gender) {
    Gender.male => 5,
    Gender.female => -161,
    Gender.other => -78,
  };

  double factor = 1.2;
  switch (activity) {
    case ActivityLevel.sedentary:
      factor = 1.2;
      break;
    case ActivityLevel.lightlyActive:
      factor = 1.375;
      break;
    case ActivityLevel.moderatelyActive:
      factor = 1.55;
      break;
    case ActivityLevel.veryActive:
      factor = 1.725;
      break;
    case ActivityLevel.extraActive:
      factor = 1.9;
      break;
  }

  double tdee = bmr * factor;

  if (goal == Goal.kiloVer) {
    tdee -= 500;
  } else if (goal == Goal.kasKazan) {
    tdee += 500;
  }

  return tdee;
}

({double protein, double carbs, double fat}) macrosFromCalories(double calories) {
  final double protein = (calories * 0.20) / 4.0;
  final double carbs = (calories * 0.50) / 4.0;
  final double fat = (calories * 0.30) / 9.0;
  return (protein: protein, carbs: carbs, fat: fat);
}

double calculateBmi({
  required double weightKg,
  required double heightCm,
}) {
  if (heightCm <= 0) return 0.0;
  final double heightM = heightCm / 100.0;
  return weightKg / (heightM * heightM);
}
