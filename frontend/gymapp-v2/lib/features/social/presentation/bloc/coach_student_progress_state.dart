import 'package:equatable/equatable.dart';
import '../../data/models/coach_student_progress_model.dart';

abstract class CoachStudentProgressState extends Equatable {
  const CoachStudentProgressState();

  @override
  List<Object?> get props => [];
}

class CoachStudentProgressInitial extends CoachStudentProgressState {}

class CoachStudentProgressLoading extends CoachStudentProgressState {}

class CoachPendingRequestsLoaded extends CoachStudentProgressState {
  final List<CoachStudentProgressModel> requests;

  const CoachPendingRequestsLoaded(this.requests);

  @override
  List<Object?> get props => [requests];
}

class CoachApprovedProgressLoaded extends CoachStudentProgressState {
  final List<CoachStudentProgressModel> progressList;

  const CoachApprovedProgressLoaded(this.progressList);

  @override
  List<Object?> get props => [progressList];
}

class CoachStudentProgressError extends CoachStudentProgressState {
  final String message;

  const CoachStudentProgressError(this.message);

  @override
  List<Object?> get props => [message];
}

class CoachStudentProgressOperationLoading extends CoachStudentProgressState {}

class CoachStudentProgressOperationSuccess extends CoachStudentProgressState {
  final String message;

  const CoachStudentProgressOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
