import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class FetchProfile extends ProfileEvent {
  final bool isCoach;

  const FetchProfile({this.isCoach = false});

  @override
  List<Object?> get props => [isCoach];
}

class UpdateProfile extends ProfileEvent {
  final int userId;
  final Map<String, dynamic> updateData;
  final bool isCoach;

  const UpdateProfile({
    required this.userId,
    required this.updateData,
    this.isCoach = false,
  });

  @override
  List<Object?> get props => [userId, updateData, isCoach];
}

class ChangePassword extends ProfileEvent {
  final String currentPassword;
  final String newPassword;

  const ChangePassword({required this.currentPassword, required this.newPassword});

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

class UploadProfilePhoto extends ProfileEvent {
  final String filePath;
  final String fileName;

  const UploadProfilePhoto({required this.filePath, required this.fileName});

  @override
  List<Object?> get props => [filePath, fileName];
}

/// Kullanıcının kendi hesabını silmesi. Uçta kimlik parametresi yok: hedef her zaman
/// oturum açmış kullanıcı.
class DeleteAccount extends ProfileEvent {
  const DeleteAccount();
}
