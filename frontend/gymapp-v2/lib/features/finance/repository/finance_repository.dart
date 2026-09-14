import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/features/dashboard/data/models/coach_dashboard_stats.dart';
import 'package:gymapp_v2/features/finance/data/services/finance_api_service.dart';
import 'package:gymapp_v2/features/finance/models/finance_models.dart';

/// Finans modülü Repository katmanı. BLoC ile API servisi arasında köprü görevi görür.
class FinanceRepository {
  final FinanceApiService _apiService;

  FinanceRepository(this._apiService);

  Future<ApiResponse<List<SubscriptionPackageModel>>> getAvailablePackages(int coachId) {
    return _apiService.getAvailablePackages(coachId);
  }

  Future<ApiResponse<ClientSubscriptionModel>> processPayment({
    required int packageId,
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required String cvv,
  }) {
    return _apiService.processPayment(
      packageId: packageId,
      cardNumber: cardNumber,
      cardHolderName: cardHolderName,
      expiryDate: expiryDate,
      cvv: cvv,
    );
  }

  Future<ApiResponse<ClientSubscriptionModel>> getMySubscription() {
    return _apiService.getMySubscription();
  }

  Future<ApiResponse<ClientSubscriptionModel>> getClientSubscription(int clientId) {
    return _apiService.getClientSubscription(clientId);
  }

  Future<ApiResponse<List<SubscriptionPackageModel>>> getCoachPackages() {
    return _apiService.getCoachPackages();
  }

  Future<ApiResponse<SubscriptionPackageModel>> createPackage(Map<String, dynamic> data) {
    return _apiService.createPackage(data);
  }

  Future<ApiResponse<SubscriptionPackageModel>> updatePackage(int id, Map<String, dynamic> data) {
    return _apiService.updatePackage(id, data);
  }

  Future<ApiResponse<void>> deletePackage(int id) {
    return _apiService.deletePackage(id);
  }

  Future<ApiResponse<PaymentTransactionModel>> addToCart(int packageId) {
    return _apiService.addToCart(packageId);
  }

  Future<ApiResponse<void>> removeFromCart(int transactionId) {
    return _apiService.removeFromCart(transactionId);
  }

  Future<ApiResponse<List<PaymentTransactionModel>>> getMyTransactions() {
    return _apiService.getMyTransactions();
  }

  Future<ApiResponse<ClientSubscriptionModel>> processPaymentForTransaction({
    required int transactionId,
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required String cvv,
  }) {
    return _apiService.processPaymentForTransaction(
      transactionId: transactionId,
      cardNumber: cardNumber,
      cardHolderName: cardHolderName,
      expiryDate: expiryDate,
      cvv: cvv,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> initiateCheckout(int transactionId) {
    return _apiService.initiateCheckout(transactionId);
  }

  Future<ApiResponse<void>> triggerPaymentWebhook({
    required String sessionId,
    required String status,
  }) {
    return _apiService.triggerPaymentWebhook(
      sessionId: sessionId,
      status: status,
    );
  }

  Future<ApiResponse<PurchaseIntentModel>> getPurchaseIntent(int transactionId) {
    return _apiService.getPurchaseIntent(transactionId);
  }

  Future<ApiResponse<CoachDashboardStats>> getCoachDashboardStats() {
    return _apiService.getCoachDashboardStats();
  }
}
