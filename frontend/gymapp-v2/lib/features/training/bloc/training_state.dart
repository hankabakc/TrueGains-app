import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';

enum TrainingStatus { initial, loading, success, failure }

class TrainingState extends Equatable {
  final TrainingStatus status;
  final List<TrainingBlock> activePrograms;
  final List<TrainingBlock> coachTemplates;
  final List<TrainingBlock> assignedPrograms;
  final bool isProcessing;
  final String? errorMessage;
  final String? successMessage;

  const TrainingState({
    this.status = TrainingStatus.initial,
    this.activePrograms = const [],
    this.coachTemplates = const [],
    this.assignedPrograms = const [],
    this.isProcessing = false,
    this.errorMessage,
    this.successMessage,
  });

  TrainingState copyWith({
    TrainingStatus? status,
    List<TrainingBlock>? activePrograms,
    List<TrainingBlock>? coachTemplates,
    List<TrainingBlock>? assignedPrograms,
    bool? isProcessing,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
  }) {
    return TrainingState(
      status: status ?? this.status,
      activePrograms: activePrograms ?? this.activePrograms,
      coachTemplates: coachTemplates ?? this.coachTemplates,
      assignedPrograms: assignedPrograms ?? this.assignedPrograms,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearError ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, activePrograms, coachTemplates, assignedPrograms, isProcessing, errorMessage, successMessage];
}
