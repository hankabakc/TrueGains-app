import 'package:dio/dio.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/features/training/models/exercise.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';
import 'package:gymapp_v2/features/training/models/assigned_program_models.dart';
import 'package:gymapp_v2/features/training/models/weekly_progress.dart';
import 'package:gymapp_v2/features/training/models/exercise_progress.dart';

class TrainingApiService {
  final DioClient _dioClient;

  TrainingApiService(this._dioClient);

  Future<ApiResponse<List<Exercise>>> getAllExercises() async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>('/training/exercises');
      return ApiResponse<List<Exercise>>.fromJson(
        response.data!,
        (json) =>
            (json as List)
                .map((i) => Exercise.fromJson(i as Map<String, dynamic>))
                .toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<TrainingBlock>>> getMyActivePrograms() async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>('/training/programs');
      return ApiResponse<List<TrainingBlock>>.fromJson(
        response.data!,
        (json) =>
            (json as List)
                .map((i) => TrainingBlock.fromJson(i as Map<String, dynamic>))
                .toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<TrainingBlock>> createPersonalProgram(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/training/programs/personal',
        data: data,
      );
      return ApiResponse<TrainingBlock>.fromJson(
        response.data!,
        (json) => TrainingBlock.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<WorkoutLog>> logSet(
    int workoutExerciseId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/training/log/$workoutExerciseId',
        data: data,
      );
      return ApiResponse<WorkoutLog>.fromJson(
        response.data!,
        (json) => WorkoutLog.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<TrainingBlock>> updatePersonalProgram(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.dio.put<Map<String, dynamic>>(
        '/training/programs/personal/$id',
        data: data,
      );
      return ApiResponse<TrainingBlock>.fromJson(
        response.data!,
        (json) => TrainingBlock.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> logWorkoutSession(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/training/sessions',
        data: data,
      );
      return ApiResponse<void>.fromJson(response.data!, (json) {});
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getWorkoutHistory([int? clientId]) async {
    try {
      final url = clientId != null
          ? '/training/sessions/history/$clientId'
          : '/training/sessions/history';
      final response = await _dioClient.dio.get<Map<String, dynamic>>(url);
      return ApiResponse<List<Map<String, dynamic>>>.fromJson(
        response.data!,
        (json) => (json as List).map((e) => e as Map<String, dynamic>).toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> deletePersonalProgram(int id) async {
    try {
      final response = await _dioClient.dio.delete<Map<String, dynamic>>(
        '/training/programs/personal/$id',
      );
      return ApiResponse<void>.fromJson(response.data!, (json) {});
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> deleteWorkoutSession(int id) async {
    try {
      final response = await _dioClient.dio.delete<Map<String, dynamic>>(
        '/training/sessions/$id',
      );
      return ApiResponse<void>.fromJson(response.data!, (json) {});
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<TrainingBlock>>> getCoachTemplates() async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>('/training/templates');
      return ApiResponse<List<TrainingBlock>>.fromJson(
        response.data!,
        (json) =>
            (json as List)
                .map((i) => TrainingBlock.fromJson(i as Map<String, dynamic>))
                .toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<TrainingBlock>>> getCoachAssignedPrograms() async {
    try {
      final response =
          await _dioClient.dio.get<Map<String, dynamic>>('/training/assigned');
      return ApiResponse<List<TrainingBlock>>.fromJson(
        response.data!,
        (json) =>
            (json as List)
                .map((i) => TrainingBlock.fromJson(i as Map<String, dynamic>))
                .toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<TrainingBlock>> createCoachTemplate(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/training/templates',
        data: data,
      );
      return ApiResponse<TrainingBlock>.fromJson(
        response.data!,
        (json) => TrainingBlock.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<TrainingBlock>> updateCoachTemplate(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.dio.put<Map<String, dynamic>>(
        '/training/templates/$id',
        data: data,
      );
      return ApiResponse<TrainingBlock>.fromJson(
        response.data!,
        (json) => TrainingBlock.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> deleteCoachTemplate(int id) async {
    try {
      final response = await _dioClient.dio.delete<Map<String, dynamic>>(
        '/training/templates/$id',
      );
      return ApiResponse<void>.fromJson(response.data!, (json) {});
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<TrainingBlock>> assignTemplateToClient(
    int templateId,
    int clientId,
  ) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/training/assign/$templateId/$clientId',
      );
      return ApiResponse<TrainingBlock>.fromJson(
        response.data!,
        (json) => TrainingBlock.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<ProgramWithAssignments>>> getAssignedProgramsV2() async {
    try {
      final response =
          await _dioClient.dio.get<Map<String, dynamic>>('/coaches/programs/assigned');
      return ApiResponse<List<ProgramWithAssignments>>.fromJson(
        response.data!,
        (json) => (json as List)
            .map((i) => ProgramWithAssignments.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> unassignProgram(int programId, int studentId) async {
    try {
      final response = await _dioClient.dio.delete<Map<String, dynamic>>(
        '/coaches/programs/unassign/$programId/$studentId',
      );
      return ApiResponse<void>.fromJson(response.data!, (json) {});
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> activateProgram(int id) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/training/activate/$id',
      );
      return ApiResponse<void>.fromJson(response.data!, (json) {});
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<TrainingBlock>> approveOrphanedProgram(int id, bool keep) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/training/programs/approve-orphan/$id',
        queryParameters: {'keep': keep},
      );
      return ApiResponse<TrainingBlock>.fromJson(
        response.data!,
        (json) => TrainingBlock.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<WeeklyProgress>> getMyWeeklyProgress() async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/training/progress/me',
      );
      return ApiResponse<WeeklyProgress>.fromJson(
        response.data!,
        (json) => WeeklyProgress.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<WeeklyProgress>> getClientWeeklyProgress(int clientId) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/training/progress/$clientId',
      );
      return ApiResponse<WeeklyProgress>.fromJson(
        response.data!,
        (json) => WeeklyProgress.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<WeeklyHistoryItem>>> getMyWeeklyHistory() async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/training/progress/weekly-history',
      );
      return ApiResponse<List<WeeklyHistoryItem>>.fromJson(
        response.data!,
        (json) => (json as List)
            .map((i) => WeeklyHistoryItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<WeeklyHistoryItem>>> getClientWeeklyHistory(int clientId) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/training/progress/weekly-history/$clientId',
      );
      return ApiResponse<List<WeeklyHistoryItem>>.fromJson(
        response.data!,
        (json) => (json as List)
            .map((i) => WeeklyHistoryItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<ExerciseProgress>>> getExerciseProgress(int exerciseId, {int? clientId}) async {
    try {
      final url = clientId == null
          ? '/training/progress/exercise/$exerciseId'
          : '/training/progress/exercise/$clientId/$exerciseId';
      final response = await _dioClient.dio.get<Map<String, dynamic>>(url);
      return ApiResponse<List<ExerciseProgress>>.fromJson(
        response.data!,
        (json) =>
            (json as List)
                .map((i) => ExerciseProgress.fromJson(i as Map<String, dynamic>))
                .toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  ApiResponse<T> _handleError<T>(DioException e) {
    String message = 'Antrenman servisi hatası';
    if (e.response?.statusCode == 409) {
      message = 'Eş zamanlı güncelleme çakışması: Veri başka bir yerde güncellenmiş. Lütfen sayfayı yenileyip tekrar deneyin.';
    } else if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        message = (data['message'] as String?) ?? 'İşlem başarısız';
      }
    }
    return ApiResponse<T>.error(message);
  }
}
