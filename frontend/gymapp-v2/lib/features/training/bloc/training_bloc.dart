import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/util/app_logger.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/features/training/repository/training_repository.dart';
import 'package:gymapp_v2/core/config/app_config.dart';
import 'training_event.dart';
import 'training_state.dart';

class TrainingBloc extends Bloc<TrainingEvent, TrainingState> {
  final TrainingRepository _repository;

  TrainingBloc(this._repository) : super(const TrainingState()) {
    on<LoadMyPrograms>(_onLoadMyPrograms);
    on<LogWorkoutSet>(_onLogWorkoutSet);
    on<DeleteProgram>(_onDeleteProgram);
    on<LoadCoachTemplates>(_onLoadCoachTemplates);
    on<CreateCoachTemplate>(_onCreateCoachTemplate);
    on<UpdateCoachTemplate>(_onUpdateCoachTemplate);
    on<DeleteCoachTemplate>(_onDeleteCoachTemplate);
    on<AssignTemplateToClient>(_onAssignTemplateToClient);
    on<LoadCoachAssignedPrograms>(_onLoadCoachAssignedPrograms);
    on<SubscribeToTrainingUpdates>(_onSubscribeToTrainingUpdates);
    on<UnsubscribeFromTrainingUpdates>(_onUnsubscribeFromTrainingUpdates);
    on<ActivateProgram>(_onActivateProgram);
    on<ApproveOrphanedProgram>(_onApproveOrphanedProgram);
    on<ClearTrainingMessages>((event, emit) {
      emit(state.copyWith(clearError: true));
    });
  }

