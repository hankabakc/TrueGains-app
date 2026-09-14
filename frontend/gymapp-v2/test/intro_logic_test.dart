import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/util/tdee_calculator.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';
import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/goal.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/auth/presentation/signup_steps.dart';
import 'package:gymapp_v2/core/widgets/signup/intro_progress_bar.dart';
import 'package:gymapp_v2/core/widgets/signup/intro_result_view.dart';

void main() {
  group('bara plakaları merkezden dolar', () {
    test('8 plaka için sıra 3,4,2,5,1,6,0,7', () {
      expect(IntroProgressBar.fillOrder(8), [3, 4, 2, 5, 1, 6, 0, 7]);
    });

    test('tek sayıda plaka tam ortadan başlar', () {
      expect(IntroProgressBar.fillOrder(5).first, 2);
    });

    test('tek plaka (koç dalı) ilk adımda dolu sayılır', () {
      final order = IntroProgressBar.fillOrder(1);
      expect(order.indexOf(0) <= 0, isTrue);
    });
  });

  group('kayıt akışı adım sayacı', () {
    test('sporcu 12, antrenör 8 adım', () {
      expect(signupTotalSteps(UserRole.CLIENT), 12);
      // Antrenörde rol + boy + kilo soruluyor: boy/kilo backend'de zorunlu.
      expect(signupTotalSteps(UserRole.COACH), 8);
      expect(signupIntroSteps(UserRole.COACH), 3);
    });

    test('adımlar boşluksuz ve çakışmasız ilerler', () {
      for (final role in [UserRole.CLIENT, UserRole.COACH]) {
        final List<int> steps = [
          for (int q = 0; q < signupIntroSteps(role); q++) q,
          signupFormStep(role),
          for (int p = 0; p < signupProfileSteps(role); p++)
            signupProfileStep(role, p),
        ];
        expect(
          steps,
          List<int>.generate(signupTotalSteps(role), (i) => i),
          reason: '$role için adım indeksleri 0..n-1 dizisini tam kaplamalı',
        );
      }
    });

    test('etiket 1 tabanlı okunur', () {
      expect(signupStepLabel(0, 12), 'ADIM 1 / 12');
      expect(signupStepLabel(11, 12), 'ADIM 12 / 12');
    });
  });

  group('kalori basamak gruplama', () {
    test('dört basamak ince boşlukla ayrılır', () {
      expect(IntroResultView.groupDigits(2799), '2 799');
    });

    test('üç basamak bölünmez', () {
      expect(IntroResultView.groupDigits(950), '950');
    });
  });

  group('TDEE hedef düzeltmesi', () {
    // Erkek / 30 yaş / 180 cm / 80 kg / orta aktif
    // BMR = 10*80 + 6.25*180 - 5*30 + 5 = 1780 ; TDEE = 1780 * 1.55 = 2759
    double tdeeFor(Goal? goal) => calculateTdee(
          weightKg: 80,
          heightCm: 180,
          age: 30,
          gender: Gender.male,
          activity: ActivityLevel.moderatelyActive,
          goal: goal,
        );

    test('koru hedefi bakım kalorisini verir', () {
      expect(tdeeFor(Goal.koru), closeTo(2759, 1));
    });

    test('kilo ver 500 kcal düşürür', () {
      expect(tdeeFor(Goal.koru) - tdeeFor(Goal.kiloVer), closeTo(500, 0.001));
    });

    test('kas kazan 500 kcal ekler', () {
      expect(tdeeFor(Goal.kasKazan) - tdeeFor(Goal.koru), closeTo(500, 0.001));
    });
  });
}
