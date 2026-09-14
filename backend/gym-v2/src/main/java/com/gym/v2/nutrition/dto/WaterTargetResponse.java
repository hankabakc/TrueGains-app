package com.gym.v2.nutrition.dto;

import java.time.LocalDateTime;

public record WaterTargetResponse(Long id, Integer targetMl, LocalDateTime validFrom, LocalDateTime validTo) {
}
