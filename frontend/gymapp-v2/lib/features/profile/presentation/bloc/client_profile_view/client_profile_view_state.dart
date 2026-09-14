import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/profile/data/models/client_profile_response_model.dart';

enum ClientProfileViewStatus { initial, loading, loaded, failure }

class ClientProfileViewState extends Equatable {
  final ClientProfileViewStatus status;
  final ClientProfileResponseModel? profile;
  final String? error;

  const ClientProfileViewState({
    this.status = ClientProfileViewStatus.initial,
    this.profile,
    this.error,
  });

  ClientProfileViewState copyWith({
    ClientProfileViewStatus? status,
    ClientProfileResponseModel? profile,
    String? error,
  }) {
    return ClientProfileViewState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, profile, error];
}
