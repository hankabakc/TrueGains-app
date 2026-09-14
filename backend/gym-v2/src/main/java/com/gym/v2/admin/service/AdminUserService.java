package com.gym.v2.admin.service;

import com.gym.v2.admin.dto.AdminUserDetailDto;
import com.gym.v2.admin.dto.AdminUserExportDto;
import com.gym.v2.admin.dto.AdminUserRowDto;
import com.gym.v2.admin.dto.AdminUserRowProjection;
import com.gym.v2.admin.repository.AdminUserRepository;
import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.CoachEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.repository.CoachRepository;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.EncryptionConverter;
import com.gym.v2.core.security.service.AuditLogService;
import com.gym.v2.finance.repository.ClientSubscriptionRepository;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Yonetim panelinin kullanici islemleri.
 * <p>
 * Okuma tarafi {@link AdminUserRepository} uzerinden (yazma yuzeyi olmayan arayuz). Yazma
 * iki islem icin acik: hesabi pasiflestirme/geri acma ve giris kilidini acma. Ikisi ve
 * toplu disa aktarma ayrica ve acikca denetim defterine yazilir - okuma kaydi otomatik,
 * YAZMA kaydi neyin degistigini de icermeli.
 * </p>
 */
@Service
public class AdminUserService {

	static final String ACTION_STATUS_CHANGE = "ADMIN_USER_STATUS_CHANGE";

	static final String ACTION_UNLOCK = "ADMIN_USER_UNLOCK";

	static final String ACTION_EXPORT = "ADMIN_USER_EXPORT";

	private final AdminUserRepository adminUserRepository;

	private final AppUserRepository appUserRepository;

	private final CoachRepository coachRepository;

	private final ClientRepository clientRepository;

	private final ClientSubscriptionRepository clientSubscriptionRepository;

	private final EncryptionConverter encryptionConverter;

	private final AuditLogService auditLogService;

	private final Clock clock;

	public AdminUserService(AdminUserRepository adminUserRepository, AppUserRepository appUserRepository,
			CoachRepository coachRepository, ClientRepository clientRepository,
			ClientSubscriptionRepository clientSubscriptionRepository, EncryptionConverter encryptionConverter,
			AuditLogService auditLogService, Clock clock) {
		this.adminUserRepository = adminUserRepository;
		this.appUserRepository = appUserRepository;
		this.coachRepository = coachRepository;
		this.clientRepository = clientRepository;
		this.clientSubscriptionRepository = clientSubscriptionRepository;
		this.encryptionConverter = encryptionConverter;
		this.auditLogService = auditLogService;
		this.clock = clock;
	}

	@Transactional(readOnly = true)
	public Page<AdminUserRowDto> search(String role, String query, Boolean activeOnly, Pageable pageable) {
		return adminUserRepository.search(blankToNull(role), blankToNull(query), activeOnly, pageable).map(this::toRow);
	}

	/**
	 * Ekrandaki suzgeclerle eslesen BUTUN kullanicilari CSV olarak verir (KR9 → A:
	 * listedeki sutunlar, telefon yok).
	 * <p>
	 * Toplu kisisel veri cikisidir: otomatik erisim kaydina ek olarak suzgec ve satir
	 * sayisiyla ayrica denetim defterine yazilir. Eslesenlerin tamami tek sorguda bellege
	 * alinir; kullanici sayisi on binleri asarsa sayfa sayfa akisa gecilir.
	 * </p>
	 */
	@Transactional(readOnly = true)
	public AdminUserExportDto exportCsv(String role, String query, Boolean activeOnly, String adminEmail) {
		List<AdminUserRowDto> rows = adminUserRepository
			.search(blankToNull(role), blankToNull(query), activeOnly, Pageable.unpaged())
			.map(this::toRow)
			.getContent();

		String fileName = "kullanicilar-" + LocalDate.ofInstant(clock.instant(), ZoneOffset.UTC) + ".csv";
		auditLogService.log(ACTION_EXPORT, adminEmail, "rows=" + rows.size() + " role=" + blankToNull(role) + " query="
				+ blankToNull(query) + " active=" + activeOnly);
		return new AdminUserExportDto(fileName, rows.size(), AdminUserCsv.toCsv(rows));
	}

