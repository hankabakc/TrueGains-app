package com.gym.v2.admin.service;

import com.gym.v2.admin.dto.AdminErrorsDto;
import com.gym.v2.admin.dto.AdminIssueDto;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Hata ve cokme ozeti. Backend ve mobil projeleri birlestirip en cok tekrarlayanlari one
 * alir - panelde onemli olan "hangi hata kac kisiyi vuruyor".
 */
@Service
public class AdminErrorService {

	private static final int PER_PROJECT_LIMIT = 25;

	private static final int TOP_ISSUES = 15;

	private final SentryIssueClient sentryIssueClient;

	@Value("${admin.sentry.backend-project:}")
	private String backendProject;

	@Value("${admin.sentry.mobile-project:}")
	private String mobileProject;

	public AdminErrorService(SentryIssueClient sentryIssueClient) {
		this.sentryIssueClient = sentryIssueClient;
	}

	public AdminErrorsDto getErrors() {
		if (!sentryIssueClient.isConfigured()) {
			return new AdminErrorsDto(false,
					"Sentry yapılandırılmamış. SENTRY_AUTH_TOKEN ve admin.sentry.organization tanımlanmalı.", 0, 0,
					List.of());
		}

		List<AdminIssueDto> backend = sentryIssueClient.fetchUnresolved(backendProject, "BACKEND", PER_PROJECT_LIMIT);
		List<AdminIssueDto> mobile = sentryIssueClient.fetchUnresolved(mobileProject, "MOBILE", PER_PROJECT_LIMIT);

		List<AdminIssueDto> all = new ArrayList<>(backend);
		all.addAll(mobile);
		all.sort(Comparator.comparingLong(AdminIssueDto::count).reversed());

		return new AdminErrorsDto(true, null, backend.size(), mobile.size(),
				all.size() > TOP_ISSUES ? all.subList(0, TOP_ISSUES) : all);
	}

}
