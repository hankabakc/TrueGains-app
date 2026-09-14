package com.gym.v2.admin.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gym.v2.admin.dto.AdminIssueDto;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Sentry sorunlarini okur.
 * <p>
 * <b>Jeton sunucuda kalir.</b> Tarayiciya Sentry anahtari verilseydi paneli acan herkes
 * tum projelerin hata verisine dogrudan erisebilirdi; panelin yetkilendirmesi asilmis
 * olurdu.
 * </p>
 * <p>
 * Yapilandirilmamissa (jeton bos) istisna atmaz: panel "yapilandirilmamis" der ve
 * calismaya devam eder. Izleme aracinin eksikligi panelin tamamini dusuremez.
 * </p>
 */
@Component
public class SentryIssueClient {

	private static final Logger logger = LoggerFactory.getLogger(SentryIssueClient.class);

	private static final Duration TIMEOUT = Duration.ofSeconds(8);

	private final HttpClient httpClient = HttpClient.newBuilder().connectTimeout(TIMEOUT).build();

	private final ObjectMapper objectMapper = new ObjectMapper();

	@Value("${admin.sentry.token:}")
	private String token;

	@Value("${admin.sentry.base-url:https://de.sentry.io}")
	private String baseUrl;

	@Value("${admin.sentry.organization:}")
	private String organization;

	public boolean isConfigured() {
		return token != null && !token.isBlank() && organization != null && !organization.isBlank();
	}

	/**
	 * Bir projenin cozulmemis sorunlarini getirir. Hata durumunda BOS liste doner;
	 * cagiran taraf panelin geri kalanini gostermeye devam edebilsin.
	 */
	public List<AdminIssueDto> fetchUnresolved(String projectSlug, String source, int limit) {
		if (!isConfigured() || projectSlug == null || projectSlug.isBlank()) {
			return List.of();
		}

		String url = "%s/api/0/projects/%s/%s/issues/?query=is:unresolved&statsPeriod=24h&limit=%d".formatted(baseUrl,
				organization, projectSlug, limit);

		try {
			HttpRequest request = HttpRequest.newBuilder(URI.create(url))
				.header("Authorization", "Bearer " + token)
				.timeout(TIMEOUT)
				.GET()
				.build();

			HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
			if (response.statusCode() != 200) {
				logger.warn("[ADMIN] Sentry {} yanıtı: {}", projectSlug, response.statusCode());
				return List.of();
			}
			return parse(response.body(), source);
		}
		catch (InterruptedException e) {
			Thread.currentThread().interrupt();
			return List.of();
		}
		catch (Exception e) {
			logger.warn("[ADMIN] Sentry {} okunamadı: {}", projectSlug, e.getMessage());
			return List.of();
		}
	}

	private List<AdminIssueDto> parse(String body, String source)
			throws com.fasterxml.jackson.core.JsonProcessingException {
		JsonNode root = objectMapper.readTree(body);
		List<AdminIssueDto> issues = new ArrayList<>();

		for (JsonNode node : root) {
			issues.add(new AdminIssueDto(node.path("id").asText(""), node.path("title").asText(""),
					node.path("culprit").asText(""), node.path("level").asText(""), node.path("count").asLong(0),
					node.path("userCount").asLong(0), node.path("lastSeen").asText(""),
					node.path("permalink").asText(""), source));
		}
		return issues;
	}

}
