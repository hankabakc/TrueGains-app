import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../social/data/services/file_api_service.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _repository;
  final FileApiService _fileApiService;

  ProfileBloc(this._repository, this._fileApiService) : super(ProfileInitial()) {
    on<FetchProfile>(_onFetchProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<ChangePassword>(_onChangePassword);
    on<DeleteAccount>(_onDeleteAccount);
    on<UploadProfilePhoto>(_onUploadProfilePhoto);
  }

  Future<void> _onFetchProfile(
    FetchProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    if (event.isCoach) {
      final response = await _repository.getMyCoachProfile();
      if (response.success && response.data != null) {
        emit(CoachProfileLoaded(response.data!));
      } else {
        emit(ProfileError(response.message));
      }
    } else {
      final response = await _repository.getMyProfile();
      if (response.success && response.data != null) {
        emit(ProfileLoaded(response.data!));
      } else {
        emit(ProfileError(response.message));
      }
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final response = await _repository.updateProfile(
      event.userId,
      event.updateData,
      isCoach: event.isCoach,
    );
    if (response.success) {
      emit(ProfileUpdateSuccess());
      add(FetchProfile(isCoach: event.isCoach)); // Refresh profile after update
    } else {
      emit(ProfileError(response.message));
    }
  }

  Future<void> _onChangePassword(
    ChangePassword event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final response = await _repository.changePassword(
      event.currentPassword,
      event.newPassword,
    );
    if (response.success) {
      emit(PasswordChangeSuccess());
    } else {
      emit(ProfileError(response.message));
    }
  }

  Future<void> _onDeleteAccount(
    DeleteAccount event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final response = await _repository.deleteMyAccount();
    if (response.success) {
      emit(AccountDeleteSuccess());
    } else {
      emit(ProfileError(response.message));
    }
  }

  Future<void> _onUploadProfilePhoto(
    UploadProfilePhoto event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfilePhotoUploadLoading());
    try {
      final response = await _fileApiService.uploadFile(event.filePath, event.fileName);
      if (response.success && response.data != null) {
        emit(ProfilePhotoUploadSuccess(response.data!['url']!));
      } else {
        emit(ProfilePhotoUploadError(response.message));
      }
    } catch (e) {
      emit(ProfilePhotoUploadError(friendlyError(e)));
    }
  }
}
