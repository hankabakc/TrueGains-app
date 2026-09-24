package com.gym.v2.nutrition.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;

/**
 * G-76 (KR13): diyet planının tamamı tek istekte. Belgede olmayan öğün ve besin silinir;
 * gün eklenmez/silinmez.
 */
public record DietProgramDocumentRequest(@NotNull(message = "Sürüm zorunludur.") Long version,
		@Size(max = 36, message = "Düzenleme kimliği en fazla 36 karakter olabilir.") String editId,
		@NotBlank(message = "Program adı boş olamaz.") @Size(max = 255,
				message = "Program adı en fazla 255 karakter olabilir.") String name,
		@NotNull(message = "Hedefler zorunludur.") @Valid UpdateNutritionGoalsRequest goals,
		@NotNull(message = "Günler zorunludur.") @Size(max = 31,
				message = "Bir planda en fazla 31 gün olabilir.") @Valid List<DayDoc> days) {

	public record DayDoc(@NotNull(message = "Gün kimliği zorunludur.") Long id,
			@NotNull(message = "Öğünler zorunludur.") @Size(max = 20,
					message = "Bir günde en fazla 20 öğün olabilir.") @Valid List<MealDoc> meals) {
	}

	public record MealDoc(@NotNull(message = "Öğün kimliği zorunludur.") Long id,
			@NotNull(message = "Besinler zorunludur.") @Size(max = 100,
					message = "Bir öğünde en fazla 100 besin olabilir.") @Valid List<IngredientDoc> ingredients) {
	}

	public record IngredientDoc(Long id, Long foodId, Long recipeId,
			@NotNull(message = "{validation.nutrition.amount.notNull}") @DecimalMin(value = "0.01",
					message = "{validation.nutrition.amount.min}") BigDecimal amount,
			@Size(max = 255, message = "Not en fazla 255 karakter olabilir.") String note, Boolean ignoreOverride) {
	}
}
