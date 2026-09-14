package com.gym.v2.admin.config;

import com.gym.v2.core.security.service.AuditLogService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * Her yonetim paneli istegini denetim defterine yazar.
 * <p>
 * Neden tek tek servislerde degil de burada: KVKK'da sorulan sey "kim, ne zaman, kimin
 * verisine bakti". Kayit tek bir yerde ve <b>otomatik</b> olmazsa yarin eklenen bir uc
 * sessizce denetim disinda kalir. Yeni admin ucu yazan kimsenin log eklemeyi hatirlamasi
 * gerekmiyor.
 * </p>
 * <p>
 * Yalnizca istegin YAPILDIGI kaydedilir; yanit govdesi (kisisel veri icerebilir)
 * defterlere yazilmaz.
 * </p>
 */
@Component
public class AdminAuditInterceptor implements HandlerInterceptor {

	static final String ACTION = "ADMIN_ACCESS";

	private final AuditLogService auditLogService;

	public AdminAuditInterceptor(AuditLogService auditLogService) {
		this.auditLogService = auditLogService;
	}

	@Override
	public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
		auditLogService.log(ACTION, currentUserEmail(), request.getMethod() + " " + request.getRequestURI());
		return true;
	}

	/**
	 * Kimlik dogrulanmamis istek de kaydedilir ("anonymous"): yetkisiz deneme, basarili
	 * erisim kadar onemli bir denetim kaydidir.
	 */
	private String currentUserEmail() {
		Authentication auth = SecurityContextHolder.getContext().getAuthentication();
		if (auth == null || !auth.isAuthenticated()) {
			return "anonymous";
		}
		return auth.getName();
	}

}
