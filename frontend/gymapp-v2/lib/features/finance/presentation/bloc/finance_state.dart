part of 'finance_bloc.dart';

/// Finans BLoC State tanımları
enum FinanceStatus { initial, loading, loaded, paymentSuccess, error, cartUpdated, packageActionSuccess, checkoutInitiated, webhookTriggered }

class FinanceState {
  final FinanceStatus status;
  final List<SubscriptionPackageModel> packages;
  final List<PaymentTransactionModel> transactions;
  final ClientSubscriptionModel? subscription;
  final String? error;
  final String? successMessage;
  final String? checkoutSessionId;
  final String? paymentUrl;

  const FinanceState({
    this.status = FinanceStatus.initial,
    this.packages = const [],
    this.transactions = const [],
    this.subscription,
    this.error,
    this.successMessage,
    this.checkoutSessionId,
    this.paymentUrl,
  });

  FinanceState copyWith({
    FinanceStatus? status,
    List<SubscriptionPackageModel>? packages,
    List<PaymentTransactionModel>? transactions,
    ClientSubscriptionModel? subscription,
    String? error,
    String? successMessage,
    String? checkoutSessionId,
    String? paymentUrl,
  }) {
    return FinanceState(
      status: status ?? this.status,
      packages: packages ?? this.packages,
      transactions: transactions ?? this.transactions,
      subscription: subscription ?? this.subscription,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
      checkoutSessionId: checkoutSessionId ?? this.checkoutSessionId,
      paymentUrl: paymentUrl ?? this.paymentUrl,
    );
  }
}
