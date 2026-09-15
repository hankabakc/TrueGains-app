import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/network_info.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:gymapp_v2/features/training/models/exercise.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';
import 'package:gymapp_v2/features/training/models/completed_set_data.dart';
import 'package:gymapp_v2/features/training/models/assigned_program_models.dart';
import 'package:gymapp_v2/features/training/models/weekly_progress.dart';
import 'package:gymapp_v2/features/training/models/exercise_progress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:gymapp_v2/core/constants/storage_keys.dart';
import 'package:gymapp_v2/core/constants/network_constants.dart';
import '../data/services/training_api_service.dart';

class TrainingRepository {
  final TrainingApiService _apiService;
  final NetworkInfo _networkInfo;
  final SyncManager _syncManager;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  StompClient? _stompClient;

  TrainingRepository({
    required TrainingApiService apiService,
    required NetworkInfo networkInfo,
    required SyncManager syncManager,
  })  : _apiService = apiService,
        _networkInfo = networkInfo,
        _syncManager = syncManager;

  // --- Egzersiz Kütüphanesi ---
  Future<ApiResponse<List<Exercise>>> getAllExercises() {
    return _apiService.getAllExercises();
  }

  // --- Aktif Programlar ---
  Future<ApiResponse<List<TrainingBlock>>> getMyActivePrograms() {
    return _apiService.getMyActivePrograms();
  }

  // --- Yeni Kişisel Program Ekleme ---
  Future<ApiResponse<TrainingBlock>> createPersonalProgram(
    TrainingBlock block,
  ) {
    return _apiService.createPersonalProgram(block.toJson());
  }

  // --- Set Loglama ---
  Future<ApiResponse<WorkoutLog>> logSet(
    int workoutExerciseId,
    WorkoutLog log,
  ) {
    return _apiService.logSet(workoutExerciseId, log.toJson());
  }

  // --- Kişisel Program Güncelleme ---
  Future<ApiResponse<TrainingBlock>> updatePersonalProgram(
    int id,
    TrainingBlock block,
  ) {
    return _apiService.updatePersonalProgram(id, block.toJson());
  }

