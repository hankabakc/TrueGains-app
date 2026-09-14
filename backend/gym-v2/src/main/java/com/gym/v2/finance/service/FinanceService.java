package com.gym.v2.finance.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.repository.CoachRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.SecurityUtils;
import com.gym.v2.core.security.EncryptionConverter;
import com.gym.v2.finance.dto.ClientSubscriptionDTO;
import com.gym.v2.finance.dto.PaymentRequestDTO;
import com.gym.v2.finance.dto.SubscriptionPackageDTO;
import com.gym.v2.finance.dto.PurchaseIntentDTO;
import com.gym.v2.finance.entity.ClientSubscription;
import com.gym.v2.finance.entity.PaymentTransaction;
import com.gym.v2.finance.entity.SubscriptionPackage;
import com.gym.v2.finance.entity.Order;
import com.gym.v2.finance.entity.OrderStatus;
import com.gym.v2.finance.repository.ClientSubscriptionRepository;
import com.gym.v2.finance.repository.PaymentTransactionRepository;
import com.gym.v2.finance.repository.SubscriptionPackageRepository;
import com.gym.v2.finance.repository.OrderRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.HashSet;

@Service
public class FinanceService {

	private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(FinanceService.class);

	private final SubscriptionPackageRepository subscriptionPackageRepository;

	private final ClientSubscriptionRepository clientSubscriptionRepository;

	private final PaymentTransactionRepository paymentTransactionRepository;

	private final AppUserRepository appUserRepository;

	private final ClientRepository clientRepository;

	private final CoachRepository coachRepository;

	private final OrderRepository orderRepository;

	private final PaymentGatewayService paymentGatewayService;

	private final EncryptionConverter encryptionConverter;

	private final FinanceMapper financeMapper;

	private final java.time.Clock clock;

	// Constructor Injection (Pure Java, Lombok YASAK)
	public FinanceService(SubscriptionPackageRepository subscriptionPackageRepository,
			ClientSubscriptionRepository clientSubscriptionRepository,
			PaymentTransactionRepository paymentTransactionRepository, AppUserRepository appUserRepository,
			ClientRepository clientRepository, CoachRepository coachRepository, OrderRepository orderRepository,
			PaymentGatewayService paymentGatewayService, EncryptionConverter encryptionConverter,
			FinanceMapper financeMapper, java.time.Clock clock) {
		this.subscriptionPackageRepository = subscriptionPackageRepository;
		this.clientSubscriptionRepository = clientSubscriptionRepository;
		this.paymentTransactionRepository = paymentTransactionRepository;
		this.appUserRepository = appUserRepository;
		this.clientRepository = clientRepository;
		this.coachRepository = coachRepository;
		this.orderRepository = orderRepository;
		this.paymentGatewayService = paymentGatewayService;
		this.encryptionConverter = encryptionConverter;
		this.financeMapper = financeMapper;
		this.clock = clock;
	}

	@Transactional
	public com.gym.v2.finance.dto.CheckoutSessionResponse initiateCheckout(Long clientId, Long transactionId) {
		PaymentTransaction tx = paymentTransactionRepository.findById(transactionId)
			.orElseThrow(() -> new NotFoundException("İşlem bulunamadı."));
		if (!tx.getClient().getId().equals(clientId)) {
			throw new SecurityException("Bu işlem size ait değildir.");
		}
		if (!tx.getStatus().equals("PENDING")) {
			throw new BadRequestException("Bu işlem zaten tamamlanmış.");
		}

		Order order = new Order();
		order.setClient(tx.getClient());
		order.setPkg(tx.getPkg());
		order.setAmount(tx.getAmount());
		order.setStatus(OrderStatus.PENDING);
		order.setCreatedAt(clock.instant());

		order = orderRepository.save(order);

		com.gym.v2.finance.dto.CheckoutSessionResponse sessionResponse = paymentGatewayService
			.createCheckoutSession(order);
		order.setCheckoutSessionId(sessionResponse.checkoutSessionId());
		orderRepository.save(order);

		return sessionResponse;
	}

