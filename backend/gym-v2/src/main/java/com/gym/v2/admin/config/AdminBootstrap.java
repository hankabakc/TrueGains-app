package com.gym.v2.admin.config;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.core.security.service.AuditLogService;
import java.time.Clock;
import java.util.Locale;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * İlk yönetici hesabını ortam değişkeninden oluşturur.
 * <p>
 * Eskiden {@code V4__seed_data.sql} her kurulumda sabit e-posta ve sabit bcrypt özetiyle
 * bir yönetici açıyordu ve özet depoda duruyordu (K1-03). Artık kaynakta hesap bilgisi
 * yok: {@code ADMIN_EMAIL} ve {@code ADMIN_PASSWORD} verilirse ve veritabanında hiç
 * yönetici yoksa hesap açılışta bir kez oluşturulur. Yönetici zaten varsa hiçbir şey
 * yapılmaz, parola da değiştirilmez; değişkenler hesap oluştuktan sonra kaldırılabilir.
 * </p>
 * <p>
 * E-posta ve parola loga yazılmaz. Oluşturma denetim defterine düşer (KURALLAR §2.1).
 * </p>
 */
@Component
public class AdminBootstrap implements ApplicationRunner {

	static final String ACTION = "ADMIN_BOOTSTRAP";

	/** KURALLAR §1.3 şifre politikası: en az 10 karakter. */
	static final int MIN_PASSWORD_LENGTH = 10;

	private static final Logger logger = LoggerFactory.getLogger(AdminBootstrap.class);

	private final AppUserRepository userRepository;

	private final PasswordEncoder passwordEncoder;

	private final AuditLogService auditLogService;

	private final Clock clock;

	private final String email;

	private final String password;

	public AdminBootstrap(AppUserRepository userRepository, PasswordEncoder passwordEncoder,
			AuditLogService auditLogService, Clock clock, @Value("${app.admin.bootstrap.email:}") String email,
			@Value("${app.admin.bootstrap.password:}") String password) {
		this.userRepository = userRepository;
		this.passwordEncoder = passwordEncoder;
		this.auditLogService = auditLogService;
		this.clock = clock;
		this.email = email;
		this.password = password;
	}

	@Override
	public void run(ApplicationArguments args) {
		if (email.isBlank() || password.isBlank()) {
			return;
		}

		// Yapılandırma hatası veritabanına gitmeden reddedilir.
		if (password.length() < MIN_PASSWORD_LENGTH) {
			logger.warn("[ADMIN] ADMIN_PASSWORD en az {} karakter olmalı; ilk yönetici oluşturulmadı.",
					MIN_PASSWORD_LENGTH);
			return;
		}

		if (userRepository.existsByRole(UserRole.ADMIN)) {
			return;
		}

		String normalizedEmail = email.toLowerCase(Locale.ROOT).strip();
		if (userRepository.existsByEmail(normalizedEmail)) {
			logger.warn("[ADMIN] ADMIN_EMAIL başka bir hesapta kayıtlı; ilk yönetici oluşturulmadı.");
			return;
		}

		AppUser admin = AppUser.builder()
			.email(normalizedEmail)
			.password(passwordEncoder.encode(password))
			.role(UserRole.ADMIN)
			.registeredAt(clock.instant())
			.isActive(true)
			.build();
		userRepository.save(admin);

		auditLogService.log(ACTION, normalizedEmail, "İlk yönetici hesabı ortam değişkeninden oluşturuldu.");
		logger.info("[ADMIN] İlk yönetici hesabı oluşturuldu.");
	}

}
