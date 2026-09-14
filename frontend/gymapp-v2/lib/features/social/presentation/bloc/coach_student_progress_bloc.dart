import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/coach_student_progress_repository.dart';
import '../../data/services/file_api_service.dart';
import 'coach_student_progress_event.dart';
import 'coach_student_progress_state.dart';

class CoachStudentProgressBloc extends Bloc<CoachStudentProgressEvent, CoachStudentProgressState> {
  final CoachStudentProgressRepository _repository;
  final FileApiService _fileApiService;

  CoachStudentProgressBloc(this._repository, this._fileApiService)
      : super(CoachStudentProgressInitial()) {
    on<LoadPendingProgressRequests>(_onLoadPendingRequests);
    on<CreateProgressRequest>(_onCreateProgressRequest);
    on<RespondToProgressRequest>(_onRespondToRequest);
    on<LoadApprovedProgressForCoach>(_onLoadApprovedProgress);
  }

  Future<void> _onLoadPendingRequests(
    LoadPendingProgressRequests event,
    Emitter<CoachStudentProgressState> emit,
  ) async {
    emit(CoachStudentProgressLoading());
    final result = await _repository.getPendingRequests();
    if (result.success && result.data != null) {
      emit(CoachPendingRequestsLoaded(result.data!));
    } else {
      emit(CoachStudentProgressError(result.message));
    }
  }

  Future<void> _onCreateProgressRequest(
    CreateProgressRequest event,
    Emitter<CoachStudentProgressState> emit,
  ) async {
    emit(CoachStudentProgressOperationLoading());

    // 1. Upload Before Image
    final beforeResult = await _fileApiService.uploadFile(event.beforeFilePath, 'before_${DateTime.now().millisecondsSinceEpoch}.jpg');
    if (!beforeResult.success || beforeResult.data == null) {
      emit(CoachStudentProgressError('Öncesi resmi yüklenemedi: ${beforeResult.message}'));
      return;
    }

    // 2. Upload After Image
    final afterResult = await _fileApiService.uploadFile(event.afterFilePath, 'after_${DateTime.now().millisecondsSinceEpoch}.jpg');
    if (!afterResult.success || afterResult.data == null) {
      emit(CoachStudentProgressError('Sonrası resmi yüklenemedi: ${afterResult.message}'));
      return;
    }

    // 3. Create Request
    final beforeUrl = beforeResult.data!['url'];
    final afterUrl = afterResult.data!['url'];

    if (beforeUrl == null || afterUrl == null) {
      emit(const CoachStudentProgressError('Dosya yükleme hatası: URL alınamadı.'));
      return;
    }

    final result = await _repository.createProgressRequest(
      clientId: event.clientId,
      studentNickname: event.studentNickname,
      beforeImageUrl: beforeUrl,
      afterImageUrl: afterUrl,
      description: event.description,
    );

    if (result.success) {
      emit(const CoachStudentProgressOperationSuccess('Gelişim talebi sporcuya gönderildi.'));
    } else {
      emit(CoachStudentProgressError(result.message));
    }
  }

  Future<void> _onRespondToRequest(
    RespondToProgressRequest event,
    Emitter<CoachStudentProgressState> emit,
  ) async {
    emit(CoachStudentProgressOperationLoading());
    final result = await _repository.respondToRequest(event.requestId, event.approved);
    if (result.success) {
      final message = event.approved ? 'Gelişim paylaşımı onaylandı.' : 'Gelişim paylaşımı reddedildi.';
      emit(CoachStudentProgressOperationSuccess(message));
      add(LoadPendingProgressRequests());
    } else {
      emit(CoachStudentProgressError(result.message));
    }
  }

  Future<void> _onLoadApprovedProgress(
    LoadApprovedProgressForCoach event,
    Emitter<CoachStudentProgressState> emit,
  ) async {
    emit(CoachStudentProgressLoading());
    final result = await _repository.getApprovedProgress(event.coachId);
    if (result.success && result.data != null) {
      emit(CoachApprovedProgressLoaded(result.data!));
    } else {
      emit(CoachStudentProgressError(result.message));
    }
  }
}
