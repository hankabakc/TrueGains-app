import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/registration_flow/registration_flow_cubit.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/registration_flow/registration_flow_state.dart';

void main() {
  group('RegistrationFlowCubit Birim Testleri', () {
    test('1. Cubit oluşturulduğunda role alanı null durumdadır', () {
      final cubit = RegistrationFlowCubit();
      expect(cubit.state.role, isNull);
      expect(cubit.state, equals(const RegistrationFlowState()));
      cubit.close();
    });

    blocTest<RegistrationFlowCubit, RegistrationFlowState>(
      '2. Rol CLIENT olarak seçildiğinde state rölü CLIENT olur',
      build: () => RegistrationFlowCubit(),
      act: (cubit) => cubit.setRole(UserRole.CLIENT),
      expect: () => [
        const RegistrationFlowState(role: UserRole.CLIENT),
      ],
    );

    blocTest<RegistrationFlowCubit, RegistrationFlowState>(
      '3. Rol seçildikten sonra clear çağrıldığında akış sıfırlanır ve role tekrar null olur',
      build: () => RegistrationFlowCubit(),
      act: (cubit) {
        cubit.setRole(UserRole.CLIENT);
        cubit.clear();
      },
      expect: () => [
        const RegistrationFlowState(role: UserRole.CLIENT),
        const RegistrationFlowState(),
      ],
    );

    blocTest<RegistrationFlowCubit, RegistrationFlowState>(
      '4. Kimlik bilgileri set edildikten sonra setRole çağrıldığında mevcut form verileri korunur ve rol güncellenir',
      build: () => RegistrationFlowCubit(),
      act: (cubit) {
        cubit.setCredentials(
          email: 'test@example.com',
          password: 'Password123!',
          phoneNumber: '+905551112233',
          role: UserRole.CLIENT,
        );
        cubit.setRole(UserRole.COACH);
      },
      expect: () => [
        const RegistrationFlowState(
          email: 'test@example.com',
          password: 'Password123!',
          phoneNumber: '+905551112233',
          role: UserRole.CLIENT,
        ),
        const RegistrationFlowState(
          email: 'test@example.com',
          password: 'Password123!',
          phoneNumber: '+905551112233',
          role: UserRole.COACH,
        ),
      ],
    );
  });
}
