import 'package:equatable/equatable.dart';
import '../../../../profile/data/models/client_profile_response_model.dart';
import '../../../data/models/coach_specialization.dart';
import '../../../data/models/discovery_user_model.dart';

enum DiscoveryStatus { initial, loading, success, failure, loadingMore }

class DiscoveryState extends Equatable {
  final DiscoveryStatus status;
  final List<DiscoveryUserModel> coaches;
  final List<DiscoveryUserModel> clients;
  final int currentCoachPage;
  final int currentClientPage;
  final bool isCoachLastPage;
  final bool isClientLastPage;
  final String? error;
  final CoachSpecialization? selectedSpecialization;
  final String searchQuery;
  final ClientProfileResponseModel? selectedUserProfile;
  final String sortOption;
  final double? minRating;

  const DiscoveryState({
    this.status = DiscoveryStatus.initial,
    this.coaches = const [],
    this.clients = const [],
    this.currentCoachPage = 0,
    this.currentClientPage = 0,
    this.isCoachLastPage = false,
    this.isClientLastPage = false,
    this.error,
    this.selectedSpecialization = CoachSpecialization.all,
    this.searchQuery = '',
    this.selectedUserProfile,
    this.sortOption = 'rating',
    this.minRating,
  });

  DiscoveryState copyWith({
    DiscoveryStatus? status,
    List<DiscoveryUserModel>? coaches,
    List<DiscoveryUserModel>? clients,
    int? currentCoachPage,
    int? currentClientPage,
    bool? isCoachLastPage,
    bool? isClientLastPage,
    String? error,
    CoachSpecialization? selectedSpecialization,
    String? searchQuery,
    ClientProfileResponseModel? selectedUserProfile,
    String? sortOption,
    double? minRating,
    bool clearMinRating = false,
    bool clearSelectedUserProfile = false,
  }) {
    return DiscoveryState(
      status: status ?? this.status,
      coaches: coaches ?? this.coaches,
      clients: clients ?? this.clients,
      currentCoachPage: currentCoachPage ?? this.currentCoachPage,
      currentClientPage: currentClientPage ?? this.currentClientPage,
      isCoachLastPage: isCoachLastPage ?? this.isCoachLastPage,
      isClientLastPage: isClientLastPage ?? this.isClientLastPage,
      error: error ?? this.error,
      selectedSpecialization: selectedSpecialization ?? this.selectedSpecialization,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedUserProfile: clearSelectedUserProfile
          ? null
          : (selectedUserProfile ?? this.selectedUserProfile),
      sortOption: sortOption ?? this.sortOption,
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
    );
  }

  @override
  List<Object?> get props => [
    status,
    coaches,
    clients,
    currentCoachPage,
    currentClientPage,
    isCoachLastPage,
    isClientLastPage,
    error,
    selectedSpecialization,
    searchQuery,
    selectedUserProfile,
    sortOption,
    minRating,
  ];
}