  Future<void> _onDeleteCoachTemplate(
    DeleteCoachTemplate event,
    Emitter<TrainingState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true));
    try {
      final result = await _repository.deleteCoachTemplate(event.id);
      if (result.success) {
        add(const LoadCoachTemplates());
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      emit(
        state.copyWith(
          isProcessing: false,
          errorMessage: 'Şablon silinemedi: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onUpdateCoachTemplate(
    UpdateCoachTemplate event,
    Emitter<TrainingState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true));
    try {
      final result = await _repository.updateCoachTemplate(event.id, event.block);
      if (result.success) {
        add(const LoadCoachTemplates());
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      emit(
        state.copyWith(
          isProcessing: false,
          errorMessage: 'Şablon güncellenemedi: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onLoadCoachTemplates(
    LoadCoachTemplates event,
    Emitter<TrainingState> emit,
  ) async {
    emit(state.copyWith(status: TrainingStatus.loading));
    try {
      final result = await _repository.getCoachTemplates();
      if (result.success) {
        emit(
          state.copyWith(
            status: TrainingStatus.success,
            coachTemplates: result.data,
          ),
        );
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: TrainingStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadCoachAssignedPrograms(
    LoadCoachAssignedPrograms event,
    Emitter<TrainingState> emit,
  ) async {
    emit(state.copyWith(status: TrainingStatus.loading));
    try {
      final result = await _repository.getCoachAssignedPrograms();
      if (result.success) {
        emit(
          state.copyWith(
            status: TrainingStatus.success,
            assignedPrograms: result.data,
          ),
        );
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: TrainingStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onCreateCoachTemplate(
    CreateCoachTemplate event,
    Emitter<TrainingState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true));
    try {
      final result = await _repository.createCoachTemplate(event.block);
      if (result.success) {
        add(const LoadCoachTemplates());
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      emit(
        state.copyWith(
          isProcessing: false,
          errorMessage: 'Şablon oluşturulamadı: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onAssignTemplateToClient(
    AssignTemplateToClient event,
    Emitter<TrainingState> emit,
  ) async {
    // Adım 1.2: İşlem başlarken eski hataları temizle
    emit(state.copyWith(isProcessing: true, clearError: true));
    try {
      final result = await _repository.assignTemplateToClient(
        event.templateId,
        event.clientId,
      );
      if (result.success) {
        emit(state.copyWith(
          isProcessing: false,
          successMessage: '"${result.data?.name}" programı başarıyla atandı.',
        ));
        // Başarılı atama sonrası bir şey tetiklemeye gerek yok,
        // koç şablon listesinde kalır.
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      // "Exception: " önekini temizle
      final cleanMessage = e.toString().replaceAll('Exception: ', '');
      emit(
        state.copyWith(
          isProcessing: false,
          errorMessage: 'Program atanamadı: $cleanMessage',
        ),
      );
    }
  }

  Future<void> _onLoadMyPrograms(
    LoadMyPrograms event,
    Emitter<TrainingState> emit,
  ) async {
    sl<AppLogger>().info('🔄 [TrainingBloc] LoadMyPrograms eventi tetiklendi!');
    emit(state.copyWith(status: TrainingStatus.loading));
    try {
      final result = await _repository.getMyActivePrograms();
      if (result.success) {
        final programs = result.data ?? [];
        sl<AppLogger>().info('✅ [TrainingBloc] Backend\'den ${programs.length} program geldi.');
        
        for (int i = 0; i < programs.length; i++) {
          final p = programs[i];
          String tree = '[BLOC-FETCH] Program ${i + 1} (ID: ${p.id}). Günler: ';
          for (var day in p.workoutDays) {
            tree += '${day.name} (${day.exercises.length} Ex), ';
          }
          sl<AppLogger>().info(tree);
        }

        emit(
          state.copyWith(
            status: TrainingStatus.success,
            activePrograms: List.from(programs),
          ),
        );
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: TrainingStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLogWorkoutSet(
    LogWorkoutSet event,
    Emitter<TrainingState> emit,
  ) async {
    // Loglama işlemi genelde sessiz yapılır (UI'da anlık güncellenir).
    try {
      await _repository.logSet(event.workoutExerciseId, event.log);
      // Başarılı olduğunda istersen program listesini tazeleyebilirsin.
      // add(LoadMyPrograms());
    } catch (e) {
      emit(
        state.copyWith(
          status: TrainingStatus.failure,
          errorMessage: 'Set kaydedilemedi: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeleteProgram(
    DeleteProgram event,
    Emitter<TrainingState> emit,
  ) async {
    try {
      final result = await _repository.deletePersonalProgram(event.id);
      if (result.success) {
        add(const LoadMyPrograms());
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: TrainingStatus.failure,
          errorMessage: 'Program silinemedi: ${e.toString()}',
        ),
      );
    }
  }

  void _onSubscribeToTrainingUpdates(
    SubscribeToTrainingUpdates event,
    Emitter<TrainingState> emit,
  ) {
    _repository.subscribeToTrainingUpdates(
      clientId: event.clientId,
      wsUrl: AppConfig.wsUrl,
      onUpdateReceived: () {
        add(const LoadMyPrograms());
      },
    );
  }

  void _onUnsubscribeFromTrainingUpdates(
    UnsubscribeFromTrainingUpdates event,
    Emitter<TrainingState> emit,
  ) {
    _repository.unsubscribeFromTrainingUpdates();
  }

  Future<void> _onActivateProgram(
    ActivateProgram event,
    Emitter<TrainingState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true, clearError: true));
    try {
      final result = await _repository.activateProgram(event.id);
      if (result.success) {
        emit(state.copyWith(
          isProcessing: false,
          successMessage: 'Program başarıyla aktif edildi.',
        ));
        add(const LoadMyPrograms());
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      emit(
        state.copyWith(
          isProcessing: false,
          errorMessage: 'Program aktif edilemedi: ${e.toString().replaceAll('Exception: ', '')}',
        ),
      );
    }
  }

  Future<void> _onApproveOrphanedProgram(
    ApproveOrphanedProgram event,
    Emitter<TrainingState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true, clearError: true));
    try {
      final result = await _repository.approveOrphanedProgram(event.id, event.keep);
      if (result.success) {
        emit(state.copyWith(
          isProcessing: false,
          successMessage: event.keep
              ? 'Program başarıyla kişisel programlarınıza taşındı.'
              : 'Program silindi.',
        ));
        add(const LoadMyPrograms());
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      emit(
        state.copyWith(
          isProcessing: false,
          errorMessage: 'İşlem gerçekleştirilemedi: ${e.toString().replaceAll('Exception: ', '')}',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _repository.unsubscribeFromTrainingUpdates();
    return super.close();
  }
}
