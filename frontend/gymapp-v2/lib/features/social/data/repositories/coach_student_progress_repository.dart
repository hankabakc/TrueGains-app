import '../models/coach_student_progress_model.dart';
import '../services/coach_student_progress_api_service.dart';
import '../../../../core/network/api_response.dart';

class CoachStudentProgressRepository {
  final CoachStudentProgressApiService _apiService;

  CoachStudentProgressRepository(this._apiService);

  Future<ApiResponse<CoachStudentProgressModel>> createProgressRequest({
    required int clientId,
    required String studentNickname,
    required String beforeImageUrl,
    required String afterImageUrl,
    String? description,
  }) {
    return _apiService.createProgressRequest(
      clientId: clientId,
      studentNickname: studentNickname,
      beforeImageUrl: beforeImageUrl,
      afterImageUrl: afterImageUrl,
      description: description,
    );
  }

  Future<ApiResponse<List<CoachStudentProgressModel>>> getPendingRequests() {
    return _apiService.getPendingRequests();
  }

  Future<ApiResponse<CoachStudentProgressModel>> respondToRequest(int requestId, bool approved) {
    return _apiService.respondToRequest(requestId, approved);
  }

  Future<ApiResponse<List<CoachStudentProgressModel>>> getApprovedProgress(int coachId) {
    return _apiService.getApprovedProgress(coachId);
  }
}
