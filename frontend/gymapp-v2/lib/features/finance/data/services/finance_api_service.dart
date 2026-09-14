import 'package:dio/dio.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import 'package:gymapp_v2/features/dashboard/data/models/coach_dashboard_stats.dart';
import 'package:gymapp_v2/features/finance/models/finance_models.dart';

/// Finans modülü API servisi. Backend ile HTTP iletişimini yönetir.
class FinanceApiService {
  final DioClient _dioClient;

  FinanceApiService(this._dioClient);

  /// Koça ait veya global paketleri listeler.
  Future<ApiResponse<List<SubscriptionPackageModel>>> getAvailablePackages(int coachId) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/finance/packages/$coachId',
      );
      return ApiResponse<List<SubscriptionPackageModel>>.fromJson(
        response.data!,
        (json) => (json as List)
            .map((i) => SubscriptionPackageModel.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Mock ödeme işlemini gerçekleştirir ve abonelik başlatır.
  Future<ApiResponse<ClientSubscriptionModel>> processPayment({
    required int packageId,
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required String cvv,
  }) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/finance/checkout',
        data: {
          'packageId': packageId,
          'cardNumber': cardNumber,
          'cardHolderName': cardHolderName,
          'expiryDate': expiryDate,
          'cvv': cvv,
        },
      );
      return ApiResponse<ClientSubscriptionModel>.fromJson(
        response.data!,
        (json) => ClientSubscriptionModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Koçun kendi paketlerini listeler.
  Future<ApiResponse<List<SubscriptionPackageModel>>> getCoachPackages() async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/finance/coach/packages',
      );
      return ApiResponse<List<SubscriptionPackageModel>>.fromJson(
        response.data!,
        (json) => (json as List)
            .map((i) => SubscriptionPackageModel.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Koç için yeni üyelik paketi ekler.
  Future<ApiResponse<SubscriptionPackageModel>> createPackage(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/finance/coach/packages',
        data: data,
      );
      return ApiResponse<SubscriptionPackageModel>.fromJson(
        response.data!,
        (json) => SubscriptionPackageModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Koç için mevcut paketi günceller.
  Future<ApiResponse<SubscriptionPackageModel>> updatePackage(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.put<Map<String, dynamic>>(
        '/finance/coach/packages/$id',
        data: data,
      );
      return ApiResponse<SubscriptionPackageModel>.fromJson(
        response.data!,
        (json) => SubscriptionPackageModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Koç için mevcut paketi siler.
  Future<ApiResponse<void>> deletePackage(int id) async {
    try {
      final response = await _dioClient.dio.delete<Map<String, dynamic>>(
        '/finance/coach/packages/$id',
      );
      return ApiResponse<void>.fromJson(response.data!, (json) {});
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Sporcu için paketi sepete (ödeme bekleyenlere) ekler.
  Future<ApiResponse<PaymentTransactionModel>> addToCart(int packageId) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/finance/cart/add/$packageId',
      );
      return ApiResponse<PaymentTransactionModel>.fromJson(
        response.data!,
        (json) => PaymentTransactionModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Sporcu sepetindeki (ödeme bekleyen) paketi sepetten çıkarır.
  Future<ApiResponse<void>> removeFromCart(int transactionId) async {
    try {
      final response = await _dioClient.dio.delete<Map<String, dynamic>>(
        '/finance/cart/cancel/$transactionId',
      );
      return ApiResponse<void>.fromJson(response.data!, (json) {});
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Sporcunun işlem geçmişi (sepet ve eski ödemeler dahil) listesini getirir.
  Future<ApiResponse<List<PaymentTransactionModel>>> getMyTransactions() async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/finance/transactions',
      );
      return ApiResponse<List<PaymentTransactionModel>>.fromJson(
        response.data!,
        (json) => (json as List)
            .map((i) => PaymentTransactionModel.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Sporcu sepetindeki bekleyen işlem için mock ödeme yapar ve aboneliği başlatır.
  Future<ApiResponse<ClientSubscriptionModel>> processPaymentForTransaction({
    required int transactionId,
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required String cvv,
  }) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/finance/checkout/$transactionId',
        data: {
          'cardNumber': cardNumber,
          'cardHolderName': cardHolderName,
          'expiryDate': expiryDate,
          'cvv': cvv,
        },
      );
      return ApiResponse<ClientSubscriptionModel>.fromJson(
        response.data!,
        (json) => ClientSubscriptionModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Sporcunun kendi aktif aboneliğini getirir.
  Future<ApiResponse<ClientSubscriptionModel>> getMySubscription() async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/finance/my-subscription',
      );
      return ApiResponse<ClientSubscriptionModel>.fromJson(
        response.data!,
        (json) => ClientSubscriptionModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Koç için hedef sporcunun aktif abonelik bilgilerini getirir.
  Future<ApiResponse<ClientSubscriptionModel>> getClientSubscription(int clientId) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/finance/coach/subscription/$clientId',
      );
      return ApiResponse<ClientSubscriptionModel>.fromJson(
        response.data!,
        (json) => ClientSubscriptionModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Checkout oturumu başlatır.
  Future<ApiResponse<Map<String, dynamic>>> initiateCheckout(int transactionId) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/finance/checkout/initiate/$transactionId',
      );
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data!,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Sahte ödeme sağlayıcısını (banka ekranını) tetikler.
  ///
  /// Not: Ödemenin sonucunu sunucuya doğrudan bildirmiyoruz. Sonuç mock sağlayıcıya
  /// yazılır, webhook'u sağlayıcı tetikler. Böylece gerçek entegrasyonda olduğu gibi
  /// iş mantığı istemcinin bildirdiği duruma güvenmez.
  Future<ApiResponse<void>> triggerPaymentWebhook({
    required String sessionId,
    required String status,
  }) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/mock-gateway/pay/$sessionId/$status',
      );
      return ApiResponse<void>.fromJson(response.data!, (json) {});
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Koç için panel istatistiklerini getirir.
  Future<ApiResponse<CoachDashboardStats>> getCoachDashboardStats() async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/finance/coach/dashboard-stats',
      );
      return ApiResponse<CoachDashboardStats>.fromJson(
        response.data!,
        (json) => CoachDashboardStats.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse<CoachDashboardStats>.error(friendlyError(e));
    }
  }

  /// Sporcu için satın alma niyeti durumunu sorgular.
  Future<ApiResponse<PurchaseIntentModel>> getPurchaseIntent(int transactionId) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/finance/purchase-intent/$transactionId',
      );
      return ApiResponse<PurchaseIntentModel>.fromJson(
        response.data!,
        (json) => PurchaseIntentModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  ApiResponse<T> _handleError<T>(DioException e) {
    String message = 'Finans servisi hatası';
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        message = (data['message'] as String?) ?? 'İşlem başarısız';
      }
    }
    return ApiResponse<T>.error(message);
  }
}
