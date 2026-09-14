package com.gym.v2.nutrition.dto;

import java.time.LocalDate;

public record WaterDailyTotalResponse(LocalDate date, Integer totalIntakeMl, Integer targetMl) {
}
