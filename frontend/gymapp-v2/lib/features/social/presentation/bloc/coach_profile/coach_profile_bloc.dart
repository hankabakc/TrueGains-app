import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import 'package:gymapp_v2/features/social/data/models/coach_review_model.dart';
import '../../../../social/data/services/coach_profile_api_service.dart';
import '../../../../social/data/services/file_api_service.dart';
import 'coach_profile_event.dart';
import 'coach_profile_state.dart';

class CoachProfileBloc extends Bloc<CoachProfileEvent, CoachProfileState> {
  final CoachProfileApiService _apiService;

  CoachProfileBloc(this._apiService) : super(CoachProfileInitial()) {
    on<LoadCoachProfile>(_onLoadCoachProfile);
    on<LoadCoachReviews>(_onLoadCoachReviews);
    on<SubmitCoachReview>(_onSubmitCoachReview);
    on<SendCoachRequestEvent>(_onSendCoachRequest);
    on<AddGalleryItemEvent>(_onAddGalleryItem);
    on<DeleteGalleryItemEvent>(_onDeleteGalleryItem);
  }

  Future<void> _onSendCoachRequest(
    SendCoachRequestEvent event,
    Emitter<CoachProfileState> emit,
  ) async {
    emit(CoachRequestLoading());
    final result = await _apiService.sendCoachRequest(event.coachId);

    if (result.success) {
      emit(CoachRequestSuccess(result.message));
    } else {
      emit(
        CoachRequestError(
          result.message.isNotEmpty ? result.message : 'İstek gönderilemedi.',
        ),
      );
    }
  }

  Future<void> _onLoadCoachProfile(
    LoadCoachProfile event,
    Emitter<CoachProfileState> emit,
  ) async {
    try {
      emit(CoachProfileLoading());
      final result = await _apiService.getCoachProfile(event.coachId);

      if (result.success && result.data != null) {
        List<CoachReviewModel>? existingReviews;
        bool hasReachedMax = false;
        final currentState = state;
        if (currentState is CoachProfileLoaded) {
          existingReviews = currentState.reviews;
          hasReachedMax = currentState.hasReachedMaxReviews;
        } else if (currentState is CoachReviewsLoaded) {
          existingReviews = currentState.reviews;
          hasReachedMax = currentState.hasReachedMax;
        }
        emit(CoachProfileLoaded(
          result.data!,
          reviews: existingReviews,
          hasReachedMaxReviews: hasReachedMax,
        ));
      } else {
        emit(
          CoachProfileError(
            result.message.isNotEmpty ? result.message : 'Profil yüklenemedi.',
          ),
        );
      }
    } catch (e) {
      emit(CoachProfileError(friendlyError(e)));
    }
  }

  Future<void> _onLoadCoachReviews(
    LoadCoachReviews event,
    Emitter<CoachProfileState> emit,
  ) async {
    final currentProfile = state is CoachProfileLoaded ? (state as CoachProfileLoaded).profile : null;
    
    if (currentProfile == null) {
      emit(CoachReviewsLoading());
    }

    final result = await _apiService.getCoachReviews(
      event.coachId,
      page: event.page,
    );

    if (result.success && result.data != null) {
      final reviews = result.data!;
      final currentState = state;
      if (currentState is CoachProfileLoaded) {
        emit(
          CoachProfileLoaded(
            currentState.profile,
            reviews: reviews,
            hasReachedMaxReviews: reviews.isEmpty || reviews.length < 20,
          ),
        );
      } else {
        emit(
          CoachReviewsLoaded(
            reviews,
            hasReachedMax: reviews.isEmpty || reviews.length < 20,
          ),
        );
      }
    } else {
      emit(
        CoachProfileError(
          result.message.isNotEmpty ? result.message : 'Yorumlar yüklenemedi.',
        ),
      );
    }
  }

  Future<void> _onSubmitCoachReview(
    SubmitCoachReview event,
    Emitter<CoachProfileState> emit,
  ) async {
    emit(CoachReviewSubmissionLoading());
    final result = await _apiService.addReview(
      event.coachId,
      event.rating,
      event.comment,
    );

    if (result.success && result.data != null) {
      emit(CoachReviewSubmissionSuccess(result.data!));
    } else {
      emit(
        CoachReviewSubmissionError(
          result.message.isNotEmpty ? result.message : 'Yorum gönderilemedi.',
        ),
      );
    }
  }

  Future<void> _onAddGalleryItem(
    AddGalleryItemEvent event,
    Emitter<CoachProfileState> emit,
  ) async {
    emit(CoachGalleryOperationLoading());
    try {
      final uploadResult = await sl<FileApiService>().uploadFile(event.filePath, event.fileName);
      if (!uploadResult.success || uploadResult.data == null) {
        emit(CoachGalleryOperationError(uploadResult.message));
        return;
      }

      final imageUrl = uploadResult.data!['url']!;
      final result = await _apiService.addGalleryItem(imageUrl, event.isStudentProgress);

      if (result.success) {
        emit(const CoachGalleryOperationSuccess('Görsel başarıyla eklendi.'));
        add(LoadCoachProfile(event.coachId));
      } else {
        emit(CoachGalleryOperationError(result.message));
      }
    } catch (e) {
      emit(CoachGalleryOperationError(friendlyError(e)));
    }
  }

  Future<void> _onDeleteGalleryItem(
    DeleteGalleryItemEvent event,
    Emitter<CoachProfileState> emit,
  ) async {
    emit(CoachGalleryOperationLoading());
    try {
      final result = await _apiService.deleteGalleryItem(event.itemId);
      if (result.success) {
        emit(const CoachGalleryOperationSuccess('Görsel başarıyla silindi.'));
        add(LoadCoachProfile(event.coachId));
      } else {
        emit(CoachGalleryOperationError(result.message));
      }
    } catch (e) {
      emit(CoachGalleryOperationError(friendlyError(e)));
    }
  }
}
