import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/features/membership/presentation/bloc/onboarding/onboarding_cubit.dart';
import 'package:gymapp_v2/features/membership/presentation/bloc/onboarding/onboarding_state.dart';

void main() {
  group('OnboardingCubit Birim Testleri', () {
    test('1. Cubit oluşturulduğunda başlangıç durumu varsayılan OnboardingState() ile eşittir', () {
      final cubit = OnboardingCubit();
      expect(cubit.state, equals(const OnboardingState()));
      cubit.close();
    });

    blocTest<OnboardingCubit, OnboardingState>(
      '2. setProvince çağrıldığında province güncellenir ve district null kalır',
      build: () => OnboardingCubit(),
      act: (cubit) => cubit.setProvince('İstanbul'),
      expect: () => [
        const OnboardingState(province: 'İstanbul', district: null),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      '3. Önce setDistrict sonra setProvince çağrıldığında ilçe tekrar null olur',
      build: () => OnboardingCubit(),
      act: (cubit) {
        cubit.setDistrict('Kadıköy');
        cubit.setProvince('Ankara');
      },
      expect: () => [
        const OnboardingState(district: 'Kadıköy'),
        const OnboardingState(province: 'Ankara', district: null),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      '4. toggleSpecialization çağrıldığında yeni uzmanlık kümesine eklenir',
      build: () => OnboardingCubit(),
      act: (cubit) => cubit.toggleSpecialization('FITNESS'),
      expect: () => [
        const OnboardingState(specializations: {'FITNESS'}),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      '5. Aynı değerle toggleSpecialization iki kez çağrıldığında küme tekrar boşalır',
      build: () => OnboardingCubit(),
      act: (cubit) {
        cubit.toggleSpecialization('FITNESS');
        cubit.toggleSpecialization('FITNESS');
      },
      expect: () => [
        const OnboardingState(specializations: {'FITNESS'}),
        const OnboardingState(specializations: {}),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      '6. Maksimum kMaxSpecializations sınırından sonra 6. uzmanlık eklendiğinde hata verir ve seçim değişmez',
      build: () => OnboardingCubit(),
      act: (cubit) {
        for (int i = 1; i <= kMaxSpecializations; i++) {
          cubit.toggleSpecialization('SPEC_$i');
        }
        cubit.toggleSpecialization('SPEC_OVER_LIMIT');
      },
      verify: (cubit) {
        expect(cubit.state.specializations.length, equals(kMaxSpecializations));
        expect(
          cubit.state.specializationError,
          equals('En fazla $kMaxSpecializations uzmanlık seçebilirsin.'),
        );
      },
    );

    blocTest<OnboardingCubit, OnboardingState>(
      '7. showErrors sonrası clearErrors çağrıldığında tüm alan hataları temizlenir',
      build: () => OnboardingCubit(),
      act: (cubit) {
        cubit.showErrors(name: 'Ad zorunlu');
        cubit.clearErrors();
      },
      expect: () => [
        const OnboardingState(nameError: 'Ad zorunlu'),
        const OnboardingState(nameError: null),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      '8. showErrors sonrası updatePage çağrıldığında sayfa güncellenir ve hatalar temizlenir',
      build: () => OnboardingCubit(),
      act: (cubit) {
        cubit.showErrors(name: 'Ad zorunlu');
        cubit.updatePage(2);
      },
      expect: () => [
        const OnboardingState(nameError: 'Ad zorunlu'),
        const OnboardingState(currentPage: 2, nameError: null),
      ],
    );
  });
}