	/**
	 * Ödeme bildirimi geldiğinde siparişi sonuçlandırır.
	 * <p>
	 * Bildirimin <b>gövdesindeki</b> duruma bakılmaz; sonuç sağlayıcıya sorulur. Aksi
	 * hâlde "SUCCESS" yazan bir istek göndermek bedava abonelik anlamına gelirdi.
	 * </p>
	 */
	@Transactional
	public void handlePaymentWebhook(String checkoutSessionId) {
		Order order = orderRepository.findByCheckoutSessionId(checkoutSessionId)
			.orElseThrow(() -> new NotFoundException("Sipariş bulunamadı."));

		if (order.getStatus() != OrderStatus.PENDING) {
			return; // Zaten işlenmişse mükerrer işlemleri önlemek için sessizce dön
		}

		PaymentOutcome outcome = paymentGatewayService.verifyPayment(checkoutSessionId);

		if (outcome == PaymentOutcome.PENDING) {
			// Sağlayıcı henüz sonuçlandırmadı; sipariş PENDING kalır ve bildirim
			// tekrarlandığında yeniden değerlendirilir.
			return;
		}

		// Durum geçişi ATOMİK yapılır. Yukarıdaki kontrol "oku, kontrol et, yaz"
		// desenidir
		// ve arada kilit yoktur: sağlayıcılar teslim garantisi için webhook'u
		// tekrarladığından
		// iki bildirim aynı anda gelip ikisi de PENDING okuyabiliyor, abonelik iki kez
		// uzatılıyordu (tek ödemeyle çift süre). Yarışı veritabanı çözer: UPDATE yalnızca
		// bir çağrı için 1 döner, diğeri 0 alıp sessizce çıkar.
		OrderStatus target = outcome == PaymentOutcome.SUCCESS ? OrderStatus.COMPLETED : OrderStatus.FAILED;
		if (orderRepository.markIfPending(order.getId(), target) == 0) {
			return;
		}

		if (outcome == PaymentOutcome.SUCCESS) {
			AppUser clientUser = order.getClient();
			activateSubscriptionForClient(clientUser, order.getPkg());

			// İlgili sepet ödeme işlemini tamamla
			List<PaymentTransaction> txList = paymentTransactionRepository.findByClientIdWithPkg(clientUser.getId());
			for (PaymentTransaction tx : txList) {
				if (tx.getStatus().equals("PENDING") && tx.getPkg().getId().equals(order.getPkg().getId())) {
					tx.setStatus("SUCCESS");
					tx.setTransactionDate(clock.instant());
					paymentTransactionRepository.save(tx);
					break;
				}
			}
		}
		else {
			List<PaymentTransaction> txList = paymentTransactionRepository
				.findByClientIdWithPkg(order.getClient().getId());
			for (PaymentTransaction tx : txList) {
				if (tx.getStatus().equals("PENDING") && tx.getPkg().getId().equals(order.getPkg().getId())) {
					tx.setStatus("FAILED");
					tx.setTransactionDate(clock.instant());
					paymentTransactionRepository.save(tx);
					break;
				}
			}
		}
	}

	@Transactional(readOnly = true)
	public ClientSubscriptionDTO getClientSubscription(Long coachId, Long clientId) {
		// Güvenlik Kontrolü: Sorgulanan sporcu bu koça mı bağlı? (IDOR Önlemi)
		ClientEntity client = clientRepository.findByUserId(clientId)
			.orElseThrow(() -> new NotFoundException("Sporcu profili bulunamadı."));

		if (!coachId.equals(client.getCoachId())) {
			throw new SecurityException("Bu sporcunun abonelik bilgilerine erişim yetkiniz yoktur.");
		}

		return clientSubscriptionRepository.findActiveSubscriptionByClientId(clientId)
			.map(this::enrichSubscriptionDTO)
			.orElse(null);
	}

	/**
	 * Sporcunun kendi aboneliğini sorguladığı metot (Koç kontrolü gerektirmez).
	 */
	@Transactional(readOnly = true)
	public ClientSubscriptionDTO getClientSubscription(Long clientId) {
		return clientSubscriptionRepository.findActiveSubscriptionByClientId(clientId)
			.map(this::enrichSubscriptionDTO)
			.orElse(null);
	}

