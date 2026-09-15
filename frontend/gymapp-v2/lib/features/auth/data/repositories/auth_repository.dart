import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/offline_cache.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import '../models/auth_model.dart';
import '../services/auth_api_service.dart';

class AuthRepository {
  final AuthApiService _apiService;
  final SyncManager _syncManager;
  final OfflineCache _offlineCache;

  AuthRepository(this._apiService, this._syncManager, this._offlineCache);

  Future<ApiResponse<AuthModel>> login(String email, String password) {
    return _apiService.login(email, password);
  }

  Future<ApiResponse<AuthModel>> restoreSession() {
    return _apiService.restoreSession();
  }

  Future<ApiResponse<void>> register(Map<String, dynamic> data) {
    return _apiService.register(data);
  }

  Future<ApiResponse<AuthModel>> verifyOtp(String email, String code) {
    return _apiService.verifyOtp(email, code);
  }

  Future<ApiResponse<void>> resendOtp(String email) {
    return _apiService.resendOtp(email);
  }

  Future<ApiResponse<void>> forgotPassword(String email) {
    return _apiService.forgotPassword(email);
  }

  Future<ApiResponse<void>> resetPassword(
    String email,
    String code,
    String newPassword,
  ) {
    return _apiService.resetPassword(email, code, newPassword);
  }

  /// Çıkış. [syncPending] açıkken bekleyen çevrimdışı kayıtlar, jeton hâlâ cihazdayken önce
  /// gönderilmeye çalışılır; gönderilemeyenler kuyrukta kalır, silinmez. Oturum düştüğünde
  /// ya da hesap silindiğinde jeton ölüdür, gönderim denenmez (false).
  Future<void> logout({bool syncPending = true}) async {
    if (syncPending) {
      await _syncManager.syncPendingData();
    }
    await _apiService.logout();
    // Okuma önbelleği sunucudaki verinin kopyasıdır; silinmesi veri kaybı değildir.
    await _offlineCache.clear();
  }
}
