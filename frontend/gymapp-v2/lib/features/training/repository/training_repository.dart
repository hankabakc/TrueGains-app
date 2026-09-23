import 'dart:async';

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
import 'package:uuid/uuid.dart';
import '../data/services/training_api_service.dart';

class TrainingRepository {
  static const String _queuedMessage = 'Program cihaza kaydedildi; internet gelince aktarılacak.';
  static const String _sentMeanwhileMessage =
      'Program bu sırada sunucuya aktarıldı. Liste yenilendikten sonra işlemi tekrarlayın.';

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
  /// Sunucudaki programlar ve kuyruktaki kişisel program değişiklikleri (KR13, G-74): internetsiz oluşturulan program
  /// "bekliyor" olarak eklenir, düzenlenen programın yeni hâli görünür, silinmeyi bekleyen program gizlenir.
  Future<ApiResponse<List<TrainingBlock>>> getMyActivePrograms() async {
    final ApiResponse<List<TrainingBlock>> res = await _apiService.getMyActivePrograms();
    final List<PendingRecord> queued = _queuedProgramRecords();
    if (queued.isEmpty) return res;
    // Bağlantı varken sunucu hatası örtülmez; internetsiz ve önbelleksizse yalnızca kuyruktakiler görünür.
    if (!res.success && await _networkInfo.isConnected) return res;

    final List<TrainingBlock> programs = <TrainingBlock>[...?res.data];
    for (final PendingRecord r in queued) {
      if (r.endpoint == TrainingApiService.personalProgramsPath) {
        programs.add(TrainingBlock.fromJson(r.payload, isQueued: true));
        continue;
      }
      if (r.endpoint.startsWith('${TrainingApiService.activatePath}/')) {
        // Etkinleştirme: kuyruk sırasıyla uygulanır, son etkinleştirilen tek aktif program olur.
        final int target = programs.indexWhere((TrainingBlock p) => _activationPathOf(p) == r.endpoint);
        if (target < 0) continue;
        for (int i = 0; i < programs.length; i++) {
          programs[i] = programs[i].withActive(i == target);
        }
        continue;
      }
      final int? id = int.tryParse(r.endpoint.substring(TrainingApiService.personalProgramsPath.length + 1));
      final int index = programs.indexWhere((TrainingBlock p) => p.id == id);
      if (index < 0) continue;
      if (r.method == SyncManager.methodDelete) {
        programs.removeAt(index);
      } else {
        // İçerik kuyruktaki düzenlemeden; aktiflik sunucunun tuttuğu durum (düzenleme onu değiştirmez).
        programs[index] = TrainingBlock.fromJson(
          <String, dynamic>{...r.payload, 'id': id, 'is_active': programs[index].isActive},
          isQueued: true,
        );
      }
    }
    return ApiResponse<List<TrainingBlock>>(
      success: true,
      message: res.message,
      data: programs,
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  // --- Yeni Kişisel Program Ekleme ---
  /// Bağlantı yoksa kuyruğa girer (KR13, G-74); program cihazda kimlik alır, kuyruktan bir kez yazılır. Kimliği olan
  /// blok kuyruktaki (henüz gönderilmemiş) programın düzenlemesidir: aynı kuyruk kaydının yükü değişir, ikinci program
  /// açılmaz.
  Future<ApiResponse<TrainingBlock>> createPersonalProgram(
    TrainingBlock block,
  ) async {
    final String localId = block.localId ?? const Uuid().v4();
    final Map<String, dynamic> payload = <String, dynamic>{...block.toJson(), 'local_id': localId};

    if (block.localId != null) {
      final PendingRecord? queued = _queuedCreateOf(localId);
      if (queued != null && await _syncManager.replacePayload(queued.key, payload)) {
        return _queuedResult(payload);
      }
      // Kayıt gönderildi ya da tam o an gönderiliyor: yeniden oluşturma sunucuda ilk hâli döndürür, düzenleme sessizce
      // kaybolurdu. Taslak ekranda kalır; liste gönderimden sonra yenilenir.
      return ApiResponse<TrainingBlock>.error(_sentMeanwhileMessage);
    }

    if (await _networkInfo.isConnected) {
      return _apiService.createPersonalProgram(payload);
    }
    await _syncManager.addToQueue(TrainingApiService.personalProgramsPath, payload);
    return _queuedResult(payload);
  }

  ApiResponse<TrainingBlock> _queuedResult(Map<String, dynamic> payload) {
    return ApiResponse<TrainingBlock>(
      success: true,
      message: _queuedMessage,
      data: TrainingBlock.fromJson(payload, isQueued: true),
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  /// Oturumdaki kullanıcının kuyruktaki (gönderilmemiş, reddedilmemiş) kişisel program ve etkinleştirme kayıtları,
  /// eklenme sırasıyla.
  List<PendingRecord> _queuedProgramRecords() {
    const String path = TrainingApiService.personalProgramsPath;
    return _syncManager
        .pendingRecords()
        .where((PendingRecord r) =>
            r.endpoint == path ||
            r.endpoint.startsWith('$path/') ||
            r.endpoint.startsWith('${TrainingApiService.activatePath}/'))
        .toList();
  }

  /// Programın etkinleştirme ucu: sunucuya gitmemiş program (id 0) yerel kimlikle (G-74).
  static String _activationPathOf(TrainingBlock program) => program.id == 0
      ? '${TrainingApiService.activatePath}/local/${program.localId}'
      : '${TrainingApiService.activatePath}/${program.id}';

  /// Henüz sunucuya gitmemiş programın kuyruktaki oluşturma kaydı.
  PendingRecord? _queuedCreateOf(String localId) => _queuedProgramRecords()
      .where((PendingRecord r) =>
          r.endpoint == TrainingApiService.personalProgramsPath && r.payload['local_id'] == localId)
      .firstOrNull;

  /// Programın kuyruktaki (gönderilmemiş) düzenlemesi.
  PendingRecord? _queuedEditOf(String path) => _queuedProgramRecords()
      .where((PendingRecord r) => r.endpoint == path && r.method == SyncManager.methodPut)
      .lastOrNull;

  // --- Set Loglama ---
  Future<ApiResponse<WorkoutLog>> logSet(
    int workoutExerciseId,
    WorkoutLog log,
  ) {
    return _apiService.logSet(workoutExerciseId, log.toJson());
  }

  // --- Kişisel Program Güncelleme ---
  /// Bağlantı yoksa kuyruğa girer (KR13, G-74). Programın gönderilmemiş bir düzenlemesi varsa onun yükü değişir ve
  /// düzenlemeye başlanan sürüm korunur: iki düzenleme ayrı gitseydi ikincisi, ilkinin sunucuda artırdığı sürümle
  /// çakışıp reddedilirdi.
  Future<ApiResponse<TrainingBlock>> updatePersonalProgram(
    int id,
    TrainingBlock block,
  ) async {
    final String path = '${TrainingApiService.personalProgramsPath}/$id';
    final Map<String, dynamic> payload = block.toJson();

    final PendingRecord? queued = _queuedEditOf(path);
    if (queued != null) {
      final Map<String, dynamic> merged = <String, dynamic>{...payload, 'version': queued.payload['version']};
      if (await _syncManager.replacePayload(queued.key, merged)) {
        return _queuedResult(merged);
      }
      return ApiResponse<TrainingBlock>.error(_sentMeanwhileMessage);
    }

    if (await _networkInfo.isConnected) {
      return _apiService.updatePersonalProgram(id, payload);
    }
    await _syncManager.addToQueue(path, payload, method: SyncManager.methodPut);
    return _queuedResult(payload);
  }

  // --- İdman Oturumu Kaydetme ---
  Future<ApiResponse<void>> logWorkoutSession({
    required String dayName,
    required int totalSeconds,
    required List<CompletedSetData> sets,
    int? trainingBlockId,
    int? workoutDayId,
  }) async {
    // G-74: sunucuya gitmemiş programın gün/egzersizi cihazda geçici (negatif) kimlik taşır. Program ve gün kimliği
    // gönderilmez, sunucu egzersizden bulur; egzersiz geçici kimliğiyle gider (sunucu onu saklıyor).
    final bool usesQueuedProgram = sets.any((CompletedSetData s) => s.workoutExerciseId < 0);
    final payload = {
      // Tekrar koruması (G-79): aynı kimlikle ikinci gönderim sunucuda yeni kayıt açmaz.
      'localId': const Uuid().v4(),
      'workoutDayName': dayName,
      'totalSeconds': totalSeconds,
      'trainingBlockId': (trainingBlockId ?? 0) > 0 ? trainingBlockId : null,
      'workoutDayId': (workoutDayId ?? 0) > 0 ? workoutDayId : null,
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

    final bool isConnected = await _networkInfo.isConnected;
    if (isConnected && !usesQueuedProgram) {
      return _apiService.logWorkoutSession(payload);
    } else {
      // Çevrimdışı ya da program henüz kuyrukta: antrenman kuyruğa, programın oluşturulmasının ardına girer (K2-08);
      // bağlantı varsa kuyruk hemen gönderilir.
      await _syncManager.addToQueue(TrainingApiService.sessionsPath, payload);
      if (isConnected) unawaited(_syncManager.syncPendingData());
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

  /// Bağlantı yoksa silme kuyruğa girer (KR13, G-74); liste programı hemen gizler. Henüz sunucuya gitmemiş programın
  /// ([id] 0) silinmesi kuyruktaki oluşturma kaydını çıkarır. Programın gönderilmemiş düzenlemesi silmeyle anlamını
  /// yitirir ve kuyruktan çıkar; yoksa silinmiş programa gidip "aktarılamadı" görünürdü.
  Future<ApiResponse<void>> deletePersonalProgram(int id, {String? localId}) async {
    if (id == 0) {
      final PendingRecord? queued = localId == null ? null : _queuedCreateOf(localId);
      if (queued == null || !await _syncManager.removePending(queued.key)) {
        return ApiResponse<void>.error(_sentMeanwhileMessage);
      }
      await _dropQueuedActivations('${TrainingApiService.activatePath}/local/$localId');
      return ApiResponse<void>(success: true, message: '', timestamp: DateTime.now().toIso8601String());
    }

    final String path = '${TrainingApiService.personalProgramsPath}/$id';
    final ApiResponse<void> res;
    if (await _networkInfo.isConnected) {
      res = await _apiService.deletePersonalProgram(id);
    } else {
      await _syncManager.addToQueue(path, <String, dynamic>{}, method: SyncManager.methodDelete);
      res = ApiResponse<void>(success: true, message: _queuedMessage, timestamp: DateTime.now().toIso8601String());
    }
    final PendingRecord? edit = _queuedEditOf(path);
    if (res.success && edit != null) {
      await _syncManager.removePending(edit.key);
    }
    if (res.success) await _dropQueuedActivations('${TrainingApiService.activatePath}/$id');
    return res;
  }

  /// Silinen programın kuyruktaki etkinleştirmeleri anlamını yitirir; gönderilselerdi "aktarılamadı" görünürlerdi.
  Future<void> _dropQueuedActivations(String activationPath) async {
    for (final PendingRecord r in _queuedProgramRecords()) {
      if (r.endpoint == activationPath) await _syncManager.removePending(r.key);
    }
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

  /// Bağlantı yoksa etkinleştirme kuyruğa girer (KR13, G-74); liste programı hemen aktif gösterir. Sunucuya gitmemiş
  /// program ([id] 0) yerel kimliğiyle etkinleşir: kuyrukta oluşturmasının ardından gider, bağlantı varsa hemen.
  Future<ApiResponse<void>> activateProgram(int id, {String? localId}) async {
    if (id == 0 && localId == null) return ApiResponse<void>.error('Program bulunamadı.');
    final bool isConnected = await _networkInfo.isConnected;
    if (id != 0 && isConnected) return _apiService.activateProgram(id);

    final String path = id == 0
        ? '${TrainingApiService.activatePath}/local/$localId'
        : '${TrainingApiService.activatePath}/$id';
    await _syncManager.addToQueue(path, <String, dynamic>{});
    if (isConnected) unawaited(_syncManager.syncPendingData());
    return ApiResponse<void>(success: true, message: _queuedMessage, timestamp: DateTime.now().toIso8601String());
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
