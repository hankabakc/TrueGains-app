import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/page_response.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/profile/data/models/client_profile_response_model.dart';
import 'package:gymapp_v2/features/social/data/models/coach_discovery_model.dart';
import 'package:gymapp_v2/features/social/data/models/discovery_user_model.dart';
import 'package:gymapp_v2/features/social/data/repositories/social_repository.dart';
import 'package:gymapp_v2/features/profile/data/repositories/profile_repository.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/discovery/discovery_cubit.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/discovery/discovery_state.dart';

class MockSocialRepository extends Mock implements SocialRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockSocialRepository socialRepository;
  late MockProfileRepository profileRepository;

  setUp(() {
    socialRepository = MockSocialRepository();
    profileRepository = MockProfileRepository();
  });

  CoachDiscoveryModel sampleCoach(int id, String name) => CoachDiscoveryModel(
        userId: id,
        fullName: name,
        bio: 'Koç biyografi',
        specialization: 'FITNESS',
        currency: 'TRY',
        profilePhotoUrl: null,
        averageRating: 4.8,
        reviewCount: 12,
        activeStudentCount: 5,
      );

  DiscoveryUserModel sampleClient(int id, String name) => DiscoveryUserModel(
        userId: id,
        fullName: name,
        bio: 'Sporcu biyografi',
        profilePhotoUrl: null,
        role: UserRole.CLIENT,
        canSendRequest: true,
      );

  ClientProfileResponseModel sampleProfile(int id, String name) =>
      ClientProfileResponseModel(
        userId: id,
        fullName: name,
        email: '$name@test.com',
        showAge: false,
        showHeight: false,
        showWeight: false,
      );

  PageResponse<T> pageResp<T>({
    required List<T> content,
    required int page,
    required int totalPages,
    int size = 10,
    int totalElements = 10,
  }) =>
      PageResponse<T>(
        content: content,
        page: page,
        size: size,
        totalElements: totalElements,
        totalPages: totalPages,
      );

  ApiResponse<T> ok<T>(T data) => ApiResponse<T>(
        success: true,
        message: '',
        data: data,
        timestamp: '',
      );

  ApiResponse<T> fail<T>(String m) => ApiResponse<T>(
        success: false,
        message: m,
        data: null,
        timestamp: '',
      );

  group('DiscoveryCubit - loadUsers', () {
    blocTest<DiscoveryCubit, DiscoveryState>(
      'ilk yükleme koç listesini dolduruyor',
      build: () {
        when(() => socialRepository.discoverCoaches(
              specialization: '',
              name: '',
              minRating: null,
              sort: 'rating',
              page: 0,
            )).thenAnswer(
          (_) async => ok(pageResp(
            content: [sampleCoach(1, 'Ahmet Koç')],
            page: 0,
            totalPages: 3,
            totalElements: 30,
          )),
        );
        return DiscoveryCubit(socialRepository, profileRepository);
      },
      act: (cubit) => cubit.loadUsers(role: UserRole.COACH),
      expect: () => [
        predicate<DiscoveryState>((s) => s.status == DiscoveryStatus.loading),
        predicate<DiscoveryState>(
          (s) =>
              s.status == DiscoveryStatus.success &&
              s.coaches.length == 1 &&
              s.coaches.first.userId == 1 &&
              s.currentCoachPage == 0 &&
              s.isCoachLastPage == false,
        ),
      ],
      verify: (_) {
        verify(() => socialRepository.discoverCoaches(
              specialization: '',
              name: '',
              minRating: null,
              sort: 'rating',
              page: 0,
            )).called(1);
      },
    );

    blocTest<DiscoveryCubit, DiscoveryState>(
      'son sayfadayken sonraki sayfa istenmiyor',
      build: () => DiscoveryCubit(socialRepository, profileRepository),
      seed: () => const DiscoveryState(
        isCoachLastPage: true,
        currentCoachPage: 2,
      ),
      act: (cubit) => cubit.loadUsers(role: UserRole.COACH, nextPage: true),
      expect: () => <DiscoveryState>[],
      verify: (_) {
        verifyZeroInteractions(socialRepository);
      },
    );

    final coachA = sampleClient(1, 'Koç 1');
    final coachB = sampleCoach(2, 'Koç 2');
    blocTest<DiscoveryCubit, DiscoveryState>(
      'sonraki sayfa listeye EKLENİYOR, değiştirmiyor',
      build: () {
        when(() => socialRepository.discoverCoaches(
              specialization: '',
              name: '',
              minRating: null,
              sort: 'rating',
              page: 1,
            )).thenAnswer(
          (_) async => ok(pageResp(
            content: [coachB],
            page: 1,
            totalPages: 3,
            totalElements: 30,
          )),
        );
        return DiscoveryCubit(socialRepository, profileRepository);
      },
      seed: () => DiscoveryState(
        coaches: [coachA],
        currentCoachPage: 0,
      ),
      act: (cubit) => cubit.loadUsers(role: UserRole.COACH, nextPage: true),
      expect: () => [
        predicate<DiscoveryState>(
            (s) => s.status == DiscoveryStatus.loadingMore),
        predicate<DiscoveryState>(
          (s) =>
              s.status == DiscoveryStatus.success &&
              s.coaches.length == 2 &&
              s.coaches[0].userId == 1 &&
              s.coaches[1].userId == 2 &&
              s.currentCoachPage == 1,
        ),
      ],
      verify: (_) {
        verify(() => socialRepository.discoverCoaches(
              specialization: '',
              name: '',
              minRating: null,
              sort: 'rating',
              page: 1,
            )).called(1);
      },
    );

    final clientX = sampleClient(99, 'Sporcu X');
    blocTest<DiscoveryCubit, DiscoveryState>(
      'koç yüklemesi sporcu izini bozmuyor',
      build: () {
        when(() => socialRepository.discoverCoaches(
              specialization: '',
              name: '',
              minRating: null,
              sort: 'rating',
              page: 0,
            )).thenAnswer(
          (_) async => ok(pageResp(
            content: [sampleCoach(1, 'Koç 1')],
            page: 0,
            totalPages: 1,
            totalElements: 1,
          )),
        );
        return DiscoveryCubit(socialRepository, profileRepository);
      },
      seed: () => DiscoveryState(
        clients: [clientX],
        currentClientPage: 2,
        isClientLastPage: true,
      ),
      act: (cubit) => cubit.loadUsers(role: UserRole.COACH),
      expect: () => [
        predicate<DiscoveryState>((s) => s.status == DiscoveryStatus.loading),
        predicate<DiscoveryState>(
          (s) =>
              s.status == DiscoveryStatus.success &&
              s.clients.length == 1 &&
              s.clients.first.userId == 99 &&
              s.currentClientPage == 2 &&
              s.isClientLastPage == true,
        ),
      ],
    );

    blocTest<DiscoveryCubit, DiscoveryState>(
      'son sayfa bayrağı taşınıyor',
      build: () {
        when(() => socialRepository.discoverCoaches(
              specialization: '',
              name: '',
              minRating: null,
              sort: 'rating',
              page: 0,
            )).thenAnswer(
          (_) async => ok(pageResp(
            content: [sampleCoach(1, 'Koç Tek')],
            page: 0,
            totalPages: 1,
            totalElements: 1,
          )),
        );
        return DiscoveryCubit(socialRepository, profileRepository);
      },
      act: (cubit) => cubit.loadUsers(role: UserRole.COACH),
      expect: () => [
        predicate<DiscoveryState>((s) => s.status == DiscoveryStatus.loading),
        predicate<DiscoveryState>(
          (s) =>
              s.status == DiscoveryStatus.success && s.isCoachLastPage == true,
        ),
      ],
    );

    blocTest<DiscoveryCubit, DiscoveryState>(
      'hata failure üretiyor',
      build: () {
        when(() => socialRepository.discoverCoaches(
              specialization: '',
              name: '',
              minRating: null,
              sort: 'rating',
              page: 0,
            )).thenAnswer((_) async => fail('Sunucu hatası'));
        return DiscoveryCubit(socialRepository, profileRepository);
      },
      act: (cubit) => cubit.loadUsers(role: UserRole.COACH),
      expect: () => [
        predicate<DiscoveryState>((s) => s.status == DiscoveryStatus.loading),
        predicate<DiscoveryState>(
          (s) =>
              s.status == DiscoveryStatus.failure && s.error == 'Sunucu hatası',
        ),
      ],
    );

    blocTest<DiscoveryCubit, DiscoveryState>(
      'sporcu yüklemesi clients izine yazıyor',
      build: () {
        when(() => socialRepository.discoverUsers(
              role: UserRole.CLIENT,
              page: 0,
            )).thenAnswer(
          (_) async => ok(pageResp(
            content: [sampleClient(10, 'Ali Sporcu')],
            page: 0,
            totalPages: 1,
            totalElements: 1,
          )),
        );
        return DiscoveryCubit(socialRepository, profileRepository);
      },
      act: (cubit) => cubit.loadUsers(role: UserRole.CLIENT),
      expect: () => [
        predicate<DiscoveryState>((s) => s.status == DiscoveryStatus.loading),
        predicate<DiscoveryState>(
          (s) =>
              s.status == DiscoveryStatus.success &&
              s.clients.length == 1 &&
              s.clients.first.userId == 10 &&
              s.coaches.isEmpty &&
              s.currentClientPage == 0 &&
              s.isClientLastPage == true,
        ),
      ],
      verify: (_) {
        verify(() => socialRepository.discoverUsers(
              role: UserRole.CLIENT,
              page: 0,
            )).called(1);
        verifyNever(() => socialRepository.discoverCoaches(
              specialization: '',
              name: '',
              minRating: null,
              sort: 'rating',
              page: 0,
            ));
      },
    );
  });

  group('DiscoveryCubit - selectedUserProfile', () {
    test('aynı profil art arda iki kez açılabiliyor', () async {
      when(() => profileRepository.getClientProfile(5))
          .thenAnswer((_) async => ok(sampleProfile(5, 'Test Sporcu')));

      final cubit = DiscoveryCubit(socialRepository, profileRepository);

      await cubit.fetchUserProfile(5);
      expect(cubit.state.selectedUserProfile?.userId, 5);

      cubit.clearSelectedUserProfile();
      expect(cubit.state.selectedUserProfile, isNull);

      await cubit.fetchUserProfile(5);
      expect(cubit.state.selectedUserProfile?.userId, 5);

      await cubit.close();
    });

    blocTest<DiscoveryCubit, DiscoveryState>(
      'temizleme diğer alanları bozmuyor',
      build: () => DiscoveryCubit(socialRepository, profileRepository),
      seed: () => DiscoveryState(
        coaches: [sampleClient(1, 'Koç 1')],
        searchQuery: 'ali',
        selectedUserProfile: sampleProfile(5, 'Sporcu 5'),
      ),
      act: (cubit) => cubit.clearSelectedUserProfile(),
      expect: () => [
        predicate<DiscoveryState>(
          (s) =>
              s.selectedUserProfile == null &&
              s.coaches.length == 1 &&
              s.coaches.first.userId == 1 &&
              s.searchQuery == 'ali',
        ),
      ],
    );

    blocTest<DiscoveryCubit, DiscoveryState>(
      'fetchUserProfile userId yi birebir iletiyor',
      build: () {
        when(() => profileRepository.getClientProfile(5))
            .thenAnswer((_) async => ok(sampleProfile(5, 'Test Sporcu')));
        return DiscoveryCubit(socialRepository, profileRepository);
      },
      act: (cubit) => cubit.fetchUserProfile(5),
      verify: (_) {
        verify(() => profileRepository.getClientProfile(5)).called(1);
      },
    );

    blocTest<DiscoveryCubit, DiscoveryState>(
      'profil çekilemezse failure üretiliyor',
      build: () {
        when(() => profileRepository.getClientProfile(5))
            .thenAnswer((_) async => fail('Profil bulunamadı'));
        return DiscoveryCubit(socialRepository, profileRepository);
      },
      act: (cubit) => cubit.fetchUserProfile(5),
      expect: () => [
        predicate<DiscoveryState>((s) => s.status == DiscoveryStatus.loading),
        predicate<DiscoveryState>(
          (s) =>
              s.status == DiscoveryStatus.failure &&
              s.error == 'Profil bulunamadı',
        ),
      ],
    );
  });
}

