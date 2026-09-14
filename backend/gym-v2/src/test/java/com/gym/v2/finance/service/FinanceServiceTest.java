package com.gym.v2.finance.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.repository.CoachRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.EncryptionConverter;
import com.gym.v2.finance.dto.PaymentTransactionDTO;
import com.gym.v2.finance.dto.ClientSubscriptionDTO;
import com.gym.v2.finance.dto.PaymentRequestDTO;
import com.gym.v2.finance.dto.SubscriptionPackageDTO;
import com.gym.v2.finance.entity.ClientSubscription;
import com.gym.v2.finance.entity.Order;
import com.gym.v2.finance.entity.OrderStatus;
import com.gym.v2.finance.entity.PaymentTransaction;
import com.gym.v2.finance.entity.SubscriptionPackage;
import com.gym.v2.finance.repository.ClientSubscriptionRepository;
import com.gym.v2.finance.repository.OrderRepository;
import com.gym.v2.finance.repository.PaymentTransactionRepository;
import com.gym.v2.finance.repository.SubscriptionPackageRepository;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FinanceServiceTest {

	@Mock
	private SubscriptionPackageRepository subscriptionPackageRepository;

	@Mock
	private ClientSubscriptionRepository clientSubscriptionRepository;

	@Mock
	private PaymentTransactionRepository paymentTransactionRepository;

	@Mock
	private AppUserRepository appUserRepository;

	@Mock
	private ClientRepository clientRepository;

	@Mock
	private CoachRepository coachRepository;

	@Mock
	private OrderRepository orderRepository;

	@Mock
	private PaymentGatewayService paymentGatewayService;

	@Mock
	private EncryptionConverter encryptionConverter;

	@Mock
	private FinanceMapper financeMapper;

	private Clock fixedClock;

	private FinanceService financeService;

	private AppUser createUser(Long id, String email) {
		AppUser user = AppUser.builder().email(email).build();
		ReflectionTestUtils.setField(user, "id", id);
		return user;
	}

	@BeforeEach
	void setUp() {
		fixedClock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);
		financeService = new FinanceService(subscriptionPackageRepository, clientSubscriptionRepository,
				paymentTransactionRepository, appUserRepository, clientRepository, coachRepository, orderRepository,
				paymentGatewayService, encryptionConverter, financeMapper, fixedClock);
	}

	@Test
	void addToCart_clientNotFound_throwsNotFoundException() {
		when(appUserRepository.findById(1L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> financeService.addToCart(1L, 10L)).isInstanceOf(NotFoundException.class);
	}

	@Test
	void addToCart_packageNotFound_throwsNotFoundException() {
		AppUser client = createUser(1L, "client@test.com");
		when(appUserRepository.findById(1L)).thenReturn(Optional.of(client));
		when(subscriptionPackageRepository.findById(10L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> financeService.addToCart(1L, 10L)).isInstanceOf(NotFoundException.class);
	}

	@Test
	void addToCart_packageInactive_throwsBadRequestExceptionAndDoesNotSave() {
		AppUser client = createUser(1L, "client@test.com");
		SubscriptionPackage pkg = new SubscriptionPackage(10L, "Standard", new BigDecimal("100.00"), 30, 2L, "Desc",
				false);

		when(appUserRepository.findById(1L)).thenReturn(Optional.of(client));
		when(subscriptionPackageRepository.findById(10L)).thenReturn(Optional.of(pkg));

		assertThatThrownBy(() -> financeService.addToCart(1L, 10L)).isInstanceOf(BadRequestException.class);

		verify(paymentTransactionRepository, never()).save(any());
	}

	@Test
	void addToCart_quotaFull_throwsBadRequestExceptionAndDoesNotSave() {
		AppUser client = createUser(1L, "client@test.com");
		SubscriptionPackage pkg = new SubscriptionPackage(10L, "Standard", new BigDecimal("100.00"), 30, 2L, "Desc",
				true);
		pkg.setQuota(5);

		when(appUserRepository.findById(1L)).thenReturn(Optional.of(client));
		when(subscriptionPackageRepository.findById(10L)).thenReturn(Optional.of(pkg));
		when(clientSubscriptionRepository.countActiveByPackageId(10L, LocalDate.of(2026, 1, 1))).thenReturn(5L);

		assertThatThrownBy(() -> financeService.addToCart(1L, 10L)).isInstanceOf(BadRequestException.class);

		verify(paymentTransactionRepository, never()).save(any());
	}

	@Test
	void addToCart_existingPendingTransaction_returnsExistingWithoutSavingNew() {
		AppUser client = createUser(1L, "client@test.com");
		SubscriptionPackage pkg = new SubscriptionPackage(10L, "Standard", new BigDecimal("100.00"), 30, 2L, "Desc",
				true);
		PaymentTransaction existingTx = new PaymentTransaction(100L, client, pkg, new BigDecimal("100.00"), "PENDING",
				Instant.now());
		PaymentTransactionDTO expectedDto = new PaymentTransactionDTO(100L, 10L, "Standard", 30,
				new BigDecimal("100.00"), "PENDING", Instant.now());

		when(appUserRepository.findById(1L)).thenReturn(Optional.of(client));
		when(subscriptionPackageRepository.findById(10L)).thenReturn(Optional.of(pkg));
		when(paymentTransactionRepository.findByClientIdWithPkg(1L)).thenReturn(List.of(existingTx));
		when(financeMapper.toDTO(existingTx)).thenReturn(expectedDto);

		PaymentTransactionDTO result = financeService.addToCart(1L, 10L);

		assertThat(result).isEqualTo(expectedDto);
		verify(paymentTransactionRepository, never()).save(any());
	}

	@Test
	void addToCart_validScenario_savesPendingTransactionWithMatchingPrice() {
		AppUser client = createUser(1L, "client@test.com");
		SubscriptionPackage pkg = new SubscriptionPackage(10L, "Standard", new BigDecimal("150.00"), 30, 2L, "Desc",
				true);

		when(appUserRepository.findById(1L)).thenReturn(Optional.of(client));
		when(subscriptionPackageRepository.findById(10L)).thenReturn(Optional.of(pkg));
		when(paymentTransactionRepository.findByClientIdWithPkg(1L)).thenReturn(Collections.emptyList());
		when(paymentTransactionRepository.save(any(PaymentTransaction.class)))
			.thenAnswer(invocation -> invocation.getArgument(0));

		financeService.addToCart(1L, 10L);

		ArgumentCaptor<PaymentTransaction> txCaptor = ArgumentCaptor.forClass(PaymentTransaction.class);
		verify(paymentTransactionRepository).save(txCaptor.capture());

		PaymentTransaction savedTx = txCaptor.getValue();
		assertThat(savedTx.getStatus()).isEqualTo("PENDING");
		assertThat(savedTx.getAmount()).isEqualByComparingTo(new BigDecimal("150.00"));
	}

	@Test
	void removeFromCart_transactionBelongsToOtherUser_throwsSecurityExceptionAndDoesNotDelete() {
		AppUser owner = createUser(2L, "owner@test.com");
		PaymentTransaction tx = new PaymentTransaction(100L, owner, new BigDecimal("100.00"), "PENDING", Instant.now());

		when(paymentTransactionRepository.findById(100L)).thenReturn(Optional.of(tx));

		assertThatThrownBy(() -> financeService.removeFromCart(1L, 100L)).isInstanceOf(SecurityException.class);

		verify(paymentTransactionRepository, never()).delete(any());
	}

	@Test
	void removeFromCart_transactionStatusNotPending_throwsBadRequestExceptionAndDoesNotDelete() {
		AppUser client = createUser(1L, "client@test.com");
		PaymentTransaction tx = new PaymentTransaction(100L, client, new BigDecimal("100.00"), "COMPLETED",
				Instant.now());

		when(paymentTransactionRepository.findById(100L)).thenReturn(Optional.of(tx));

		assertThatThrownBy(() -> financeService.removeFromCart(1L, 100L)).isInstanceOf(BadRequestException.class);

		verify(paymentTransactionRepository, never()).delete(any());
	}

	// ---------------------------------------------------------------------------
	// P2 — ÖDEME İŞLEME: çift tahsilat, yetki ve başarısız ödeme durumu
	// ---------------------------------------------------------------------------

	private SubscriptionPackage activePackage() {
		return new SubscriptionPackage(10L, "Standard", new BigDecimal("150.00"), 30, null, "Desc", true);
	}

	private PaymentRequestDTO cardRequest(String cardNumber) {
		return new PaymentRequestDTO(10L, cardNumber, "Ali Veli", "12/30", "123");
	}

	/** Abonelik aktivasyonunun uçtan uca yürümesi için gereken asgari stub'lar. */
	private void stubSubscriptionActivation() {
		lenient().when(clientSubscriptionRepository.findActiveSubscriptionByClientId(any()))
			.thenReturn(Optional.empty());
		lenient().when(clientSubscriptionRepository.findByClientId(any())).thenReturn(Collections.emptyList());
		lenient().when(clientSubscriptionRepository.save(any(ClientSubscription.class)))
			.thenAnswer(i -> i.getArgument(0));
		lenient().when(clientRepository.findByUserId(any())).thenReturn(Optional.empty());
		lenient().when(financeMapper.toDTO(any(ClientSubscription.class))).thenReturn(sampleSubscriptionDto());
	}

	/** {@code enrichSubscriptionDTO} bu nesnenin alanlarını okuduğu için null olamaz. */
	private ClientSubscriptionDTO sampleSubscriptionDto() {
		return new ClientSubscriptionDTO(5L, null, null, "Standard", LocalDate.of(2026, 1, 1),
				LocalDate.of(2026, 1, 31), true, 30L, new BigDecimal("150.00"));
	}

	@Test
	void processPayment_transactionNotFound_throwsNotFound() {
		when(paymentTransactionRepository.findById(100L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> financeService.processPaymentForTransaction(1L, 100L, cardRequest("1234567890123456")))
			.isInstanceOf(NotFoundException.class);
	}

	@Test
	void processPayment_transactionBelongsToAnotherClient_throwsSecurityExceptionAndDoesNotCharge() {
		AppUser owner = createUser(2L, "owner@test.com");
		PaymentTransaction tx = new PaymentTransaction(100L, owner, activePackage(), new BigDecimal("150.00"),
				"PENDING", Instant.now());
		when(paymentTransactionRepository.findById(100L)).thenReturn(Optional.of(tx));

		assertThatThrownBy(() -> financeService.processPaymentForTransaction(1L, 100L, cardRequest("1234567890123456")))
			.isInstanceOf(SecurityException.class);

		verify(paymentTransactionRepository, never()).save(any());
		verify(clientSubscriptionRepository, never()).save(any());
	}

	@Test
	void processPayment_alreadyPaidTransaction_throwsAndDoesNotChargeTwice() {
		AppUser client = createUser(1L, "client@test.com");
		PaymentTransaction tx = new PaymentTransaction(100L, client, activePackage(), new BigDecimal("150.00"),
				"SUCCESS", Instant.now());
		when(paymentTransactionRepository.findById(100L)).thenReturn(Optional.of(tx));

		assertThatThrownBy(() -> financeService.processPaymentForTransaction(1L, 100L, cardRequest("1234567890123456")))
			.isInstanceOf(BadRequestException.class);

		// Çift tahsilat koruması: ikinci abonelik açılmamalı.
		verify(clientSubscriptionRepository, never()).save(any());
	}

	@Test
	void processPayment_inactivePackage_throwsAndDoesNotCharge() {
		AppUser client = createUser(1L, "client@test.com");
		SubscriptionPackage inactive = new SubscriptionPackage(10L, "Standard", new BigDecimal("150.00"), 30, null,
				"Desc", false);
		PaymentTransaction tx = new PaymentTransaction(100L, client, inactive, new BigDecimal("150.00"), "PENDING",
				Instant.now());
		when(paymentTransactionRepository.findById(100L)).thenReturn(Optional.of(tx));

		assertThatThrownBy(() -> financeService.processPaymentForTransaction(1L, 100L, cardRequest("1234567890123456")))
			.isInstanceOf(BadRequestException.class);

		verify(clientSubscriptionRepository, never()).save(any());
	}

	@Test
	void processPayment_shortCardNumber_marksTransactionFailedAndCreatesNoSubscription() {
		AppUser client = createUser(1L, "client@test.com");
		PaymentTransaction tx = new PaymentTransaction(100L, client, activePackage(), new BigDecimal("150.00"),
				"PENDING", Instant.now());
		when(paymentTransactionRepository.findById(100L)).thenReturn(Optional.of(tx));

		assertThatThrownBy(() -> financeService.processPaymentForTransaction(1L, 100L, cardRequest("1234")))
			.isInstanceOf(BadRequestException.class);

		// Başarısız ödeme kalıcı olarak işaretlenmeli; sepette PENDING olarak kalmamalı.
		assertThat(tx.getStatus()).isEqualTo("FAILED");
		verify(paymentTransactionRepository).save(tx);
		verify(clientSubscriptionRepository, never()).save(any());
	}

	@Test
	void processPayment_cardNumberWithSpaces_isNormalizedAndAccepted() {
		AppUser client = createUser(1L, "client@test.com");
		PaymentTransaction tx = new PaymentTransaction(100L, client, activePackage(), new BigDecimal("150.00"),
				"PENDING", Instant.now());
		when(paymentTransactionRepository.findById(100L)).thenReturn(Optional.of(tx));
		stubSubscriptionActivation();

		financeService.processPaymentForTransaction(1L, 100L, cardRequest("1234 5678 9012 3456"));

		// Boşluklu kart numarası reddedilmemeli (istemci maskeli girdi gönderiyor).
		assertThat(tx.getStatus()).isEqualTo("SUCCESS");
	}

	@Test
	void processPayment_validCard_marksSuccessActivatesPremiumAndCreatesSubscription() {
		AppUser client = createUser(1L, "client@test.com");
		PaymentTransaction tx = new PaymentTransaction(100L, client, activePackage(), new BigDecimal("150.00"),
				"PENDING", Instant.now());
		when(paymentTransactionRepository.findById(100L)).thenReturn(Optional.of(tx));
		stubSubscriptionActivation();

		financeService.processPaymentForTransaction(1L, 100L, cardRequest("1234567890123456"));

		assertThat(tx.getStatus()).isEqualTo("SUCCESS");
		assertThat(client.getIsPremium()).isTrue();
		verify(clientSubscriptionRepository).save(any(ClientSubscription.class));
	}

	@Test
	void processPayment_samePackageAlreadyActive_extendsEndDateInsteadOfDuplicating() {
		AppUser client = createUser(1L, "client@test.com");
		SubscriptionPackage pkg = activePackage();
		PaymentTransaction tx = new PaymentTransaction(100L, client, pkg, new BigDecimal("150.00"), "PENDING",
				Instant.now());
		ClientSubscription active = new ClientSubscription(5L, client, null, pkg, LocalDate.of(2026, 1, 1),
				LocalDate.of(2026, 1, 31), true);

		when(paymentTransactionRepository.findById(100L)).thenReturn(Optional.of(tx));
		when(clientSubscriptionRepository.findActiveSubscriptionByClientId(1L)).thenReturn(Optional.of(active));
		when(clientSubscriptionRepository.save(any(ClientSubscription.class))).thenAnswer(i -> i.getArgument(0));
		lenient().when(clientRepository.findByUserId(any())).thenReturn(Optional.empty());
		lenient().when(financeMapper.toDTO(any(ClientSubscription.class))).thenReturn(sampleSubscriptionDto());

		financeService.processPaymentForTransaction(1L, 100L, cardRequest("1234567890123456"));

		// Aynı paket yeniden alındığında süre uzatılmalı, ikinci abonelik açılmamalı.
		assertThat(active.getEndDate()).isEqualTo(LocalDate.of(2026, 3, 2));
	}

	// ---------------------------------------------------------------------------
	// P2.1 — KOÇ PAKET YÖNETİMİ: sahiplik (IDOR) kontrolü
	// ---------------------------------------------------------------------------

	private SubscriptionPackageDTO packageDto(String name, String price) {
		return new SubscriptionPackageDTO(10L, name, new BigDecimal(price), 30, null, "Açıklama", "Özellikler", 5, 0,
				"BASLANGIC", "ONLINE");
	}

	/** Koç A'ya (id 1) ait paket. */
	private SubscriptionPackage packageOfCoachOne() {
		return new SubscriptionPackage(10L, "Standard", new BigDecimal("150.00"), 30, 1L, "Desc", true);
	}

	@Test
	void updatePackage_packageNotFound_throwsNotFound() {
		when(subscriptionPackageRepository.findById(10L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> financeService.updatePackage(1L, 10L, packageDto("Yeni", "200.00")))
			.isInstanceOf(NotFoundException.class);
	}

	@Test
	void updatePackage_packageOfAnotherCoach_throwsSecurityExceptionAndDoesNotSave() {
		when(subscriptionPackageRepository.findById(10L)).thenReturn(Optional.of(packageOfCoachOne()));

		// Koç 2, koç 1'in paketini güncellemeye çalışıyor.
		assertThatThrownBy(() -> financeService.updatePackage(2L, 10L, packageDto("Ele geçirildi", "1.00")))
			.isInstanceOf(SecurityException.class);

		verify(subscriptionPackageRepository, never()).save(any());
	}

	@Test
	void updatePackage_ownPackage_appliesNewValues() {
		SubscriptionPackage pkg = packageOfCoachOne();
		when(subscriptionPackageRepository.findById(10L)).thenReturn(Optional.of(pkg));
		when(subscriptionPackageRepository.save(any(SubscriptionPackage.class))).thenAnswer(i -> i.getArgument(0));

		financeService.updatePackage(1L, 10L, packageDto("Premium", "250.00"));

		assertThat(pkg.getName()).isEqualTo("Premium");
		assertThat(pkg.getPrice()).isEqualByComparingTo(new BigDecimal("250.00"));
	}

	@Test
	void deletePackage_packageOfAnotherCoach_throwsSecurityExceptionAndDoesNotSave() {
		when(subscriptionPackageRepository.findById(10L)).thenReturn(Optional.of(packageOfCoachOne()));

		assertThatThrownBy(() -> financeService.deletePackage(2L, 10L)).isInstanceOf(SecurityException.class);

		verify(subscriptionPackageRepository, never()).save(any());
	}

	@Test
	void deletePackage_ownPackage_isSoftDeletedNotRemoved() {
		SubscriptionPackage pkg = packageOfCoachOne();
		when(subscriptionPackageRepository.findById(10L)).thenReturn(Optional.of(pkg));
		when(subscriptionPackageRepository.save(any(SubscriptionPackage.class))).thenAnswer(i -> i.getArgument(0));

		financeService.deletePackage(1L, 10L);

		// Yumuşak silme: mevcut abonelikler kayıtsız kalmasın diye satır silinmez.
		assertThat(pkg.getIsActive()).isFalse();
		verify(subscriptionPackageRepository, never()).delete(any());
	}

	@Test
	void createPackage_alwaysUsesCallersCoachIdNotTheOneInPayload() {
		when(subscriptionPackageRepository.save(any(SubscriptionPackage.class))).thenAnswer(i -> i.getArgument(0));
		// DTO'da başka bir koçun id'si taşınsa bile dikkate alınmamalı.
		SubscriptionPackageDTO payload = new SubscriptionPackageDTO(null, "Yeni", new BigDecimal("100.00"), 30, 999L,
				"Açıklama", "Özellikler", 5, 0, "BASLANGIC", "ONLINE");

		financeService.createPackage(7L, payload);

		ArgumentCaptor<SubscriptionPackage> captor = ArgumentCaptor.forClass(SubscriptionPackage.class);
		verify(subscriptionPackageRepository).save(captor.capture());
		assertThat(captor.getValue().getCoachId()).isEqualTo(7L);
	}

	// ---------------------------------------------------------------------------
	// P2.1 — KOÇUN SPORCU ABONELİĞİNİ SORGULAMASI: IDOR kontrolü
	// ---------------------------------------------------------------------------

	@Test
	void getClientSubscription_clientOfAnotherCoach_throwsSecurityException() {
		ClientEntity client = new ClientEntity();
		client.setCoachId(1L);
		when(clientRepository.findByUserId(50L)).thenReturn(Optional.of(client));

		assertThatThrownBy(() -> financeService.getClientSubscription(2L, 50L)).isInstanceOf(SecurityException.class);
	}

	@Test
	void getClientSubscription_unknownClientProfile_throwsNotFound() {
		when(clientRepository.findByUserId(50L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> financeService.getClientSubscription(2L, 50L)).isInstanceOf(NotFoundException.class);
	}

	@Test
	void getClientSubscription_ownClientWithoutActiveSubscription_returnsNull() {
		ClientEntity client = new ClientEntity();
		client.setCoachId(1L);
		when(clientRepository.findByUserId(50L)).thenReturn(Optional.of(client));
		when(clientSubscriptionRepository.findActiveSubscriptionByClientId(50L)).thenReturn(Optional.empty());

		assertThat(financeService.getClientSubscription(1L, 50L)).isNull();
	}

	// ---------------------------------------------------------------------------
	// P2.1 — ABONELİK SÜRESİ DOLDURMA (zamanlanmış iş)
	// ---------------------------------------------------------------------------

	@Test
	void expireSubscriptions_noExpiredSubscriptions_returnsZeroAndTouchesNothing() {
		when(clientSubscriptionRepository.findByIsActiveTrueAndEndDateBefore(LocalDate.of(2026, 1, 1)))
			.thenReturn(Collections.emptyList());

		assertThat(financeService.expireSubscriptions()).isZero();

		verify(clientSubscriptionRepository, never()).saveAll(any());
	}

	@Test
	void expireSubscriptions_expiredSubscription_isDeactivatedAndPremiumRevoked() {
		AppUser client = createUser(1L, "client@test.com");
		client.setIsPremium(true);
		ClientSubscription expired = new ClientSubscription(5L, client, null, activePackage(),
				LocalDate.of(2025, 12, 1), LocalDate.of(2025, 12, 31), true);

		when(clientSubscriptionRepository.findByIsActiveTrueAndEndDateBefore(LocalDate.of(2026, 1, 1)))
			.thenReturn(List.of(expired));
		// Aktif aboneliği kalmayan müşteri COUNT sonucunda hiç görünmez (boş liste).
		when(clientSubscriptionRepository.countActiveByClientIds(List.of(1L), LocalDate.of(2026, 1, 1)))
			.thenReturn(List.of());
		when(appUserRepository.findAllById(List.of(1L))).thenReturn(List.of(client));
		when(clientRepository.findAllByUserIdIn(List.of(1L))).thenReturn(List.of());

		assertThat(financeService.expireSubscriptions()).isEqualTo(1);

		assertThat(expired.getIsActive()).isFalse();
		// Başka aktif aboneliği kalmadıysa premium hakkı geri alınmalı.
		assertThat(client.getIsPremium()).isFalse();
	}

	@Test
	void expireSubscriptions_clientStillHasAnotherActiveSubscription_keepsPremium() {
		AppUser client = createUser(1L, "client@test.com");
		client.setIsPremium(true);
		ClientSubscription expired = new ClientSubscription(5L, client, null, activePackage(),
				LocalDate.of(2025, 12, 1), LocalDate.of(2025, 12, 31), true);

		when(clientSubscriptionRepository.findByIsActiveTrueAndEndDateBefore(LocalDate.of(2026, 1, 1)))
			.thenReturn(List.of(expired));
		// Aktif aboneliği olan müşteri COUNT sonucunda satır üretir.
		when(clientSubscriptionRepository.countActiveByClientIds(List.of(1L), LocalDate.of(2026, 1, 1)))
			.thenReturn(List.<Object[]>of(new Object[] { 1L, 1L }));

		financeService.expireSubscriptions();

		// Hâlâ aktif aboneliği var: premium alınmamalı.
		assertThat(client.getIsPremium()).isTrue();
		verify(appUserRepository, never()).save(any());
		verify(appUserRepository, never()).saveAll(any());
	}

	// ---------------------------------------------------------------------------
	// P2 — ÖDEME WEBHOOK'U: dış sistemden gelen çağrının mükerrerlik koruması
	// ---------------------------------------------------------------------------

	private Order pendingOrder(AppUser client, SubscriptionPackage pkg) {
		return new Order(1L, client, pkg, new BigDecimal("150.00"), OrderStatus.PENDING, "sess-1", Instant.now());
	}

	@Test
	void handlePaymentWebhook_unknownSession_throwsNotFound() {
		when(orderRepository.findByCheckoutSessionId("yok")).thenReturn(Optional.empty());

		assertThatThrownBy(() -> financeService.handlePaymentWebhook("yok")).isInstanceOf(NotFoundException.class);
	}

	@Test
	void handlePaymentWebhook_alreadyCompletedOrder_isIdempotentAndDoesNotActivateAgain() {
		AppUser client = createUser(1L, "client@test.com");
		Order order = pendingOrder(client, activePackage());
		order.setStatus(OrderStatus.COMPLETED);
		when(orderRepository.findByCheckoutSessionId("sess-1")).thenReturn(Optional.of(order));

		financeService.handlePaymentWebhook("sess-1");

		// Ödeme sağlayıcısı webhook'u tekrar gönderirse ikinci abonelik açılmamalı.
		// Sipariş zaten sonuçlandığı için sağlayıcıya sormaya bile gerek yok.
		verify(paymentGatewayService, never()).verifyPayment(any());
		verify(orderRepository, never()).save(any());
		verify(clientSubscriptionRepository, never()).save(any());
	}

	@Test
	void handlePaymentWebhook_successStatus_completesOrderAndMarksPendingTransactionSuccess() {
		AppUser client = createUser(1L, "client@test.com");
		SubscriptionPackage pkg = activePackage();
		Order order = pendingOrder(client, pkg);
		PaymentTransaction pending = new PaymentTransaction(100L, client, pkg, new BigDecimal("150.00"), "PENDING",
				Instant.now());

		when(orderRepository.findByCheckoutSessionId("sess-1")).thenReturn(Optional.of(order));
		when(paymentTransactionRepository.findByClientIdWithPkg(1L)).thenReturn(List.of(pending));
		when(paymentGatewayService.verifyPayment("sess-1")).thenReturn(PaymentOutcome.SUCCESS);
		when(orderRepository.markIfPending(order.getId(), OrderStatus.COMPLETED)).thenReturn(1);
		stubSubscriptionActivation();

		financeService.handlePaymentWebhook("sess-1");

		// Durum geçişi tek atomik UPDATE ile yapılır (mükerrer webhook koruması).
		verify(orderRepository).markIfPending(order.getId(), OrderStatus.COMPLETED);
		assertThat(pending.getStatus()).isEqualTo("SUCCESS");
		verify(clientSubscriptionRepository).save(any(ClientSubscription.class));
	}

	@Test
	void handlePaymentWebhook_failedStatus_marksOrderFailedAndActivatesNoSubscription() {
		AppUser client = createUser(1L, "client@test.com");
		SubscriptionPackage pkg = activePackage();
		Order order = pendingOrder(client, pkg);
		PaymentTransaction pending = new PaymentTransaction(100L, client, pkg, new BigDecimal("150.00"), "PENDING",
				Instant.now());

		when(orderRepository.findByCheckoutSessionId("sess-1")).thenReturn(Optional.of(order));
		when(paymentTransactionRepository.findByClientIdWithPkg(1L)).thenReturn(List.of(pending));
		when(paymentGatewayService.verifyPayment("sess-1")).thenReturn(PaymentOutcome.FAILED);
		when(orderRepository.markIfPending(order.getId(), OrderStatus.FAILED)).thenReturn(1);

		financeService.handlePaymentWebhook("sess-1");

		verify(orderRepository).markIfPending(order.getId(), OrderStatus.FAILED);
		assertThat(pending.getStatus()).isEqualTo("FAILED");
		// Başarısız ödemede kesinlikle abonelik açılmamalı.
		verify(clientSubscriptionRepository, never()).save(any());
	}

	@Test
	void handlePaymentWebhook_providerHasNotSettledYet_leavesOrderPending() {
		AppUser client = createUser(1L, "client@test.com");
		Order order = pendingOrder(client, activePackage());
		when(orderRepository.findByCheckoutSessionId("sess-1")).thenReturn(Optional.of(order));
		when(paymentGatewayService.verifyPayment("sess-1")).thenReturn(PaymentOutcome.PENDING);

		financeService.handlePaymentWebhook("sess-1");

		// Sağlayıcı henüz sonuçlandırmadıysa sipariş ne tamamlanır ne de iptal edilir.
		assertThat(order.getStatus()).isEqualTo(OrderStatus.PENDING);
		verify(orderRepository, never()).save(any());
		verify(clientSubscriptionRepository, never()).save(any());
	}

	@Test
	void handlePaymentWebhook_outcomeComesFromTheProviderNotTheRequest() {
		AppUser client = createUser(1L, "client@test.com");
		Order order = pendingOrder(client, activePackage());
		when(orderRepository.findByCheckoutSessionId("sess-1")).thenReturn(Optional.of(order));
		when(paymentGatewayService.verifyPayment("sess-1")).thenReturn(PaymentOutcome.FAILED);
		when(paymentTransactionRepository.findByClientIdWithPkg(1L)).thenReturn(List.of());
		when(orderRepository.markIfPending(order.getId(), OrderStatus.FAILED)).thenReturn(1);

		// Bildirimi gönderen taraf ne iddia ederse etsin, karar sağlayıcınındır:
		// metot artık bir durum parametresi almıyor.
		financeService.handlePaymentWebhook("sess-1");

		verify(paymentGatewayService).verifyPayment("sess-1");
		verify(orderRepository).markIfPending(order.getId(), OrderStatus.FAILED);
		verify(clientSubscriptionRepository, never()).save(any());
	}

	@Test
	void removeFromCart_validScenario_deletesTransaction() {
		AppUser client = createUser(1L, "client@test.com");
		PaymentTransaction tx = new PaymentTransaction(100L, client, new BigDecimal("100.00"), "PENDING",
				Instant.now());

		when(paymentTransactionRepository.findById(100L)).thenReturn(Optional.of(tx));

		financeService.removeFromCart(1L, 100L);

		verify(paymentTransactionRepository).delete(tx);
	}

	/**
	 * Mükerrer webhook koruması. Sağlayıcılar teslim garantisi için bildirimi tekrarlar;
	 * atomik geçiş olmadan iki bildirim aynı anda PENDING okuyup aboneliği iki kez
	 * uzatabiliyordu (tek ödemeyle çift süre).
	 */
	@Test
	void handlePaymentWebhook_secondConcurrentDelivery_activatesNoSecondSubscription() {
		AppUser client = createUser(1L, "client@test.com");
		Order order = pendingOrder(client, activePackage());

		when(orderRepository.findByCheckoutSessionId("sess-1")).thenReturn(Optional.of(order));
		when(paymentGatewayService.verifyPayment("sess-1")).thenReturn(PaymentOutcome.SUCCESS);
		// Yarışı ilk bildirim kazandı: bu çağrı için UPDATE hiçbir satırı etkilemez.
		when(orderRepository.markIfPending(order.getId(), OrderStatus.COMPLETED)).thenReturn(0);

		financeService.handlePaymentWebhook("sess-1");

		verify(clientSubscriptionRepository, never()).save(any());
		verify(appUserRepository, never()).save(any());
	}

}
