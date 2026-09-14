import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/social/data/models/coach_discovery_model.dart';
import 'package:gymapp_v2/features/social/data/models/pairing_request_model.dart';
import 'package:gymapp_v2/features/social/data/models/discovery_user_model.dart';
import 'package:gymapp_v2/features/social/data/repositories/social_repository.dart';

// --- States ---
abstract class SocialState extends Equatable {
  const SocialState();
  @override
  List<Object?> get props => [];
}

class SocialInitial extends SocialState {}

class SocialLoading extends SocialState {}

class SocialCoachesLoaded extends SocialState {
  final List<CoachDiscoveryModel> coaches;
  const SocialCoachesLoaded(this.coaches);
  @override
  List<Object?> get props => [coaches];
}

class SocialPendingRequestsLoaded extends SocialState {
  final List<PairingRequestModel> requests;
  const SocialPendingRequestsLoaded(this.requests);
  @override
  List<Object?> get props => [requests];
}

class SocialProcessingRequest extends SocialState {
  final List<PairingRequestModel> requests;
  const SocialProcessingRequest(this.requests);
  @override
  List<Object?> get props => [requests];
}

class SocialRequestSent extends SocialState {}

class SocialResponseSuccess extends SocialState {
  final String message;
  const SocialResponseSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class SocialError extends SocialState {
  final String message;
  const SocialError(this.message);
  @override
  List<Object?> get props => [message];
}

class SocialClientsLoaded extends SocialState {
  final List<DiscoveryUserModel> clients;
  const SocialClientsLoaded(this.clients);
  @override
  List<Object?> get props => [clients];
}

// --- Events ---
abstract class SocialEvent extends Equatable {
  const SocialEvent();
  @override
  List<Object?> get props => [];
}

class DiscoverCoachesRequested extends SocialEvent {
  final String? specialization;
  final int page;
  final bool isRefresh;

  const DiscoverCoachesRequested({
    this.specialization,
    this.page = 0,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [specialization, page, isRefresh];
}

class PairingRequestSubmitted extends SocialEvent {
  final int coachId;
  final String message;
  const PairingRequestSubmitted({required this.coachId, required this.message});
  @override
  List<Object?> get props => [coachId, message];
}

class PendingRequestsRequested extends SocialEvent {
  final bool isSilent;
  const PendingRequestsRequested({this.isSilent = false});
  @override
  List<Object?> get props => [isSilent];
}

class RequestResponseSubmitted extends SocialEvent {
  final int requestId;
  final bool accepted;
  const RequestResponseSubmitted({
    required this.requestId,
    required this.accepted,
  });
  @override
  List<Object?> get props => [requestId, accepted];
}

class LoadMyClientsRequested extends SocialEvent {}

// --- Bloc ---
class SocialBloc extends Bloc<SocialEvent, SocialState> {
  final SocialRepository _repository;
  List<CoachDiscoveryModel> _currentCoaches = [];
  List<PairingRequestModel> _currentRequests = [];

  SocialBloc(this._repository) : super(SocialInitial()) {
    on<DiscoverCoachesRequested>((event, emit) async {
      try {
        if (event.page == 0) {
          if (!event.isRefresh) emit(SocialLoading());
          _currentCoaches = [];
        }

        final result = await _repository.discoverCoaches(
          specialization: event.specialization,
          page: event.page,
        );

        if (result.success && result.data != null) {
          final content = result.data!.content;
          if (event.page == 0) {
            _currentCoaches = content;
          } else {
            _currentCoaches.addAll(content);
          }
          emit(SocialCoachesLoaded(List.from(_currentCoaches)));
        } else {
          emit(SocialError(result.message));
        }
      } catch (e) {
        emit(SocialError('Antrenörler yüklenirken bir hata oluştu: $e'));
      }
    });

    on<PairingRequestSubmitted>((event, emit) async {
      try {
        emit(SocialLoading());
        final result = await _repository.sendPairingRequest(
          event.coachId,
          event.message,
        );
        if (result.success) {
          emit(SocialRequestSent());
        } else {
          emit(SocialError(result.message));
        }
      } catch (e) {
        emit(SocialError('İstek gönderilirken bir hata oluştu: $e'));
      }
    });

    on<PendingRequestsRequested>((event, emit) async {
      try {
        if (!event.isSilent) emit(SocialLoading());
        final result = await _repository.getPendingRequests();
        if (result.success && result.data != null) {
          _currentRequests = result.data!;
          emit(SocialPendingRequestsLoaded(List.from(_currentRequests)));
        } else {
          emit(SocialError(result.message));
        }
      } catch (e) {
        emit(SocialError('İstekler yüklenirken bir hata oluştu: $e'));
      }
    });

    on<RequestResponseSubmitted>((event, emit) async {
      try {
        // Liste kaybolmasın diye şeffaf loading durumuna geçiyoruz
        emit(SocialProcessingRequest(List.from(_currentRequests)));

        final result = await _repository.respondToRequest(
          event.requestId,
          event.accepted,
        );
        if (result.success) {
          emit(SocialResponseSuccess(result.message));
          // Sessizce listeyi güncelle
          add(const PendingRequestsRequested(isSilent: true));
        } else {
          emit(SocialError(result.message));
          // Hata olsa bile listeyi geri göster
          emit(SocialPendingRequestsLoaded(List.from(_currentRequests)));
        }
      } catch (e) {
        emit(SocialError('İşlem sırasında bir hata oluştu: $e'));
        emit(SocialPendingRequestsLoaded(List.from(_currentRequests)));
      }
    });

    on<LoadMyClientsRequested>((event, emit) async {
      try {
        emit(SocialLoading());
        final result = await _repository.getMyClients();
        if (result.success && result.data != null) {
          emit(SocialClientsLoaded(result.data!));
        } else {
          emit(SocialError(result.message));
        }
      } catch (e) {
        emit(SocialError('Öğrenciler yüklenirken bir hata oluştu: $e'));
      }
    });
  }
}
