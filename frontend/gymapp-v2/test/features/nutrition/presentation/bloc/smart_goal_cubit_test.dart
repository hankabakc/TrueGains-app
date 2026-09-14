import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';
import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/smart_goal/smart_goal_cubit.dart';

/// Hazır kalori hedefi ekranı.
///
/// Hesabın kendisi `tdee_calculator` içinde ve testi var. Burada test edilen
/// şey **hangi sayının nereye gittiği**: profil verisi yanlış alana kopyalanırsa
/// (kilo yerine boy gibi) kullanıcıya sessizce yanlış bir kalori hedefi çıkar.
void main() {
  SmartGoalCubit cubit({bool withProfile = true}) {
    return SmartGoalCubit(
      initialWeight: 70,
      initialHeight: 170,
      initialAge: 25,
      initialGender: Gender.female,
      initialActivity: ActivityLevel.sedentary,
      initialGoal: 'KORU',
      fetchedWeight: withProfile ? 85 : null,
      fetchedHeight: withProfile ? 185 : null,
      fetchedAge: withProfile ? 40 : null,
      fetchedGender: withProfile ? Gender.male : null,
      fetchedActivity: withProfile ? ActivityLevel.veryActive : null,
      fetchedGoal: withProfile ? 'KILO_VER' : null,
    );
  }

  test('profil verisi varsa başlangıçta profil kullanılır', () {
    expect(cubit().state.useProfile, isTrue);
    expect(cubit(withProfile: false).state.useProfile, isFalse);
  });

  test('profil açıldığında her değer kendi alanına yazılır', () {
    final c = cubit();
    c.toggleUseProfile(false);

    c.toggleUseProfile(true);

    expect(c.state.weight, 85);
    expect(c.state.height, 185);
    expect(c.state.age, 40);
    expect(c.state.gender, Gender.male);
    expect(c.state.activity, ActivityLevel.veryActive);
    expect(c.state.goal, 'KILO_VER');
  });

  test('profil kapatılınca elle girilen değerler silinmez', () {
    final c = cubit();
    c.updateWeight(92);
    c.updateAge(33);

    c.toggleUseProfile(false);

    expect(c.state.useProfile, isFalse);
    expect(c.state.weight, 92);
    expect(c.state.age, 33);
  });

  test('hesap ekrandaki güncel değerlerle yapılır', () {
    final c = cubit();
    final before = c.calculateTdee();

    c.updateWeight(c.state.weight + 20);

    // Kilo arttıysa hedef kalori de artmalı; hesap eski değerle yapılıyorsa
    // kullanıcı ekranda gördüğü veriye ait olmayan bir sonuç görür.
    expect(c.calculateTdee(), greaterThan(before));
  });

  test('profil verisi yoksa açma denemesi mevcut değerleri bozmaz', () {
    final c = cubit(withProfile: false);

    c.toggleUseProfile(true);

    expect(c.state.weight, 70);
    expect(c.state.height, 170);
    expect(c.state.age, 25);
  });
}
