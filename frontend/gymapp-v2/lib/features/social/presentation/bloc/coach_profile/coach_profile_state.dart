import 'package:equatable/equatable.dart';
import '../../../../social/data/models/coach_profile_model.dart';
import '../../../../social/data/models/coach_review_model.dart';

abstract class CoachProfileState extends Equatable {
  const CoachProfileState();

  @override
  List<Object?> get props => [];
}

class CoachProfileInitial extends CoachProfileState {}

class CoachProfileLoading extends CoachProfileState {}

class CoachProfileLoaded extends CoachProfileState {
  final CoachProfileModel profile;
  final List<CoachReviewModel>? reviews;
  final bool hasReachedMaxReviews;

  const CoachProfileLoaded(this.profile, {this.reviews, this.hasReachedMaxReviews = false});

  @override
  List<Object?> get props => [profile, reviews, hasReachedMaxReviews];
}

class CoachProfileError extends CoachProfileState {
  final String message;

  const CoachProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

class CoachReviewsLoading extends CoachProfileState {}

class CoachReviewsLoaded extends CoachProfileState {
  final List<CoachReviewModel> reviews;
  final bool hasReachedMax;

  const CoachReviewsLoaded(this.reviews, {this.hasReachedMax = false});

  @override
  List<Object?> get props => [reviews, hasReachedMax];
}

class CoachReviewSubmissionLoading extends CoachProfileState {}

class CoachReviewSubmissionSuccess extends CoachProfileState {
  final CoachReviewModel newReview;

  const CoachReviewSubmissionSuccess(this.newReview);

  @override
  List<Object?> get props => [newReview];
}

class CoachReviewSubmissionError extends CoachProfileState {
  final String message;

  const CoachReviewSubmissionError(this.message);

  @override
  List<Object?> get props => [message];
}

class CoachRequestLoading extends CoachProfileState {}

class CoachRequestSuccess extends CoachProfileState {
  final String message;

  const CoachRequestSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CoachRequestError extends CoachProfileState {
  final String message;

  const CoachRequestError(this.message);

  @override
  List<Object?> get props => [message];
}

class CoachGalleryOperationLoading extends CoachProfileState {}

class CoachGalleryOperationSuccess extends CoachProfileState {
  final String message;

  const CoachGalleryOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CoachGalleryOperationError extends CoachProfileState {
  final String message;

  const CoachGalleryOperationError(this.message);

  @override
  List<Object?> get props => [message];
}
