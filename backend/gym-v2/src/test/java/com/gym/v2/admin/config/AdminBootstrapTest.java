package com.gym.v2.admin.config;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.core.security.service.AuditLogService;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * İlk yönetici hesabının ortam değişkeninden oluşturulması.
 * <p>
 * Kaynakta sabit yönetici hesabı yok (eski {@code V4__seed_data.sql} satırı çıkarıldı).
 * Bu sınıf, hesabın yalnızca doğru koşulda ve yalnızca bir kez açıldığını kilitler.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class AdminBootstrapTest {

	private static final Instant NOW = Instant.parse("2026-09-14T09:00:00Z");

	private static final String STRONG_PASSWORD = "GucluParola-2026";

	@Mock
	private AppUserRepository userRepository;

	@Mock
	private PasswordEncoder passwordEncoder;

	@Mock
	private AuditLogService auditLogService;

	private AdminBootstrap bootstrap(String email, String password) {
		return new AdminBootstrap(userRepository, passwordEncoder, auditLogService, Clock.fixed(NOW, ZoneOffset.UTC),
				email, password);
	}

	/**
	 * E-posta verilmemişse (parola verilmiş olsa bile) hiçbir şey yapılmaz; testler ve
	 * yönetici zaten olan kurulumlar bu yoldan geçer.
	 */
	@Test
	void withoutEmail_doesNothing() {
		bootstrap("", STRONG_PASSWORD).run(null);

		verifyNoInteractions(userRepository, passwordEncoder, auditLogService);
	}

	/** Kısa parola bir yapılandırma hatası; veritabanına gitmeden reddedilir. */
	@Test
	void withShortPassword_isRejectedBeforeTouchingDatabase() {
		bootstrap("yonetici@test.com", "Kisa-1").run(null);

		verifyNoInteractions(userRepository, passwordEncoder, auditLogService);
	}

	/**
	 * Yönetici zaten varsa yeni hesap açılmaz ve mevcut parolaya dokunulmaz: değişken
	 * unutulup bırakılsa bile her açılışta bir şey değişmemeli.
	 */
	@Test
	void whenAdminAlreadyExists_createsNothing() {
		when(userRepository.existsByRole(UserRole.ADMIN)).thenReturn(true);

		bootstrap("yonetici@test.com", STRONG_PASSWORD).run(null);

		verify(userRepository, never()).save(any());
		verifyNoInteractions(passwordEncoder, auditLogService);
	}

	/**
	 * E-posta başka bir hesaba aitse o hesap yöneticiye dönüştürülmez, yeni hesap da
	 * açılmaz.
	 */
	@Test
	void whenEmailBelongsToAnotherAccount_createsNothing() {
		when(userRepository.existsByRole(UserRole.ADMIN)).thenReturn(false);
		when(userRepository.existsByEmail("yonetici@test.com")).thenReturn(true);

		bootstrap("yonetici@test.com", STRONG_PASSWORD).run(null);

		verify(userRepository, never()).save(any());
		verifyNoInteractions(passwordEncoder, auditLogService);
	}

	@Test
	void withoutAdmin_createsAdminWithEncodedPasswordAndAudits() {
		when(userRepository.existsByRole(UserRole.ADMIN)).thenReturn(false);
		when(userRepository.existsByEmail("yonetici@test.com")).thenReturn(false);
		when(passwordEncoder.encode(STRONG_PASSWORD)).thenReturn("kodlanmis-ozet");

		bootstrap("  Yonetici@Test.com ", STRONG_PASSWORD).run(null);

		ArgumentCaptor<AppUser> saved = ArgumentCaptor.forClass(AppUser.class);
		verify(userRepository).save(saved.capture());
		AppUser admin = saved.getValue();
		assertThat(admin.getEmail()).isEqualTo("yonetici@test.com");
		assertThat(admin.getPassword()).isEqualTo("kodlanmis-ozet");
		assertThat(admin.getRole()).isEqualTo(UserRole.ADMIN);
		assertThat(admin.getIsActive()).isTrue();
		assertThat(admin.getRegisteredAt()).isEqualTo(NOW);

		verify(auditLogService).log(eq(AdminBootstrap.ACTION), eq("yonetici@test.com"), anyString());
	}

}