	@Transactional(readOnly = true)
	public AdminUserDetailDto getDetail(Long userId) {
		AppUser user = appUserRepository.findById(userId)
			.orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));

		Optional<CoachEntity> coach = coachRepository.findByUserId(userId);
		Optional<ClientEntity> client = clientRepository.findByUserId(userId);

		String fullName = coach.map(CoachEntity::getFullName)
			.orElseGet(() -> client.map(ClientEntity::getFullName).orElse(null));

		return new AdminUserDetailDto(user.getId(), user.getEmail(), fullName, user.getPhoneNumber(), user.getRole(),
				Boolean.TRUE.equals(user.getIsActive()), Boolean.TRUE.equals(user.getIsPremium()),
				user.getRegisteredAt(), user.getLastLoginAt(), user.getFailedLoginAttempts(),
				user.getAccountLockedUntil(), coach.map(CoachEntity::getProvince).orElse(null),
				coach.map(CoachEntity::getDistrict).orElse(null),
				coach.map(CoachEntity::getExperienceYears).orElse(null),
				coach.map(CoachEntity::getSpecialization).orElse(null),
				client.map(ClientEntity::getCoachId).orElse(null), clientSubscriptionRepository
					.countActiveByClientId(userId, LocalDate.ofInstant(clock.instant(), ZoneOffset.UTC)));
	}

	/**
	 * Hesabi pasiflestirir veya geri acar.
	 * <p>
	 * Silme bilerek yok: geri alinamaz bir islem, denetim defteri olsa bile veriyi geri
	 * getirmez. Hesap silme akisi uygulamada zaten var (KVKK) ve kullanicinin kendi
	 * talebiyle isliyor.
	 * </p>
	 */
	@Transactional
	public AdminUserDetailDto setActive(Long userId, boolean active, String adminEmail) {
		AppUser user = appUserRepository.findById(userId)
			.orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));

		boolean previous = Boolean.TRUE.equals(user.getIsActive());
		user.setIsActive(active);
		appUserRepository.save(user);

		auditLogService.log(ACTION_STATUS_CHANGE, adminEmail, "userId=" + userId + " " + previous + " -> " + active);

		return getDetail(userId);
	}

	/**
	 * Giris kilidini acar ve basarisiz giris sayacini sifirlar.
	 * <p>
	 * Kilit 5 hatali denemede 15 dk suruyor ({@code AuthenticationService}). Hesabin
	 * aktif/pasif durumuna DOKUNMAZ: pasif (veya silinmis) hesap kilidi acilsa da
	 * giremez.
	 * </p>
	 */
	@Transactional
	public AdminUserDetailDto unlock(Long userId, String adminEmail) {
		AppUser user = appUserRepository.findById(userId)
			.orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));

		String previous = "attempts=" + user.getFailedLoginAttempts() + " lockedUntil=" + user.getAccountLockedUntil();
		user.setFailedLoginAttempts(0);
		user.setAccountLockedUntil(null);
		appUserRepository.save(user);

		auditLogService.log(ACTION_UNLOCK, adminEmail,
				"userId=" + userId + " " + previous + " -> attempts=0 lockedUntil=null");

		return getDetail(userId);
	}

	private AdminUserRowDto toRow(AdminUserRowProjection p) {
		return new AdminUserRowDto(p.getId(), p.getEmail(),
				encryptionConverter.convertToEntityAttribute(p.getFullName()), UserRole.valueOf(p.getRole()),
				Boolean.TRUE.equals(p.getActive()), Boolean.TRUE.equals(p.getPremium()),
				ProjectionTime.toInstant(p.getRegisteredAt()), ProjectionTime.toInstant(p.getLastLoginAt()));
	}

	private static String blankToNull(String value) {
		return (value == null || value.isBlank()) ? null : value;
	}

}
