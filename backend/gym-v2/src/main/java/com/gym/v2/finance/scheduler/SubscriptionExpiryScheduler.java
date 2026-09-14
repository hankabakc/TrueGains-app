package com.gym.v2.finance.scheduler;

import com.gym.v2.finance.service.FinanceService;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Süresi dolan abonelikleri günlük olarak kontrol eden scheduler.
 */
@Component
public class SubscriptionExpiryScheduler {

	private final FinanceService financeService;

	// Constructor Injection (Pure Java, Lombok YASAK)
	public SubscriptionExpiryScheduler(FinanceService financeService) {
		this.financeService = financeService;
	}

	@Scheduled(cron = "0 0 3 * * *", zone = "${app.timezone:Europe/Istanbul}")
	public void runDailyExpiry() {
		financeService.expireSubscriptions();
	}

}
