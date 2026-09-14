import 'package:equatable/equatable.dart';

abstract class CoachProfileEvent extends Equatable {
  const CoachProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadCoachProfile extends CoachProfileEvent {
  final int coachId;

  const LoadCoachProfile(this.coachId);

  @override
  List<Object?> get props => [coachId];
}

class LoadCoachReviews extends CoachProfileEvent {
  final int coachId;
  final int page;

  const LoadCoachReviews(this.coachId, {this.page = 0});

  @override
  List<Object?> get props => [coachId, page];
}

class SubmitCoachReview extends CoachProfileEvent {
  final int coachId;
  final int rating;
  final String? comment;

  const SubmitCoachReview({
    required this.coachId,
    required this.rating,
    this.comment,
  });

  @override
  List<Object?> get props => [coachId, rating, comment];
}

class SendCoachRequestEvent extends CoachProfileEvent {
  final int coachId;

  const SendCoachRequestEvent(this.coachId);

  @override
  List<Object?> get props => [coachId];
}

class AddGalleryItemEvent extends CoachProfileEvent {
  final int coachId;
  final String filePath;
  final String fileName;
  final bool isStudentProgress;

  const AddGalleryItemEvent({
    required this.coachId,
    required this.filePath,
    required this.fileName,
    required this.isStudentProgress,
  });

  @override
  List<Object?> get props => [coachId, filePath, fileName, isStudentProgress];
}

class DeleteGalleryItemEvent extends CoachProfileEvent {
  final int coachId;
  final int itemId;

  const DeleteGalleryItemEvent({
    required this.coachId,
    required this.itemId,
  });

  @override
  List<Object?> get props => [coachId, itemId];
}
