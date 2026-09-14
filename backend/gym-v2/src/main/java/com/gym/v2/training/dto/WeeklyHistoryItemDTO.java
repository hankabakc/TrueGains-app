package com.gym.v2.training.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDate;

public record WeeklyHistoryItemDTO(@JsonProperty("week_start_date") LocalDate weekStartDate,
		@JsonProperty("target_days") int targetDays, @JsonProperty("completed_days") int completedDays,
		@JsonProperty("success_percentage") double successPercentage) {
}
