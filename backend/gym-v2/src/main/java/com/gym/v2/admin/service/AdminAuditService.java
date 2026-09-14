package com.gym.v2.admin.service;

import com.gym.v2.admin.dto.AdminAuditRowDto;
import com.gym.v2.admin.repository.AdminAuditRepository;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Denetim defteri okumalari. */
@Service
public class AdminAuditService {

	private final AdminAuditRepository adminAuditRepository;

	public AdminAuditService(AdminAuditRepository adminAuditRepository) {
		this.adminAuditRepository = adminAuditRepository;
	}

	@Transactional(readOnly = true)
	public Page<AdminAuditRowDto> search(String action, String email, Pageable pageable) {
		String emailPattern = emailPattern(email);

		return adminAuditRepository.search(blankToNull(action), emailPattern, pageable)
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
