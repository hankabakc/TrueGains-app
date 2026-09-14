package com.gym.v2.membership.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.repository.CoachRepository;
import com.gym.v2.auth.repository.RefreshTokenRepository;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.SecurityUtils;
import com.gym.v2.core.security.service.AuditLogService;
import com.gym.v2.core.service.FileStorageService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.time.Clock;
import java.util.List;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Kullanıcının kendi hesabını silmesi (KVKK m.7 "silme/yok etme" hakkı, ayrıca Apple ve
 * Google'ın hesap açtıran uygulamalar için zorunlu kıldığı özellik).
 *
 * <h2>Neden satır silinmiyor da kimliksizleştiriliyor?</h2>
 * <p>
 * Kullanıcıya bağlı ~25 tablo var ve çoğunun yabancı anahtarı {@code NOT NULL}; düz bir
 * {@code DELETE} kısıt ihlaliyle patlar. Daha önemlisi, bazı kayıtların <b>kalması
 * gerekiyor</b>:
 * </p>
 * <ul>
 * <li><b>Ödeme kayıtları:</b> silinirse koçun kapanmış bir ayının cirosu geriye dönük
 * değişir; ayrıca VUK saklama yükümlülüğü var.</li>
 * <li><b>Sohbet mesajları:</b> silinirse karşı taraf konuşmayı yarım görür.</li>
 * <li><b>Koç değerlendirmeleri:</b> silinirse koçun ortalama puanı geriye dönük değişir
 * ve kötü yorum yazıp hesabını silen biri puanı geri yükseltebilir.</li>
 * </ul>
 * <p>
 * Bu yüzden yöntem şudur: <b>kişisel veri geri döndürülemez şekilde yok edilir</b>,
 * kaydın kendisi kimliksiz bir iskelet olarak kalır. KVKK'nın "anonim hâle getirme"
 * tanımı budur — veri artık belirli bir kişiyle ilişkilendirilemez.
 * </p>
 *
 * <h2>Ne yok edilir</h2>
 * <p>
 * Kimlik ve iletişim bilgileri (e-posta, telefon, ad-soyad, biyografi, fotoğraf, doğum
 * tarihi, vücut ölçüleri), oturum anahtarları, bildirim token'ı ve kullanıcıya ait tüm
 * içerik: ölçümler, antrenman programları ve geçmişi, diyet programları, öğün kayıtları,
 * su takibi, galeriler, kişisel tarifler. Yüklenmiş dosyalar diskten de silinir.
 * </p>
 */
@Service
public class AccountDeletionService {

	private static final Logger log = LoggerFactory.getLogger(AccountDeletionService.class);

	/** Silinen kullanıcının profilinde görünecek sabit ad. */
	private static final String ANONYMIZED_NAME = "Silinmiş kullanıcı";

	private final AppUserRepository userRepository;

	private final ClientRepository clientRepository;

	private final CoachRepository coachRepository;

	private final RefreshTokenRepository refreshTokenRepository;

	private final FileStorageService fileStorageService;

	private final AuditLogService auditLogService;

	private final PasswordEncoder passwordEncoder;

	private final Clock clock;

	@PersistenceContext
	private EntityManager entityManager;

	public AccountDeletionService(AppUserRepository userRepository, ClientRepository clientRepository,
			CoachRepository coachRepository, RefreshTokenRepository refreshTokenRepository,
			FileStorageService fileStorageService, AuditLogService auditLogService, PasswordEncoder passwordEncoder,
			Clock clock) {
		this.userRepository = userRepository;
		this.clientRepository = clientRepository;
		this.coachRepository = coachRepository;
		this.refreshTokenRepository = refreshTokenRepository;
		this.fileStorageService = fileStorageService;
		this.auditLogService = auditLogService;
		this.passwordEncoder = passwordEncoder;
		this.clock = clock;
	}

	/**
	 * Oturum açmış kullanıcının kendi hesabını siler. Başka bir kullanıcının hesabını
	 * silmenin yolu <b>yoktur</b>: hedef her zaman güvenlik bağlamındaki kullanıcıdır.
	 */
	@Transactional
	public void deleteMyAccount() {
		String email = SecurityUtils.getCurrentUserEmail();
		AppUser user = userRepository.findByEmail(email)
			.orElseThrow(() -> new NotFoundException("Oturum açmış kullanıcı bulunamadı."));

		Long userId = user.getId();
		log.info("[KVKK] Hesap silme başlatıldı. UserID: {}", userId);

		deleteOwnedFiles(user);
		deleteOwnedContent(userId, user.getRole());
		anonymizeProfile(user);
		anonymizeAccount(user);

		// Denetim kaydı kimlik içermez: yalnızca "şu kimlikli hesap silindi" bilgisi
		// tutulur, e-posta yazılmaz — aksi hâlde silinen veri audit_log'da yaşamaya
		// devam ederdi.
		auditLogService.log("ACCOUNT_DELETED", "user#" + userId, "Kullanıcı kendi hesabını sildi.");
		log.info("[KVKK] Hesap silme tamamlandı. UserID: {}", userId);
	}

	/**
	 * Diskteki yüklenmiş dosyaları siler.
	 * <p>
	 * Veritabanı satırını temizlemek yeterli değil: profil ve galeri fotoğrafları dosya
	 * sisteminde duruyor ve adresleri tahmin edilebilir olmasa da erişilebilir kalırdı.
	 * </p>
	 */
	private void deleteOwnedFiles(AppUser user) {
		List<String> urls = entityManager.createQuery("""
				SELECT c.profilePhotoUrl FROM ClientEntity c WHERE c.userId = :id AND c.profilePhotoUrl IS NOT NULL
				""", String.class).setParameter("id", user.getId()).getResultList();

		urls.forEach(fileStorageService::deleteByUrlQuietly);
		fileStorageService.deleteByUrlQuietly(user.getProfilePhotoUrl());
	}

	/**
	 * Kullanıcıya ait içeriği siler.
	 * <p>
	 * Sıra önemlidir: yabancı anahtarların çoğunda {@code ON DELETE CASCADE} yok, bu
	 * yüzden çocuk kayıtlar ebeveynden önce silinir. Ağaç kökleri (antrenman programı,
	 * diyet programı) varlık üzerinden silinir ki JPA'nın {@code cascade + orphanRemoval}
	 * zinciri çalışsın; yaprak tablolar toplu JPQL ile silinir.
	 * </p>
	 */
	private void deleteOwnedContent(Long userId, UserRole role) {
		// 1) Antrenman geçmişi — loglar seanslardan önce.
		bulkDelete("DELETE FROM WorkoutLog l WHERE l.session.user.id = :id", userId);
		bulkDelete("DELETE FROM WorkoutSession s WHERE s.user.id = :id", userId);
		bulkDelete("DELETE FROM WeeklyProgress w WHERE w.userId = :id", userId);

		// 2) Ağaç kökleri: varlık üzerinden sil ki alt koleksiyonlar da gitsin.
		entityManager
			.createQuery("SELECT b FROM TrainingBlock b WHERE b.client.id = :id OR b.coach.id = :id",
					com.gym.v2.training.entity.TrainingBlock.class)
			.setParameter("id", userId)
			.getResultList()
			.forEach(entityManager::remove);

		entityManager
			.createQuery("SELECT p FROM DietProgram p WHERE p.owner.id = :id",
					com.gym.v2.nutrition.entity.DietProgram.class)
			.setParameter("id", userId)
			.getResultList()
			.forEach(entityManager::remove);

		// 3) Beslenme ve takip kayıtları.
		bulkDelete("DELETE FROM MealEntry m WHERE m.client.id = :id", userId);
		bulkDelete("DELETE FROM WaterIntake w WHERE w.user.id = :id", userId);
		bulkDelete("DELETE FROM WaterTarget w WHERE w.user.id = :id", userId);
		bulkDelete("DELETE FROM CustomGlass g WHERE g.user.id = :id", userId);
		bulkDelete("DELETE FROM UserFoodOverride o WHERE o.user.id = :id", userId);
		bulkDelete("DELETE FROM UserRecipe r WHERE r.user.id = :id", userId);

		// 4) Ölçümler ve görseller.
		bulkDelete("DELETE FROM Measurement m WHERE m.user.id = :id", userId);
		bulkDelete("DELETE FROM ClientGallery g WHERE g.client.id = :id", userId);
		bulkDelete("DELETE FROM CoachGallery g WHERE g.coach.id = :id", userId);

		// 5) Sosyal bağlar. Mesajlar ve değerlendirmeler BİLEREK bırakılır (sınıf
		// açıklamasına bakınız); yalnızca kişiyi kişiye bağlayan kayıtlar silinir.
		bulkDelete("DELETE FROM UserBlock b WHERE b.blocker.id = :id OR b.blocked.id = :id", userId);
		bulkDelete("DELETE FROM PairingRequest p WHERE p.client.userId = :id OR p.coach.userId = :id", userId);

		// 6) Oturumlar ve kayıtlı cihazlar.
		bulkDelete("DELETE FROM RefreshToken t WHERE t.user.id = :id", userId);
		bulkDelete("DELETE FROM UserDeviceToken d WHERE d.user.id = :id", userId);

		if (role == UserRole.COACH) {
			// Koç silinince öğrencileri koçsuz kalır; programları "öksüz" olarak
			// işaretlenir ve sporcuya sor/sakla akışı devreye girer.
			entityManager.createQuery("UPDATE ClientEntity c SET c.coachId = NULL WHERE c.coachId = :id")
				.setParameter("id", userId)
				.executeUpdate();
		}

		entityManager.flush();
	}

	private void bulkDelete(String jpql, Long userId) {
		entityManager.createQuery(jpql).setParameter("id", userId).executeUpdate();
	}

	/** Rol profilindeki kimlik verisini yok eder. */
	private void anonymizeProfile(AppUser user) {
		clientRepository.findByUserId(user.getId()).ifPresent(client -> {
			client.setFullName(ANONYMIZED_NAME);
			client.setBio(null);
			client.setProfilePhotoUrl(null);
			client.setInstagramUrl(null);
			client.setWebsiteUrl(null);
			client.setTiktokUrl(null);
			client.setDateOfBirth(null);
			client.setGender(null);
			client.setHeightCm(null);
			client.setWeightKg(null);
			client.setProvince(null);
			client.setDistrict(null);
			client.getPublicPhotos().clear();
			client.setCoachId(null);
			clientRepository.save(client);
		});

		coachRepository.findByUserId(user.getId()).ifPresent(coach -> {
			coach.setFullName(ANONYMIZED_NAME);
			coach.setBio(null);
			coach.setProfilePhotoUrl(null);
			coach.setInstagramUrl(null);
			coach.setWebsiteUrl(null);
			coach.setTiktokUrl(null);
			coach.setHeightCm(null);
			coach.setWeightKg(null);
			coach.setProvince(null);
			coach.setDistrict(null);
			coachRepository.save(coach);
		});
	}

	/**
	 * Hesabın kendisini kimliksizleştirir ve girişe kapatır.
	 * <p>
	 * E-posta serbest bırakılır (benzersizlik kısıtı var): kişi isterse aynı adresle
	 * yeniden kaydolabilir, bu KVKK açısından da doğru davranıştır. Şifre yerine rastgele
	 * bir değer konur — boş bırakmak, ileride bir kod yolunun boş şifreyle eşleşmesine
	 * zemin hazırlar.
	 * </p>
	 */
	private void anonymizeAccount(AppUser user) {
		user.setEmail("silinmis-" + user.getId() + "-" + UUID.randomUUID() + "@deleted.invalid");
		user.setPassword(passwordEncoder.encode(UUID.randomUUID().toString()));
		user.setPhoneNumber(null);
		user.setProfilePhotoUrl(null);
		user.setFcmToken(null);
		user.setOtpCode(null);
		user.setOtpExpiresAt(null);
		user.setOtpLastSentAt(null);
		user.setLastAiRecipeSuggestion(null);
		user.setIsPremium(false);
		// isActive=false, Spring Security'nin `enabled` bayrağına bağlıdır
		// (UserDetailsServiceImpl); giriş bu satırla kapanır.
		user.setIsActive(false);
		user.setAccountLockedUntil(clock.instant().plusSeconds(0));
		userRepository.saveAndFlush(user);

		refreshTokenRepository.deleteAllByUser(user);
	}

}