	private ClientSubscriptionDTO enrichSubscriptionDTO(ClientSubscription sub) {
		ClientSubscriptionDTO dto = financeMapper.toDTO(sub);

		String clientName = clientRepository.findByUserId(sub.getClient().getId())
			.map(client -> client.getFullName())
			.orElse(sub.getClient().getEmail());

		String coachName = "Kişisel Antrenman (Koç Yok)";
		if (sub.getCoach() != null) {
			coachName = coachRepository.findByUserId(sub.getCoach().getId())
				.map(coach -> coach.getFullName())
				.orElse("Bilinmeyen Koç");
		}

		long daysRemaining = ChronoUnit.DAYS.between(LocalDate.now(clock), sub.getEndDate());
		if (daysRemaining < 0) {
			daysRemaining = 0;
		}

		// Yeni record nesnesi oluşturup alanları dolduruyoruz
		return new ClientSubscriptionDTO(dto.id(), clientName, coachName, dto.packageName(), dto.startDate(),
				dto.endDate(), dto.isActive(), daysRemaining, dto.price());
	}

	/**
	 * Mevcut oturum açmış kullanıcının bilgilerini SecurityContext üzerinden çözümler.
	 */
	public AppUser getCurrentUser() {
		String email = SecurityUtils.getCurrentUserEmail();
		return appUserRepository.findByEmail(email)
			.orElseThrow(() -> new NotFoundException("Oturum açmış kullanıcı bulunamadı."));
	}

	@Transactional(readOnly = true)
	public PurchaseIntentDTO getPurchaseIntent(Long clientId, Long transactionId) {
		PaymentTransaction tx = paymentTransactionRepository.findById(transactionId)
			.orElseThrow(() -> new NotFoundException("İşlem bulunamadı."));

		// IDOR Korunumu
		if (!tx.getClient().getId().equals(clientId)) {
			throw new SecurityException("Bu işlem size ait değildir.");
		}

		SubscriptionPackage pkg = tx.getPkg();
		if (pkg == null) {
			return new PurchaseIntentDTO("NONE", null);
		}

		Long newCoachId = pkg.getCoachId();
		Optional<ClientSubscription> activeSubOpt = clientSubscriptionRepository
			.findActiveSubscriptionByClientId(clientId);
		if (activeSubOpt.isEmpty()) {
			return new PurchaseIntentDTO("NONE", null);
		}

		ClientSubscription activeSub = activeSubOpt.get();
		Long activeCoachId = activeSub.getCoach() != null ? activeSub.getCoach().getId() : null;
		Long activePkgId = activeSub.getPkg().getId();

		if (newCoachId != null && !newCoachId.equals(activeCoachId)) {
			String currentCoachName = activeSub.getCoach() == null ? null
					: coachRepository.findByUserId(activeSub.getCoach().getId())
						.map(c -> c.getFullName())
						.orElse("Bilinmeyen Koç");
			return new PurchaseIntentDTO("DIFFERENT_COACH", currentCoachName);
		}
		else if (newCoachId != null && newCoachId.equals(activeCoachId) && !pkg.getId().equals(activePkgId)) {
			String currentCoachName = activeSub.getCoach() == null ? null
					: coachRepository.findByUserId(activeSub.getCoach().getId())
						.map(c -> c.getFullName())
						.orElse("Bilinmeyen Koç");
			return new PurchaseIntentDTO("SAME_COACH_DIFFERENT_PACKAGE", currentCoachName);
		}

		return new PurchaseIntentDTO("NONE", null);
	}

