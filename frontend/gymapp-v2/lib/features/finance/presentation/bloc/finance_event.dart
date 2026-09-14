part of 'finance_bloc.dart';

/// Finans BLoC Event'leri
abstract class FinanceEvent {}

/// Sporcunun görüntülediği koçun paketlerini yükler
class LoadPackages extends FinanceEvent {
  final int coachId;
  LoadPackages(this.coachId);
}

/// Koçun kendi paketlerini yükler
class LoadCoachMyPackages extends FinanceEvent {}

/// Koç için yeni üyelik paketi oluşturur
class CreateCoachPackage extends FinanceEvent {
  final String name;
  final double price;
  final int durationDays;
  final String description;
  final String features;
  final int? quota;
  final String levels;
  final String mode;

  CreateCoachPackage({
    required this.name,
    required this.price,
    required this.durationDays,
    required this.description,
    required this.features,
    required this.levels,
    required this.mode,
    this.quota,
  });
}

/// Koç için mevcut paketi günceller
class UpdateCoachPackage extends FinanceEvent {
  final int id;
  final String name;
  final double price;
  final int durationDays;
  final String description;
  final String features;
  final int? quota;
  final String levels;
  final String mode;

  UpdateCoachPackage({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.description,
    required this.features,
    required this.levels,
    required this.mode,
    this.quota,
  });
}

/// Koç için paketi siler
class DeleteCoachPackage extends FinanceEvent {
  final int id;
  DeleteCoachPackage(this.id);
}

/// Sporcu için paketi sepete (ödeme bekleyenlere) ekler
class AddPackageToCart extends FinanceEvent {
  final int packageId;
  AddPackageToCart(this.packageId);
}

/// Sporcu için bekleyen işlemi sepetten kaldırır
class RemovePackageFromCart extends FinanceEvent {
  final int transactionId;
  RemovePackageFromCart(this.transactionId);
}

/// Sporcunun kendi işlem geçmişini ve sepetini yükler
class LoadMyTransactions extends FinanceEvent {}

/// Sepetteki bekleyen işlem için ödeme başlatır
class PayCartTransaction extends FinanceEvent {
  final int transactionId;
  final String cardNumber;
  final String cardHolderName;
  final String expiryDate;
  final String cvv;

  PayCartTransaction({
    required this.transactionId,
    required this.cardNumber,
    required this.cardHolderName,
    required this.expiryDate,
    required this.cvv,
  });
}

/// Sporcunun kendi aboneliğini yükler
class LoadMySubscription extends FinanceEvent {}

/// Koç için sporcunun aboneliğini yükler
class LoadClientSubscription extends FinanceEvent {
  final int clientId;
  LoadClientSubscription(this.clientId);
}

/// Checkout oturumu başlatma olayı
class InitiateCheckoutEvent extends FinanceEvent {
  final int transactionId;
  InitiateCheckoutEvent(this.transactionId);
}

/// Webhook simülasyonu tetikleme olayı
class TriggerPaymentWebhookEvent extends FinanceEvent {
  final String sessionId;
  final String status;

  TriggerPaymentWebhookEvent({
    required this.sessionId,
    required this.status,
  });
}
