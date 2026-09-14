package com.gym.v2.core.security.service;

import com.gym.v2.core.entity.AuditLog;
import com.gym.v2.core.repository.AuditLogRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.time.Clock;

/**
 * Kritik sistem olaylarını denetim (audit) loglarına kaydeden servis. Güvenlik
 * iyileştirmeleri (Proxy IP desteği ve Transaction İzolasyonu) içerir.
 */
@Service
public class AuditLogService {

	private final AuditLogRepository auditLogRepository;

	private final Clock clock;

	public AuditLogService(AuditLogRepository auditLogRepository, Clock clock) {
		this.auditLogRepository = auditLogRepository;
		this.clock = clock;
	}

	/**
	 * Olay kaydını bağımsız bir transaction'da gerçekleştirir. Bulgu #7:
	 * Propagation.REQUIRES_NEW ile loglama hatası ana işlemi etkilemez. Bulgu #6:
	 * X-Forwarded-For desteği ile gerçek client IP'si kaydedilir.
	 */
	@Async // İsteğe bağlı asenkron çalışma (Performans için)
	@Transactional(propagation = Propagation.REQUIRES_NEW)
	public void log(String action, String userEmail, String details) {
		String ipAddress = "0.0.0.0";
		ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();

		if (attributes != null) {
			HttpServletRequest request = attributes.getRequest();
			ipAddress = extractClientIp(request);
		}

		AuditLog auditLog = new AuditLog(action, userEmail, ipAddress, details, clock.instant());
		auditLogRepository.save(auditLog);
	}

	/**
	 * Reverse proxy (nginx) arkasındaki gerçek client IP'sini çeker (Bulgu #6).
	 */
	private String extractClientIp(HttpServletRequest request) {
		String xff = request.getHeader("X-Forwarded-For");
		if (xff != null && !xff.isBlank()) {
			return xff.split(",")[0].strip();
		}
		return request.getRemoteAddr();
	}

}
