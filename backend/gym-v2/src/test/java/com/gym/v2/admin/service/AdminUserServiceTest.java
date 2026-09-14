package com.gym.v2.admin.service;

import com.gym.v2.admin.dto.AdminUserExportDto;
import com.gym.v2.admin.dto.AdminUserRowProjection;
import com.gym.v2.admin.repository.AdminUserRepository;
import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.repository.CoachRepository;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.EncryptionConverter;
import com.gym.v2.core.security.service.AuditLogService;
import com.gym.v2.finance.repository.ClientSubscriptionRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AdminUserServiceTest {

	@Mock
	private AdminUserRepository adminUserRepository;

	@Mock
	private AppUserRepository appUserRepository;

	@Mock
	private CoachRepository coachRepository;

	@Mock
	private ClientRepository clientRepository;

	@Mock
	private ClientSubscriptionRepository clientSubscriptionRepository;

	@Mock
	private EncryptionConverter encryptionConverter;

	@Mock
	private AuditLogService auditLogService;

	private AdminUserService service;

	private static final Instant NOW = Instant.parse("2026-09-04T12:00:00Z");

	@BeforeEach
	void setUp() {
		service = new AdminUserService(adminUserRepository, appUserRepository, coachRepository, clientRepository,
				clientSubscriptionRepository, encryptionConverter, auditLogService, Clock.fixed(NOW, ZoneOffset.UTC));
	}

	@Test
	void unlock_resetsCounterAndLockAndWritesAudit() {
		AppUser user = AppUser.builder()
			.email("sporcu@test.com")
			.role(UserRole.CLIENT)
			.failedLoginAttempts(3)
			.accountLockedUntil(Instant.parse("2026-09-04T12:10:00Z"))
			.build();

		when(appUserRepository.findById(7L)).thenReturn(Optional.of(user));

		service.unlock(7L, "admin@test.com");

		assertThat(user.getFailedLoginAttempts()).isZero();
		assertThat(user.getAccountLockedUntil()).isNull();
		verify(appUserRepository).save(user);
		verify(auditLogService).log(AdminUserService.ACTION_UNLOCK, "admin@test.com",
				"userId=7 attempts=3 lockedUntil=2026-09-04T12:10:00Z -> attempts=0 lockedUntil=null");
	}

	@Test
	void unlock_unknownUser_isRejectedAndWritesNoAudit() {
		when(appUserRepository.findById(42L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> service.unlock(42L, "admin@test.com")).isInstanceOf(NotFoundException.class);

		verify(appUserRepository, never()).save(any());
		verify(auditLogService, never()).log(anyString(), anyString(), anyString());
	}

	@Test
	void exportCsv_appliesFiltersAndWritesAuditWithRowCount() {
		AdminUserRowProjection row = mock(AdminUserRowProjection.class);
		when(row.getEmail()).thenReturn("antrenor@test.com");
		when(row.getRole()).thenReturn("COACH");
		when(adminUserRepository.search(eq("COACH"), eq("antrenor"), eq(true), any(Pageable.class)))
			.thenReturn(new PageImpl<>(List.of(row)));

		AdminUserExportDto result = service.exportCsv("COACH", "antrenor", true, "admin@test.com");

		assertThat(result.rowCount()).isEqualTo(1);
		assertThat(result.fileName()).isEqualTo("kullanicilar-2026-09-04.csv");
		assertThat(result.csv()).startsWith(AdminUserCsv.HEADER).contains("\"antrenor@test.com\"");
		verify(auditLogService).log(AdminUserService.ACTION_EXPORT, "admin@test.com",
				"rows=1 role=COACH query=antrenor active=true");
	}

}
