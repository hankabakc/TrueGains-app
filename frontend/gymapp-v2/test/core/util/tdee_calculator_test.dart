import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/util/tdee_calculator.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';
import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/goal.dart';

void main() {
  group('calculateTdee', () {
    test('erkek moderatör aktif hedef yok → tam 2759.0 kalori fırlatır', () {
      final double result = calculateTdee(
        weightKg: 80.0,
        heightCm: 180.0,
        age: 30,
        gender: Gender.male,
        activity: ActivityLevel.moderatelyActive,
      );
      expect(result, equals(2759.0));
    });

    test('kadın moderatör aktif hedef yok → 2501.7 kalori hesaplar', () {
      final double result = calculateTdee(
        weightKg: 80.0,
        heightCm: 180.0,
        age: 30,
        gender: Gender.female,
        activity: ActivityLevel.moderatelyActive,
      );
      expect(result, closeTo(2501.7, 0.01));
    });

    /// Cinsiyetini belirtmeyen kullanıcı (`Gender.other`; bilinmeyen değerler de buraya
    /// düşüyor) daha önce **kadın katsayısını** alıyordu ve sistematik olarak düşük
    /// hedef görüyordu. Artık iki katsayının tam ortası kullanılıyor.
    test('cinsiyet belirtilmediğinde katsayı erkek ile kadının tam ortası', () {
      double forGender(Gender gender) => calculateTdee(
            weightKg: 80.0,
            heightCm: 180.0,
            age: 30,
            gender: gender,
            activity: ActivityLevel.moderatelyActive,
          );

      final double other = forGender(Gender.other);

      expect(other, closeTo((forGender(Gender.male) + forGender(Gender.female)) / 2, 0.0001));
      // Kadın katsayısına eşit kalırsa eski davranış geri gelmiş demektir.
      expect(other, isNot(closeTo(forGender(Gender.female), 0.01)));
    });

    test('erkek moderatör aktif kilo ver hedefi → 500 kalori eksiltir tam 2259.0', () {
      final double result = calculateTdee(
        weightKg: 80.0,
        heightCm: 180.0,
        age: 30,
        gender: Gender.male,
        activity: ActivityLevel.moderatelyActive,
        goal: Goal.kiloVer,
      );
      expect(result, equals(2259.0));
    });

    test('erkek moderatör aktif kas kazan hedefi → 500 kalori ekler tam 3259.0', () {
      final double result = calculateTdee(
        weightKg: 80.0,
        heightCm: 180.0,
        age: 30,
        gender: Gender.male,
        activity: ActivityLevel.moderatelyActive,
        goal: Goal.kasKazan,
      );
      expect(result, equals(3259.0));
    });

    test('erkek hareketsiz hedef yok → tam 2136.0 kalori hesaplar', () {
      final double result = calculateTdee(
        weightKg: 80.0,
        heightCm: 180.0,
        age: 30,
        gender: Gender.male,
        activity: ActivityLevel.sedentary,
      );
      expect(result, equals(2136.0));
    });

    test('erkek ekstra aktif hedef yok → tam 3382.0 kalori hesaplar', () {
      final double result = calculateTdee(
        weightKg: 80.0,
        heightCm: 180.0,
        age: 30,
        gender: Gender.male,
        activity: ActivityLevel.extraActive,
      );
      expect(result, equals(3382.0));
    });
  });

  group('macrosFromCalories', () {
    test('2000 kalori → protein 100g, karbonhidrat 250g, yağ 66.67g hesaplar', () {
      final macros = macrosFromCalories(2000.0);
      expect(macros.protein, closeTo(100.0, 0.01));
      expect(macros.carbs, closeTo(250.0, 0.01));
      expect(macros.fat, closeTo(66.67, 0.01));
    });

    test('2000 kalori → makro enerjileri toplamı tam 2000 kaloridir', () {
      final macros = macrosFromCalories(2000.0);
      final double totalCalories = (macros.protein * 4.0) + (macros.carbs * 4.0) + (macros.fat * 9.0);
      expect(totalCalories, closeTo(2000.0, 0.01));
    });
  });

  group('calculateBmi', () {
    test('80 kg 180 cm → VKİ 24.69 hesaplar', () {
      final double result = calculateBmi(weightKg: 80.0, heightCm: 180.0);
      expect(result, closeTo(24.69, 0.01));
    });

    test('80 kg 0 cm → sıfıra bölme koruması tam 0.0 döner', () {
      final double result = calculateBmi(weightKg: 80.0, heightCm: 0.0);
      expect(result, equals(0.0));
    });

    test('80 kg -10 cm → negatif boy koruması tam 0.0 döner', () {
      final double result = calculateBmi(weightKg: 80.0, heightCm: -10.0);
      expect(result, equals(0.0));
    });
  });
}
