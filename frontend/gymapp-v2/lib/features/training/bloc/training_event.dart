import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';

abstract class TrainingEvent extends Equatable {
  const TrainingEvent();
  @override
  List<Object?> get props => [];
}

class LoadMyPrograms extends TrainingEvent {
  const LoadMyPrograms();
}

class SubscribeToTrainingUpdates extends TrainingEvent {
  final int clientId;
  const SubscribeToTrainingUpdates(this.clientId);

  @override
  List<Object?> get props => [clientId];
}

class UnsubscribeFromTrainingUpdates extends TrainingEvent {
  const UnsubscribeFromTrainingUpdates();
}

class LogWorkoutSet extends TrainingEvent {
  final int workoutExerciseId;
  final WorkoutLog log;

  const LogWorkoutSet(this.workoutExerciseId, this.log);

  @override
  List<Object?> get props => [workoutExerciseId, log];
}

class DeleteProgram extends TrainingEvent {
  final int id;
  const DeleteProgram(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadCoachTemplates extends TrainingEvent {
  const LoadCoachTemplates();
}

class CreateCoachTemplate extends TrainingEvent {
  final TrainingBlock block;
  const CreateCoachTemplate(this.block);

  @override
  List<Object?> get props => [block];
}

class AssignTemplateToClient extends TrainingEvent {
  final int templateId;
  final int clientId;
  const AssignTemplateToClient({required this.templateId, required this.clientId});

  @override
  List<Object?> get props => [templateId, clientId];
}

class UpdateCoachTemplate extends TrainingEvent {
  final int id;
  final TrainingBlock block;
  const UpdateCoachTemplate(this.id, this.block);

  @override
  List<Object?> get props => [id, block];
}

class DeleteCoachTemplate extends TrainingEvent {
  final int id;
  const DeleteCoachTemplate(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadCoachAssignedPrograms extends TrainingEvent {
  const LoadCoachAssignedPrograms();
}

class ActivateProgram extends TrainingEvent {
  final int id;
  const ActivateProgram(this.id);

  @override
  List<Object?> get props => [id];
}

class ClearTrainingMessages extends TrainingEvent {
  const ClearTrainingMessages();
}

class ApproveOrphanedProgram extends TrainingEvent {
  final int id;
  final bool keep;
  const ApproveOrphanedProgram({required this.id, required this.keep});

  @override
  List<Object?> get props => [id, keep];
}
