package com.gym.v2.finance.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record ClientSubscriptionDTO(Long id, String clientName, String coachName, String packageName,
		LocalDate startDate, LocalDate endDate, Boolean isActive, Long daysRemaining, BigDecimal price) {

}
