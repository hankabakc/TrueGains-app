package com.gym.v2.admin.service;

import com.gym.v2.admin.dto.AdminAuditRowDto;
import com.gym.v2.admin.repository.AdminAuditRepository;
import java.time.Instant;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Denetim defteri okumalari. */
@Service
public class AdminAuditService {

	/** Süzgeç verilmeyen uç. Sorguya null an gönderilmez: bkz. AdminAuditRepository. */
	private static final Instant NO_LOWER_BOUND = Instant.EPOCH;

	private static final Instant NO_UPPER_BOUND = Instant.parse("9999-12-31T23:59:59Z");

	private final AdminAuditRepository adminAuditRepository;

	public AdminAuditService(AdminAuditRepository adminAuditRepository) {
		this.adminAuditRepository = adminAuditRepository;
	}

	@Transactional(readOnly = true)
	public Page<AdminAuditRowDto> search(String action, String email, Instant from, Instant to, Pageable pageable) {
		String emailPattern = emailPattern(email);
		Instant since = from == null ? NO_LOWER_BOUND : from;
		Instant until = to == null ? NO_UPPER_BOUND : to;

		return adminAuditRepository.search(blankToNull(action), emailPattern, since, until, pageable)
			.map(a -> new AdminAuditRowDto(a.getId(), a.getAction(), a.getUserEmail(), a.getIpAddress(), a.getDetails(),
					a.getCreatedAt()));
	}

	@Transactional(readOnly = true)
	public List<String> actions() {
		return adminAuditRepository.distinctActions();
	}

	/** Kucuk harfe cevirip % ile sarar; bkz. {@code AdminAuditRepository.search}. */
	private static String emailPattern(String email) {
		String normalized = blankToNull(email);
		return normalized == null ? null : "%" + normalized.toLowerCase(java.util.Locale.ROOT) + "%";
	}

	private static String blankToNull(String value) {
		return (value == null || value.isBlank()) ? null : value;
	}

}