	@Transactional(readOnly = true)
	public List<SubscriptionPackageDTO> getCoachPackages(Long coachId) {
		List<SubscriptionPackage> packages = subscriptionPackageRepository.findByCoachIdAndIsActiveTrue(coachId);
		if (packages.isEmpty()) {
			return List.of();
		}
		List<Long> ids = packages.stream().map(SubscriptionPackage::getId).toList();
		LocalDate today = LocalDate.now(clock);
		java.util.Map<Long, Integer> countMap = new java.util.HashMap<>();
		List<Object[]> activeCounts = clientSubscriptionRepository.countActiveByPackageIds(ids, today);
		if (activeCounts != null) {
			for (Object[] row : activeCounts) {
				Long pkgId = (Long) row[0];
				Long count = (Long) row[1];
				countMap.put(pkgId, count != null ? count.intValue() : 0);
			}
		}
		return packages.stream().map(pkg -> financeMapper.toDTO(pkg, countMap.getOrDefault(pkg.getId(), 0))).toList();
	}

	@Transactional
	public SubscriptionPackageDTO createPackage(Long coachId, SubscriptionPackageDTO dto) {
		SubscriptionPackage pkg = new SubscriptionPackage();
		pkg.setName(dto.name());
		pkg.setPrice(dto.price());
		pkg.setDurationDays(dto.durationDays());
		pkg.setCoachId(coachId);
		pkg.setDescription(dto.description());
		pkg.setFeatures(dto.features());
		pkg.setQuota(dto.quota());
		pkg.setLevels(dto.levels());
		pkg.setMode(dto.mode());
		pkg = subscriptionPackageRepository.save(pkg);
		return financeMapper.toDTO(pkg);
	}

	@Transactional
	public SubscriptionPackageDTO updatePackage(Long coachId, Long packageId, SubscriptionPackageDTO dto) {
		SubscriptionPackage pkg = subscriptionPackageRepository.findById(packageId)
			.orElseThrow(() -> new NotFoundException("Paket bulunamadı."));
		if (!pkg.getCoachId().equals(coachId)) {
			throw new SecurityException("Bu paketi güncelleme yetkiniz yoktur.");
		}
		pkg.setName(dto.name());
		pkg.setPrice(dto.price());
		pkg.setDurationDays(dto.durationDays());
		pkg.setDescription(dto.description());
		pkg.setFeatures(dto.features());
		pkg.setQuota(dto.quota());
		pkg.setLevels(dto.levels());
		pkg.setMode(dto.mode());
		pkg = subscriptionPackageRepository.save(pkg);
		return financeMapper.toDTO(pkg);
	}

	@Transactional
	public void deletePackage(Long coachId, Long packageId) {
		SubscriptionPackage pkg = subscriptionPackageRepository.findById(packageId)
			.orElseThrow(() -> new NotFoundException("Paket bulunamadı."));
		if (!pkg.getCoachId().equals(coachId)) {
			throw new SecurityException("Bu paketi silme yetkiniz yoktur.");
		}
		pkg.setIsActive(false);
		subscriptionPackageRepository.save(pkg);
	}

