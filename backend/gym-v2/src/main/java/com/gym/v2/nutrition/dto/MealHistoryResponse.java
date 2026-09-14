package com.gym.v2.nutrition.dto;

import com.gym.v2.nutrition.entity.MealType;
import java.util.List;

public record MealHistoryResponse(MealType mealType, List<FoodResponse> foods) {
}
