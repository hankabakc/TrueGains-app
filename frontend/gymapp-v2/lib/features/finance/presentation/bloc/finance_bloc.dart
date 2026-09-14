import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/finance/models/finance_models.dart';
import 'package:gymapp_v2/features/finance/repository/finance_repository.dart';

part 'finance_event.dart';
part 'finance_state.dart';

/// Finans ve Ödeme Modülü BLoC.
/// Paket listeleme, sepet, mock ödeme ve abonelik sorgulama akışlarını yönetir.
class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final FinanceRepository _repository;

  FinanceBloc({required FinanceRepository repository})
    : _repository = repository,
      super(const FinanceState()) {
    on<LoadPackages>(_onLoadPackages);
    on<LoadCoachMyPackages>(_onLoadCoachMyPackages);
    on<CreateCoachPackage>(_onCreateCoachPackage);
    on<UpdateCoachPackage>(_onUpdateCoachPackage);
    on<DeleteCoachPackage>(_onDeleteCoachPackage);
    on<AddPackageToCart>(_onAddPackageToCart);
    on<RemovePackageFromCart>(_onRemovePackageFromCart);
    on<LoadMyTransactions>(_onLoadMyTransactions);
    on<PayCartTransaction>(_onPayCartTransaction);
    on<LoadMySubscription>(_onLoadMySubscription);
    on<LoadClientSubscription>(_onLoadClientSubscription);
    on<InitiateCheckoutEvent>(_onInitiateCheckout);
    on<TriggerPaymentWebhookEvent>(_onTriggerPaymentWebhook);
  }

  Future<void> _onLoadPackages(
    LoadPackages event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading));
    try {
      final result = await _repository.getAvailablePackages(event.coachId);
      if (result.success) {
        emit(state.copyWith(
          status: FinanceStatus.loaded,
          packages: result.data ?? [],
        ));
      } else {
        emit(state.copyWith(
          status: FinanceStatus.error,
          error: result.message,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FinanceStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadCoachMyPackages(
    LoadCoachMyPackages event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading));
    try {
      final result = await _repository.getCoachPackages();
      if (result.success) {
        emit(state.copyWith(
          status: FinanceStatus.loaded,
          packages: result.data ?? [],
        ));
      } else {
        emit(state.copyWith(
          status: FinanceStatus.error,
          error: result.message,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FinanceStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCreateCoachPackage(
    CreateCoachPackage event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading));
    try {
      final result = await _repository.createPackage({
        'name': event.name,
        'price': event.price,
        'durationDays': event.durationDays,
        'description': event.description,
        'features': event.features,
        'quota': event.quota,
        'levels': event.levels,
        'mode': event.mode,
      });
      if (result.success) {
        emit(state.copyWith(
          status: FinanceStatus.packageActionSuccess,
          successMessage: result.message,
        ));
        add(LoadCoachMyPackages());
      } else {
        emit(state.copyWith(
          status: FinanceStatus.error,
          error: result.message,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FinanceStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateCoachPackage(
    UpdateCoachPackage event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading));
    try {
      final result = await _repository.updatePackage(event.id, {
        'name': event.name,
        'price': event.price,
        'durationDays': event.durationDays,
        'description': event.description,
        'features': event.features,
        'quota': event.quota,
        'levels': event.levels,
        'mode': event.mode,
      });
      if (result.success) {
        emit(state.copyWith(
          status: FinanceStatus.packageActionSuccess,
          successMessage: result.message,
        ));
        add(LoadCoachMyPackages());
      } else {
        emit(state.copyWith(
          status: FinanceStatus.error,
          error: result.message,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FinanceStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteCoachPackage(
    DeleteCoachPackage event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading));
    try {
      final result = await _repository.deletePackage(event.id);
      if (result.success) {
        emit(state.copyWith(
          status: FinanceStatus.packageActionSuccess,
          successMessage: result.message,
        ));
        add(LoadCoachMyPackages());
      } else {
        emit(state.copyWith(
          status: FinanceStatus.error,
          error: result.message,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FinanceStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onAddPackageToCart(
    AddPackageToCart event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading));
    try {
      final result = await _repository.addToCart(event.packageId);
      if (result.success) {
        emit(state.copyWith(
          status: FinanceStatus.cartUpdated,
          successMessage: result.message,
        ));
        add(LoadMyTransactions());
      } else {
        emit(state.copyWith(
          status: FinanceStatus.error,
          error: result.message,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FinanceStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRemovePackageFromCart(
    RemovePackageFromCart event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading));
    try {
      final result = await _repository.removeFromCart(event.transactionId);
      if (result.success) {
        emit(state.copyWith(
          status: FinanceStatus.cartUpdated,
          successMessage: result.message,
        ));
        add(LoadMyTransactions());
      } else {
        emit(state.copyWith(
          status: FinanceStatus.error,
          error: result.message,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FinanceStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMyTransactions(
    LoadMyTransactions event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading));
    try {
      final result = await _repository.getMyTransactions();
      if (result.success) {
        emit(state.copyWith(
          status: FinanceStatus.loaded,
          transactions: result.data ?? [],
        ));
      } else {
        emit(state.copyWith(
          status: FinanceStatus.error,
          error: result.message,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FinanceStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onPayCartTransaction(
    PayCartTransaction event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading));
    try {
      final result = await _repository.processPaymentForTransaction(
        transactionId: event.transactionId,
        cardNumber: event.cardNumber,
        cardHolderName: event.cardHolderName,
        expiryDate: event.expiryDate,
        cvv: event.cvv,
      );
      if (result.success) {
        emit(state.copyWith(
          status: FinanceStatus.paymentSuccess,
          subscription: result.data,
          successMessage: result.message,
        ));
        add(LoadMyTransactions());
      } else {
        emit(state.copyWith(
          status: FinanceStatus.error,
          error: result.message,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FinanceStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMySubscription(
    LoadMySubscription event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading));
    try {
      final result = await _repository.getMySubscription();
      emit(state.copyWith(
        status: FinanceStatus.loaded,
        subscription: result.data,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FinanceStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadClientSubscription(
    LoadClientSubscription event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading));
    try {
      final result = await _repository.getClientSubscription(event.clientId);
      emit(state.copyWith(
        status: FinanceStatus.loaded,
        subscription: result.data,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FinanceStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onInitiateCheckout(
    InitiateCheckoutEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading));
    try {
      final result = await _repository.initiateCheckout(event.transactionId);
      if (result.success && result.data != null) {
        emit(state.copyWith(
          status: FinanceStatus.checkoutInitiated,
          checkoutSessionId: result.data!['checkoutSessionId'] as String?,
          paymentUrl: result.data!['paymentUrl'] as String?,
        ));
      } else {
        emit(state.copyWith(
          status: FinanceStatus.error,
          error: result.message,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FinanceStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onTriggerPaymentWebhook(
    TriggerPaymentWebhookEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading));
    try {
      final result = await _repository.triggerPaymentWebhook(
        sessionId: event.sessionId,
        status: event.status,
      );
      if (result.success) {
        if (event.status.toUpperCase() == 'SUCCESS') {
          emit(state.copyWith(
            status: FinanceStatus.webhookTriggered,
            successMessage: result.message,
          ));
        } else {
          emit(state.copyWith(
            status: FinanceStatus.error,
            error: 'Ödeme iptal edildi veya reddedildi.',
          ));
        }
      } else {
        emit(state.copyWith(
          status: FinanceStatus.error,
          error: result.message,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FinanceStatus.error,
        error: e.toString(),
      ));
    }
  }
}
