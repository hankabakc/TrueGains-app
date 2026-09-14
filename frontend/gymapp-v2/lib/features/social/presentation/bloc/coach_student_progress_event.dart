import 'package:equatable/equatable.dart';

abstract class CoachStudentProgressEvent extends Equatable {
  const CoachStudentProgressEvent();

  @override
  List<Object?> get props => [];
}

class LoadPendingProgressRequests extends CoachStudentProgressEvent {}

class CreateProgressRequest extends CoachStudentProgressEvent {
  final int clientId;
  final String studentNickname;
  final String beforeFilePath;
  final String afterFilePath;
  final String? description;

  const CreateProgressRequest({
    required this.clientId,
    required this.studentNickname,
    required this.beforeFilePath,
    required this.afterFilePath,
    this.description,
  });

  @override
  List<Object?> get props => [clientId, studentNickname, beforeFilePath, afterFilePath, description];
}

class RespondToProgressRequest extends CoachStudentProgressEvent {
  final int requestId;
  final bool approved;

  const RespondToProgressRequest({required this.requestId, required this.approved});

  @override
  List<Object?> get props => [requestId, approved];
}

class LoadApprovedProgressForCoach extends CoachStudentProgressEvent {
  final int coachId;

  const LoadApprovedProgressForCoach(this.coachId);

  @override
  List<Object?> get props => [coachId];
}
