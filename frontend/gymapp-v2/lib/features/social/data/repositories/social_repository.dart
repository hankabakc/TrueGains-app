import 'package:gymapp_v2/core/network/page_response.dart';
import '../models/coach_discovery_model.dart';
import '../models/discovery_user_model.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import '../models/pairing_request_model.dart';
import '../services/social_api_service.dart';
import 'package:gymapp_v2/core/network/api_response.dart';

class SocialRepository {
  final SocialApiService _apiService;

  SocialRepository(this._apiService);

  Future<ApiResponse<PageResponse<CoachDiscoveryModel>>> discoverCoaches({
    String? specialization,
    String? name,
    double? minRating,
    String sort = 'rating',
    int page = 0,
    int size = 10,
  }) {
    return _apiService.discoverCoaches(
      specialization: specialization,
      name: name,
      minRating: minRating,
      sort: sort,
      page: page,
      size: size,
    );
  }

  Future<ApiResponse<PageResponse<DiscoveryUserModel>>> discoverUsers({
    required UserRole role,
    int page = 0,
    int size = 10,
  }) {
    return _apiService.discoverUsers(
      role: role,
      page: page,
      size: size,
    );
  }

  Future<ApiResponse<PairingRequestModel>> sendPairingRequest(
    int coachId,
    String message,
  ) {
    return _apiService.sendPairingRequest(coachId, message);
  }

  Future<ApiResponse<void>> sendCoachRequest(int coachId) {
    return _apiService.sendCoachRequest(coachId);
  }

  Future<ApiResponse<List<PairingRequestModel>>> getPendingRequests() {
    return _apiService.getPendingRequests();
  }

  Future<ApiResponse<void>> respondToRequest(int requestId, bool accepted) {
    return _apiService.respondToRequest(requestId, accepted);
  }

  Future<ApiResponse<List<DiscoveryUserModel>>> getMyClients() {
    return _apiService.getMyClients();
  }
}
