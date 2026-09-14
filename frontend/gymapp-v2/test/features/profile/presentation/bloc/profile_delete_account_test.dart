import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/features/profile/data/repositories/profile_repository.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_event.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_state.dart';
import 'package:gymapp_v2/features/social/data/services/file_api_service.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockFileApiService extends Mock implements FileApiService {}

void main() {
  late MockProfileRepository repository;
  late MockFileApiService fileApiService;
  late ProfileBloc bloc;

  setUp(() {
    repository = MockProfileRepository();
    fileApiService = MockFileApiService();
    bloc = ProfileBloc(repository, fileApiService);
  });

  tearDown(() {
    bloc.close();
  });

  group('DeleteAccount', () {
    blocTest<ProfileBloc, ProfileState>(
      'başarılı silme durumunda AccountDeleteSuccess döner',
      build: () {
        when(() => repository.deleteMyAccount()).thenAnswer(
          (_) async => ApiResponse<void>(
            success: true,
            message: 'Hesap başarıyla silindi.',
            timestamp: '2026-08-20T00:00:00Z',
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const DeleteAccount()),
      expect: () => [
        isA<ProfileLoading>(),
        isA<AccountDeleteSuccess>(),
      ],
      verify: (_) {
        verify(() => repository.deleteMyAccount()).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'sunucu reddederse ProfileError ve hata mesajı korunur',
      build: () {
        when(() => repository.deleteMyAccount()).thenAnswer(
          (_) async => ApiResponse<void>(
            success: false,
            message: 'Aktif aboneliğiniz var.',
            timestamp: '2026-08-20T00:00:00Z',
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const DeleteAccount()),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>().having((s) => s.message, 'message', 'Aktif aboneliğiniz var.'),
      ],
      verify: (_) {
        verify(() => repository.deleteMyAccount()).called(1);
      },
    );
  });
}
