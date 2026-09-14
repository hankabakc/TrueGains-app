import 'package:equatable/equatable.dart';
import '../../data/models/client_profile_response_model.dart';
import '../../data/models/coach_profile_response_model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ClientProfileResponseModel profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class CoachProfileLoaded extends ProfileState {
  final CoachProfileResponseModel profile;

  const CoachProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProfileUpdateSuccess extends ProfileState {}

class PasswordChangeSuccess extends ProfileState {}

class AccountDeleteSuccess extends ProfileState {}

class ProfilePhotoUploadLoading extends ProfileState {}

class ProfilePhotoUploadSuccess extends ProfileState {
  final String photoUrl;

  const ProfilePhotoUploadSuccess(this.photoUrl);

  @override
  List<Object?> get props => [photoUrl];
}

class ProfilePhotoUploadError extends ProfileState {
  final String message;

  const ProfilePhotoUploadError(this.message);

  @override
  List<Object?> get props => [message];
}