  // --- İdman Oturumu Kaydetme ---
  Future<ApiResponse<void>> logWorkoutSession({
    required String dayName,
    required int totalSeconds,
    required List<CompletedSetData> sets,
    int? trainingBlockId,
    int? workoutDayId,
  }) async {
    final payload = {
      'workoutDayName': dayName,
      'totalSeconds': totalSeconds,
      'trainingBlockId': trainingBlockId,
      'workoutDayId': workoutDayId,
      'logs':
          sets
              .map(
                (s) => {
                  'workoutExerciseId': s.workoutExerciseId,
                  'setIndex': s.setIndex,
                  'actualWeight': s.weight,
                  'actualReps': s.reps,
                  'durationSeconds': s.durationSeconds,
                  'substituteExerciseId': s.substituteExerciseId,
                },
              )
              .toList(),
    };

    if (await _networkInfo.isConnected) {
      return _apiService.logWorkoutSession(payload);
    } else {
      // Çevrimdışı: Kuyruğa ekle
      await _syncManager.addToQueue(TrainingApiService.sessionsPath, payload);
      // Başarılıymış gibi dön (UI'ın devam edebilmesi için)
      return ApiResponse(
        success: true,
        message: 'Offline kaydedildi.',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  // --- Haftalık İlerleme Durumu ---
  Future<ApiResponse<WeeklyProgress>> getMyWeeklyProgress() {
    return _apiService.getMyWeeklyProgress();
  }

  Future<ApiResponse<WeeklyProgress>> getClientWeeklyProgress(int clientId) {
    return _apiService.getClientWeeklyProgress(clientId);
  }

  Future<ApiResponse<List<WeeklyHistoryItem>>> getMyWeeklyHistory() {
    return _apiService.getMyWeeklyHistory();
  }

  Future<ApiResponse<List<WeeklyHistoryItem>>> getClientWeeklyHistory(int clientId) {
    return _apiService.getClientWeeklyHistory(clientId);
  }

  // --- İdman Geçmişi ---
  Future<ApiResponse<List<Map<String, dynamic>>>> getWorkoutHistory([int? clientId]) {
    return _apiService.getWorkoutHistory(clientId);
  }

  Future<ApiResponse<void>> deletePersonalProgram(int id) {
    return _apiService.deletePersonalProgram(id);
  }

  Future<ApiResponse<void>> deleteWorkoutSession(int id) {
    return _apiService.deleteWorkoutSession(id);
  }

  Future<ApiResponse<List<TrainingBlock>>> getCoachTemplates() {
    return _apiService.getCoachTemplates();
  }

  Future<ApiResponse<List<TrainingBlock>>> getCoachAssignedPrograms() {
    return _apiService.getCoachAssignedPrograms();
  }

  Future<ApiResponse<TrainingBlock>> createCoachTemplate(TrainingBlock block) {
    return _apiService.createCoachTemplate(block.toJson());
  }

  Future<ApiResponse<TrainingBlock>> updateCoachTemplate(
    int id,
    TrainingBlock block,
  ) {
    return _apiService.updateCoachTemplate(id, block.toJson());
  }

  Future<ApiResponse<void>> deleteCoachTemplate(int id) {
    return _apiService.deleteCoachTemplate(id);
  }

  Future<ApiResponse<TrainingBlock>> assignTemplateToClient(
    int templateId,
    int clientId,
  ) {
    return _apiService.assignTemplateToClient(templateId, clientId);
  }

  Future<ApiResponse<List<ProgramWithAssignments>>> getAssignedProgramsV2() {
    return _apiService.getAssignedProgramsV2();
  }

  Future<ApiResponse<void>> unassignProgram(int programId, int studentId) {
    return _apiService.unassignProgram(programId, studentId);
  }

  Future<ApiResponse<void>> activateProgram(int id) {
    return _apiService.activateProgram(id);
  }

  Future<ApiResponse<TrainingBlock>> approveOrphanedProgram(int id, bool keep) {
    return _apiService.approveOrphanedProgram(id, keep);
  }

  Future<ApiResponse<List<ExerciseProgress>>> getExerciseProgress(int exerciseId, {int? clientId}) {
    return _apiService.getExerciseProgress(exerciseId, clientId: clientId);
  }

  // --- WebSocket (Stomp) Abonelik ---
  Future<void> subscribeToTrainingUpdates({
    required int clientId,
    required String wsUrl,
    required void Function() onUpdateReceived,
  }) async {
    _stompClient?.deactivate();

    final token = await _storage.read(key: StorageKeys.accessToken);

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        stompConnectHeaders: {
          if (token != null)
            NetworkConstants.authorizationHeader:
                '${NetworkConstants.bearerPrefix}$token',
        },
        webSocketConnectHeaders: {
          if (token != null)
            NetworkConstants.authorizationHeader:
                '${NetworkConstants.bearerPrefix}$token',
        },
        onConnect: (frame) {
          _stompClient?.subscribe(
            destination: '/topic/training/$clientId',
            callback: (frame) {
              if (frame.body == 'REFRESH_REQUIRED') {
                onUpdateReceived();
              }
            },
          );
        },
        onWebSocketError: (error) {},
        onStompError: (frame) {},
      ),
    );
    _stompClient?.activate();
  }

  void unsubscribeFromTrainingUpdates() {
    _stompClient?.deactivate();
    _stompClient = null;
  }

  Future<int> getDefaultRestSeconds() async {
    final val = await _storage.read(key: StorageKeys.defaultRestSeconds);
    return int.tryParse(val ?? '') ?? 90;
  }

  Future<void> saveDefaultRestSeconds(int seconds) async {
    await _storage.write(key: StorageKeys.defaultRestSeconds, value: seconds.toString());
  }
}
