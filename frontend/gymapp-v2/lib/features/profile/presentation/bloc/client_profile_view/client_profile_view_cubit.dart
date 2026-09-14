import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/profile/data/repositories/profile_repository.dart';
import 'client_profile_view_state.dart';

class ClientProfileViewCubit extends Cubit<ClientProfileViewState> {
  final ProfileRepository _repository;

  ClientProfileViewCubit(this._repository) : super(const ClientProfileViewState());

  Future<void> load(int clientId) async {
    emit(state.copyWith(status: ClientProfileViewStatus.loading));
    try {
      final result = await _repository.getClientProfile(clientId);
      if (result.success && result.data != null) {
        emit(state.copyWith(
          status: ClientProfileViewStatus.loaded,
          profile: result.data,
        ));
      } else {
        emit(state.copyWith(
          status: ClientProfileViewStatus.failure,
          error: result.message,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ClientProfileViewStatus.failure,
        error: e.toString(),
      ));
    }
  }
}
