package com.gym.v2.nutrition.dto;

import java.util.List;

public record DietDayResponse(Long id, Integer dayOrder, String name, List<MealResponse> meals) {
}
