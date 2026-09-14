package com.gym.v2.finance.controller;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.finance.dto.ClientSubscriptionDTO;
import com.gym.v2.finance.dto.PaymentTransactionDTO;
import com.gym.v2.finance.dto.SubscriptionPackageDTO;
import com.gym.v2.finance.dto.PurchaseIntentDTO;
import com.gym.v2.finance.service.FinanceService;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.time.Clock;
import java.util.List;

/**
 * Finans, Sepet ve Ödeme Modülü API Controller.
 */
@RestController
@RequestMapping("/api/v1/finance")
public class FinanceController {

	private final FinanceService financeService;

	private final Clock clock;

	// Constructor Injection (Pure Java, Lombok YASAK)
	public FinanceController(FinanceService financeService, Clock clock) {
		this.financeService = financeService;
		this.clock = clock;
	}

	/**
	 * Sporcu için koça ait paketleri listeler.
	 */
	@GetMapping("/packages/{coachId}")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<List<SubscriptionPackageDTO>> getAvailablePackages(@PathVariable Long coachId) {
		List<SubscriptionPackageDTO> packages = financeService.getCoachPackages(coachId);
		return ApiResponse.success(packages, "Koç paketleri listelendi.", clock.instant());
	}

	/**
	 * Koçun kendi paketlerini listeler.
	 */
	@GetMapping("/coach/packages")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<List<SubscriptionPackageDTO>> getCoachPackages() {
		AppUser currentCoach = financeService.getCurrentUser();
		List<SubscriptionPackageDTO> packages = financeService.getCoachPackages(currentCoach.getId());
		return ApiResponse.success(packages, "Paketleriniz listelendi.", clock.instant());
	}

	/**
	 * Koç için yeni üyelik paketi ekler.
	 */
	@PostMapping("/coach/packages")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<SubscriptionPackageDTO> createPackage(@RequestBody @Valid SubscriptionPackageDTO dto) {
		AppUser currentCoach = financeService.getCurrentUser();
		SubscriptionPackageDTO result = financeService.createPackage(currentCoach.getId(), dto);
		return ApiResponse.success(result, "Paket başarıyla oluşturuldu.", clock.instant());
	}

	/**
	 * Koç için mevcut paketi günceller.
	 */
	@PutMapping("/coach/packages/{id}")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<SubscriptionPackageDTO> updatePackage(@PathVariable Long id,
			@RequestBody @Valid SubscriptionPackageDTO dto) {
		AppUser currentCoach = financeService.getCurrentUser();
		SubscriptionPackageDTO result = financeService.updatePackage(currentCoach.getId(), id, dto);
		return ApiResponse.success(result, "Paket başarıyla güncellendi.", clock.instant());
	}

	/**
	 * Koç için mevcut paketi siler.
	 */
	@DeleteMapping("/coach/packages/{id}")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<Void> deletePackage(@PathVariable Long id) {
		AppUser currentCoach = financeService.getCurrentUser();
		financeService.deletePackage(currentCoach.getId(), id);
		return ApiResponse.success(null, "Paket başarıyla silindi.", clock.instant());
	}

	/**
	 * Sporcu için paketi sepete (ödeme bekleyenlere) ekler.
	 */
	@PostMapping("/cart/add/{packageId}")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<PaymentTransactionDTO> addToCart(@PathVariable Long packageId) {
		AppUser currentClient = financeService.getCurrentUser();
		PaymentTransactionDTO result = financeService.addToCart(currentClient.getId(), packageId);
		return ApiResponse.success(result,
				"Paket sepetinize eklendi. Ödemeyi tamamlamak için Ödemelerim sayfasına gidiniz.", clock.instant());
	}

	/**
	 * Sporcu sepetindeki (ödeme bekleyen) paketi sepetten çıkarır.
	 */
	@DeleteMapping("/cart/cancel/{transactionId}")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<Void> removeFromCart(@PathVariable Long transactionId) {
		AppUser currentClient = financeService.getCurrentUser();
		financeService.removeFromCart(currentClient.getId(), transactionId);
		return ApiResponse.success(null, "İşlem başarıyla iptal edildi ve sepetten kaldırıldı.", clock.instant());
	}

	/**
	 * Sporcunun işlem geçmişi (sepet ve eski ödemeler dahil) listesini getirir.
	 */
	@GetMapping("/transactions")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<List<PaymentTransactionDTO>> getMyTransactions() {
		AppUser currentClient = financeService.getCurrentUser();
		List<PaymentTransactionDTO> result = financeService.getClientTransactions(currentClient.getId());
		return ApiResponse.success(result, "İşlem geçmişiniz listelendi.", clock.instant());
	}

	/**
	 * Koç için hedef sporcunun aktif abonelik bilgilerini getirir (Salt Okunur).
	 */
	@GetMapping("/coach/subscription/{clientId}")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<ClientSubscriptionDTO> getClientSubscription(@PathVariable Long clientId) {
		AppUser currentCoach = financeService.getCurrentUser();
		ClientSubscriptionDTO result = financeService.getClientSubscription(currentCoach.getId(), clientId);
		if (result == null) {
			return ApiResponse.success(null, "Bu sporcunun aktif bir aboneliği bulunmamaktadır.", clock.instant());
		}
		return ApiResponse.success(result, "Sporcu abonelik bilgisi başarıyla getirildi.", clock.instant());
	}

	/**
	 * Sporcu kendi aktif aboneliğini görüntüler.
	 */
	@GetMapping("/my-subscription")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<ClientSubscriptionDTO> getMySubscription() {
		AppUser currentClient = financeService.getCurrentUser();
		ClientSubscriptionDTO result = financeService.getClientSubscription(currentClient.getId());
		return ApiResponse.success(result, "Abonelik bilginiz getirildi.", clock.instant());
	}

	/**
	 * Koç için panel istatistiklerini getirir (Aktif Öğrenci ve Aylık Kazanç).
	 */
	@GetMapping("/coach/dashboard-stats")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<com.gym.v2.finance.dto.CoachDashboardStatsDTO> getCoachDashboardStats() {
		return ApiResponse.success(financeService.getCoachDashboardStats(), "Panel verileri getirildi.",
				clock.instant());
	}

	/**
	 * Sporcu için satın alma niyeti durumunu sorgular.
	 */
	@GetMapping("/purchase-intent/{transactionId}")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<PurchaseIntentDTO> getPurchaseIntent(@PathVariable Long transactionId) {
		AppUser currentClient = financeService.getCurrentUser();
		PurchaseIntentDTO result = financeService.getPurchaseIntent(currentClient.getId(), transactionId);
		return ApiResponse.success(result, "Satın alma durumu getirildi.", clock.instant());
	}

}