	@Transactional
	public com.gym.v2.finance.dto.PaymentTransactionDTO addToCart(Long clientId, Long packageId) {
		AppUser clientUser = appUserRepository.findById(clientId)
			.orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));
		SubscriptionPackage pkg = subscriptionPackageRepository.findById(packageId)
			.orElseThrow(() -> new NotFoundException("Paket bulunamadı."));

		if (!Boolean.TRUE.equals(pkg.getIsActive())) {
			throw new BadRequestException("Bu paket artık satışta değildir.");
		}

		if (pkg.getQuota() != null) {
			long active = clientSubscriptionRepository.countActiveByPackageId(packageId,
					java.time.LocalDate.now(clock));
			if (active >= pkg.getQuota()) {
				throw new BadRequestException("Bu paketin kontenjanı dolu.");
			}
		}

		List<PaymentTransaction> txList = paymentTransactionRepository.findByClientIdWithPkg(clientId);
		for (PaymentTransaction tx : txList) {
			if (tx.getStatus().equals("PENDING") && tx.getPkg().getId().equals(packageId)) {
				return financeMapper.toDTO(tx);
			}
		}

		PaymentTransaction tx = new PaymentTransaction(null, clientUser, pkg, pkg.getPrice(), "PENDING",
				clock.instant());
		tx = paymentTransactionRepository.save(tx);
		return financeMapper.toDTO(tx);
	}

	@Transactional
	public void removeFromCart(Long clientId, Long transactionId) {
		PaymentTransaction tx = paymentTransactionRepository.findById(transactionId)
			.orElseThrow(() -> new NotFoundException("İşlem bulunamadı."));
		if (!tx.getClient().getId().equals(clientId)) {
			throw new SecurityException("Bu işlemi sepetinizden kaldırma yetkiniz yoktur.");
		}
		if (!tx.getStatus().equals("PENDING")) {
			throw new BadRequestException("Sadece ödeme bekleyen işlemler sepetten kaldırılabilir.");
		}
		paymentTransactionRepository.delete(tx);
	}

	@Transactional(readOnly = true)
	public List<com.gym.v2.finance.dto.PaymentTransactionDTO> getClientTransactions(Long clientId) {
		List<PaymentTransaction> transactions = paymentTransactionRepository.findByClientIdWithPkg(clientId);
		return financeMapper.toTxDTOList(transactions);
	}

	@Transactional
	public ClientSubscriptionDTO processPaymentForTransaction(Long clientId, Long transactionId,
			PaymentRequestDTO request) {
		PaymentTransaction tx = paymentTransactionRepository.findById(transactionId)
			.orElseThrow(() -> new NotFoundException("İşlem bulunamadı."));
		if (!tx.getClient().getId().equals(clientId)) {
			throw new SecurityException("Bu işlem size ait değildir.");
		}
		if (!tx.getStatus().equals("PENDING")) {
			throw new BadRequestException("Bu işlemin ödemesi zaten gerçekleştirilmiş.");
		}

		SubscriptionPackage pkg = tx.getPkg();

		if (!Boolean.TRUE.equals(pkg.getIsActive())) {
			throw new BadRequestException("Bu paket artık satışta değildir.");
		}

		String cardNo = request.cardNumber() != null ? request.cardNumber().replaceAll("\\s+", "") : "";
		if (cardNo.length() < 16) {
			tx.setStatus("FAILED");
			tx.setTransactionDate(clock.instant());
			paymentTransactionRepository.save(tx);
			throw new BadRequestException("Geçersiz kredi kartı numarası. 16 hane olmalıdır.");
		}

		tx.setStatus("SUCCESS");
		tx.setTransactionDate(clock.instant());
		paymentTransactionRepository.save(tx);

		AppUser clientUser = tx.getClient();
		ClientSubscription subToReturn = activateSubscriptionForClient(clientUser, pkg);

		return enrichSubscriptionDTO(subToReturn);
	}

	@Transactional(readOnly = true)
	public com.gym.v2.finance.dto.CoachDashboardStatsDTO getCoachDashboardStats() {
		AppUser coach = getCurrentUser();
		long activeStudents = clientRepository.countByCoachId(coach.getId());
		Instant startOfMonth = java.time.YearMonth.now(clock).atDay(1).atStartOfDay(clock.getZone()).toInstant();
		java.math.BigDecimal earnings = paymentTransactionRepository.sumCoachEarningsSince(coach.getId(), startOfMonth);
		return new com.gym.v2.finance.dto.CoachDashboardStatsDTO(activeStudents,
				earnings != null ? earnings : java.math.BigDecimal.ZERO);
	}

	@Transactional
	public int expireSubscriptions() {
		LocalDate today = LocalDate.now(clock);
		List<ClientSubscription> expired = clientSubscriptionRepository.findByIsActiveTrueAndEndDateBefore(today);
		if (expired.isEmpty()) {
			return 0;
		}

		for (ClientSubscription sub : expired) {
			sub.setIsActive(false);
		}
		clientSubscriptionRepository.saveAll(expired);

		Set<Long> affectedClientIds = new HashSet<>();
		for (ClientSubscription sub : expired) {
			affectedClientIds.add(sub.getClient().getId());
		}

		// Maliyet müşteri sayısıyla büyümemeli: bu görev zamanlanmış ve tek işlem içinde
		// koşuyor, yani bağlantıyı süresince tutuyor. Önceden müşteri başına 5 sorgu
		// (sayım + kullanıcı bul + kaydet + profil bul + kaydet) atılıyordu.
		List<Long> clientIds = new ArrayList<>(affectedClientIds);

		Set<Long> stillPremium = new HashSet<>();
		for (Object[] row : clientSubscriptionRepository.countActiveByClientIds(clientIds, today)) {
			stillPremium.add(((Number) row[0]).longValue());
		}

		List<Long> downgradeIds = clientIds.stream().filter(id -> !stillPremium.contains(id)).toList();
		if (downgradeIds.isEmpty()) {
			log.info("Süresi dolan {} adet abonelik pasifleştirildi.", expired.size());
			return expired.size();
		}

		List<AppUser> downgradedUsers = appUserRepository.findAllById(downgradeIds);
		for (AppUser user : downgradedUsers) {
			user.setIsPremium(false);
		}
		appUserRepository.saveAll(downgradedUsers);

		List<ClientEntity> profiles = clientRepository.findAllByUserIdIn(downgradeIds);
		List<ClientEntity> unlinked = profiles.stream().filter(p -> p.getCoachId() != null).toList();
		for (ClientEntity profile : unlinked) {
			profile.setCoachId(null);
		}
		if (!unlinked.isEmpty()) {
			clientRepository.saveAll(unlinked);
		}

		log.info("Süresi dolan {} adet abonelik pasifleştirildi.", expired.size());
		return expired.size();
	}

	private ClientSubscription activateSubscriptionForClient(AppUser clientUser, SubscriptionPackage pkg) {
		clientUser.setIsPremium(true);
		appUserRepository.save(clientUser);

		// Mevcut aktif abonelik kontrolü
		Optional<ClientSubscription> activeSubOpt = clientSubscriptionRepository
			.findActiveSubscriptionByClientId(clientUser.getId());
		ClientSubscription activeSub = null;
		if (activeSubOpt.isPresent() && activeSubOpt.get().getPkg().getId().equals(pkg.getId())) {
			activeSub = activeSubOpt.get();
		}

		if (activeSub != null) {
			// Aynı paket ise süreyi ekle
			activeSub.setEndDate(activeSub.getEndDate().plusDays(pkg.getDurationDays()));
			clientSubscriptionRepository.save(activeSub);
		}
		else {
			// Farklı paket veya aktif abonelik yoksa mevcutları pasif yap
			List<ClientSubscription> oldSubs = clientSubscriptionRepository.findByClientId(clientUser.getId());
			for (ClientSubscription sub : oldSubs) {
				if (sub.getIsActive()) {
					sub.setIsActive(false);
					clientSubscriptionRepository.save(sub);
				}
			}
		}

		// Antrenörü belirle ve otomatik eşleştirme (pairing) yap
		AppUser coachUser = null;
		if (pkg.getCoachId() != null) {
			coachUser = appUserRepository.findById(pkg.getCoachId()).orElse(null);
			if (coachUser != null) {
				Optional<ClientEntity> clientProfileOpt = clientRepository.findByUserId(clientUser.getId());
				if (clientProfileOpt.isPresent()) {
					ClientEntity clientProfile = clientProfileOpt.get();
					clientProfile.setCoachId(coachUser.getId());
					clientRepository.save(clientProfile);
				}
			}
		}
		else {
			Optional<ClientEntity> clientProfile = clientRepository.findByUserId(clientUser.getId());
			if (clientProfile.isPresent() && clientProfile.get().getCoachId() != null) {
				coachUser = appUserRepository.findById(clientProfile.get().getCoachId()).orElse(null);
			}
		}

		ClientSubscription subToReturn = activeSub;
		if (activeSub == null) {
			// Yeni aboneliği oluştur
			LocalDate startDate = LocalDate.now(clock);
			LocalDate endDate = startDate.plusDays(pkg.getDurationDays());
			ClientSubscription newSub = new ClientSubscription(null, clientUser, coachUser, pkg, startDate, endDate,
					true);
			subToReturn = clientSubscriptionRepository.save(newSub);
		}

		return subToReturn;
	}

}
