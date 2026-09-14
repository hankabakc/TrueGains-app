package com.gym.v2.admin.service;

import com.gym.v2.admin.dto.AdminOverviewDto;
import com.gym.v2.admin.dto.AdminOverviewProjection;
import com.gym.v2.admin.repository.AdminStatsRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Ozet sayilarin zaman pencereleri ve eslesmesi.
 */
@ExtendWith(MockitoExtension.class)
class AdminOverviewServiceTest {

	@Mock
	private AdminStatsRepository adminStatsRepository;

	@Mock
	private AdminOverviewProjection projection;

	private AdminOverviewService service;

	private static final Instant NOW = Instant.parse("2026-09-04T12:00:00Z");

	@BeforeEach
	void setUp() {
		service = new AdminOverviewService(adminStatsRepository, Clock.fixed(NOW, ZoneOffset.UTC));
	}

	/**
	 * Zaman esikleri sorguya {@code Clock}'tan gitmeli. Sorgu icinde {@code NOW()}
	 * kullanilsaydi bu davranis test edilemezdi.
	 */
	@Test
	void getOverview_derivesTimeWindowsFromClock() {
		when(adminStatsRepository.loadOverview(any(), any(), any(), any())).thenReturn(projection);

		service.getOverview();

		verify(adminStatsRepository).loadOverview(Instant.parse("2026-09-03T12:00:00Z"),
				Instant.parse("2026-08-28T12:00:00Z"), Instant.parse("2026-08-05T12:00:00Z"), LocalDate.of(2026, 9, 4));
	}

	/**
	 * Alanlarin karismadigini dogrular; hepsi ayni tipte oldugu icin yer degistirmesi
	 * derleyiciden kacar.
	 */
	@Test
	void getOverview_mapsEveryFieldToItsOwnSlot() {
		when(projection.getTotalUsers()).thenReturn(21L);
		when(projection.getClientCount()).thenReturn(9L);
		when(projection.getCoachCount()).thenReturn(11L);
		when(projection.getInactiveUsers()).thenReturn(1L);
		when(projection.getNewLast24h()).thenReturn(2L);
		when(projection.getNewLast7d()).thenReturn(5L);
		when(projection.getNewLast30d()).thenReturn(13L);
		when(projection.getActiveLast7d()).thenReturn(7L);
		when(projection.getPairedClients()).thenReturn(3L);
		when(projection.getActiveSubscriptions()).thenReturn(4L);
		when(adminStatsRepository.loadOverview(any(), any(), any(), any())).thenReturn(projection);

		AdminOverviewDto dto = service.getOverview();

		assertThat(dto).isEqualTo(new AdminOverviewDto(21L, 9L, 11L, 1L, 2L, 5L, 13L, 7L, 3L, 4L));
	}

}
