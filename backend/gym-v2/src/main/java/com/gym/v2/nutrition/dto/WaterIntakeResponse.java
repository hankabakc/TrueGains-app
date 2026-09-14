package com.gym.v2.nutrition.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;

public record WaterIntakeResponse(Long id, Integer amountMl, LocalDate date, LocalDateTime createdAt) {
}
