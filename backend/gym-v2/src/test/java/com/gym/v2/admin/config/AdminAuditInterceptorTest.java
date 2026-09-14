package com.gym.v2.admin.config;

import com.gym.v2.core.security.service.AuditLogService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import static org.mockito.Mockito.verify;

/**
 * Yonetim paneli erisimlerinin denetim defterine dustugunu dogrular.
 */
@ExtendWith(MockitoExtension.class)
class AdminAuditInterceptorTest {

	@Mock
	private AuditLogService auditLogService;

	@AfterEach
	void clearContext() {
		SecurityContextHolder.clearContext();
	}

	@Test
	void preHandle_recordsAdminEmailAndRequestLine() {
		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken("admin@test.com", null, java.util.List.of()));

		MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/v1/admin/overview");

		new AdminAuditInterceptor(auditLogService).preHandle(request, new MockHttpServletResponse(), new Object());

		verify(auditLogService).log(AdminAuditInterceptor.ACTION, "admin@test.com", "GET /api/v1/admin/overview");
	}

	/**
	 * Yetkisiz deneme de kayda gecmeli; guvenlik acisindan basarili erisim kadar
	 * onemlidir.
	 */
	@Test
	void preHandle_recordsUnauthenticatedAttemptAsAnonymous() {
		MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/v1/admin/overview");

		new AdminAuditInterceptor(auditLogService).preHandle(request, new MockHttpServletResponse(), new Object());

		verify(auditLogService).log(AdminAuditInterceptor.ACTION, "anonymous", "GET /api/v1/admin/overview");
	}

}
