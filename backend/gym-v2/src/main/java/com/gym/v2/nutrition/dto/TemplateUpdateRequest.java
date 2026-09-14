package com.gym.v2.nutrition.dto;

import com.gym.v2.nutrition.entity.MealType;
import java.math.BigDecimal;
import java.util.List;

public record TemplateUpdateRequest(String name, List<MealType> applicableMealTypes,
		List<TemplateIngredientRequest> ingredients) {
	public record TemplateIngredientRequest(Long foodId, Long recipeId, Long userRecipeId, BigDecimal amount,
			boolean ignoreOverride) {
	}
}
