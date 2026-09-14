import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import '../../../../profile/data/repositories/profile_repository.dart';
import '../../../data/models/coach_specialization.dart';
import '../../../data/models/discovery_user_model.dart';
import '../../../data/repositories/social_repository.dart';
import 'discovery_state.dart';

class DiscoveryCubit extends Cubit<DiscoveryState> {
  final SocialRepository _repository;
  final ProfileRepository _profileRepository;

  DiscoveryCubit(this._repository, this._profileRepository) : super(const DiscoveryState());

  Future<void> updateSearchFilters({CoachSpecialization? specialization, String? searchQuery}) async {
    emit(state.copyWith(
      selectedSpecialization: specialization,
      searchQuery: searchQuery,
    ));
    await loadUsers(role: UserRole.COACH);
  }

  /// Tek filtre paneli hepsini birlikte uyguluyor; uzmanlık da bu çağrıya
  /// dahil olmasa "Uygula" arka arkaya iki ağ isteği atardı.
  Future<void> updateCoachSortFilter({
    String? sort,
    double? minRating,
    CoachSpecialization? specialization,
    bool clearFilters = false,
    bool clearMinRating = false,
  }) async {
    if (clearFilters) {
      emit(state.copyWith(
        sortOption: 'rating',
        selectedSpecialization: CoachSpecialization.all,
        clearMinRating: true,
      ));
    } else {
      emit(state.copyWith(
        sortOption: sort,
        minRating: minRating,
        selectedSpecialization: specialization,
        clearMinRating: clearMinRating,
      ));
    }
    await loadUsers(role: UserRole.COACH);
  }

  Future<void> fetchUserProfile(int userId) async {
    emit(state.copyWith(status: DiscoveryStatus.loading));
    try {
      final result = await _profileRepository.getClientProfile(userId);
      if (result.success && result.data != null) {
        emit(state.copyWith(
          status: DiscoveryStatus.success,
          selectedUserProfile: result.data,
        ));
      } else {
        emit(state.copyWith(
          status: DiscoveryStatus.failure,
          error: result.message,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DiscoveryStatus.failure,
        error: 'Profil yüklenirken bir hata oluştu: $e',
      ));
    }
  }

  void clearSelectedUserProfile() {
    emit(state.copyWith(clearSelectedUserProfile: true));
  }

  Future<void> loadUsers({required UserRole role, bool nextPage = false}) async {
    final bool isCoach = role == UserRole.COACH;
    final int currentPage = isCoach ? state.currentCoachPage : state.currentClientPage;
    final bool isLastPage = isCoach ? state.isCoachLastPage : state.isClientLastPage;

    if (nextPage && isLastPage) return;

    final int page = nextPage ? currentPage + 1 : 0;

    emit(state.copyWith(
      status: nextPage ? DiscoveryStatus.loadingMore : DiscoveryStatus.loading,
    ));

    try {
      if (isCoach) {
        final result = await _repository.discoverCoaches(
          specialization: state.selectedSpecialization?.apiValue,
          name: state.searchQuery,
          minRating: state.minRating,
          sort: state.sortOption,
          page: page,
        );

        if (result.success && result.data != null) {
          final pageData = result.data!;
          final List<DiscoveryUserModel> coachUsers = pageData.content.map((coach) {
            return DiscoveryUserModel(
              userId: coach.userId,
              fullName: coach.fullName,
              bio: coach.bio,
              profilePhotoUrl: coach.profilePhotoUrl,
              role: UserRole.COACH,
              specialization: coach.specialization,
              currency: coach.currency,
              canSendRequest: true,
              averageRating: coach.averageRating,
              reviewCount: coach.reviewCount,
              activeStudentCount: coach.activeStudentCount,
              province: coach.province,
              district: coach.district,
              experienceYears: coach.experienceYears,
              minPackagePrice: coach.minPackagePrice,
            );
          }).toList();

          final updatedCoaches = nextPage
              ? [...state.coaches, ...coachUsers]
              : coachUsers;

          emit(state.copyWith(
            status: DiscoveryStatus.success,
            coaches: updatedCoaches,
            currentCoachPage: page,
            isCoachLastPage: pageData.isLast,
          ));
        } else {
          emit(state.copyWith(
            status: DiscoveryStatus.failure,
            error: result.message,
          ));
        }
      } else {
        final result = await _repository.discoverUsers(
          role: role,
          page: page,
        );

        if (result.success && result.data != null) {
          final pageData = result.data!;
          final updatedClients = nextPage
              ? [...state.clients, ...pageData.content]
              : pageData.content;
          emit(state.copyWith(
            status: DiscoveryStatus.success,
            clients: updatedClients,
            currentClientPage: page,
            isClientLastPage: pageData.isLast,
          ));
        } else {
          emit(state.copyWith(
            status: DiscoveryStatus.failure,
            error: result.message,
          ));
        }
      }
    } catch (e) {
      emit(state.copyWith(
        status: DiscoveryStatus.failure,
        error: 'Keşfetme sırasında hata oluştu: $e',
      ));
    }
  }
}
