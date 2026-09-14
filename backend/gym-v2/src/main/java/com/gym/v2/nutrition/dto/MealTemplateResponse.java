package com.gym.v2.nutrition.dto;

import com.gym.v2.nutrition.entity.MealType;
import java.util.List;

/**
 * Yemek Şablonu Cevap DTO'su (MealTemplateResponse)
 */
public record MealTemplateResponse(Long id, String name, List<MealType> applicableMealTypes,
		List<MealIngredientResponse> ingredients) {
}
