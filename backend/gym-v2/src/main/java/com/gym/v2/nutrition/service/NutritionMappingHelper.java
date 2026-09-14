package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.core.security.EncryptionConverter;
import com.gym.v2.nutrition.dto.*;
import com.gym.v2.nutrition.entity.DietProgram;
import com.gym.v2.nutrition.entity.MealTemplate;
import com.gym.v2.nutrition.entity.MealType;
import org.mapstruct.Context;
import org.mapstruct.Named;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * NutritionMapper için karmaşık veri çözümleme, hesaplama ve yardımcı işlemleri yöneten
 * bileşen.
 */
@Component
public class NutritionMappingHelper {

	private final NutrientCalculator nutrientCalculator;

	private final EncryptionConverter encryptionConverter;

	public NutritionMappingHelper(NutrientCalculator nutrientCalculator, EncryptionConverter encryptionConverter) {
		this.nutrientCalculator = nutrientCalculator;
		this.encryptionConverter = encryptionConverter;
	}

	@Named("getMealName")
	public String getMealName(MealType type) {
		if (type == null) {
			return "Diğer";
		}
		return switch (type) {
			case KAHVALTI -> "Kahvaltı";
			case OGLE_YEMEGI -> "Öğle Yemeği";
			case AKSAM_YEMEGI -> "Akşam Yemeği";
			default -> "Diğer";
		};
	}

	@Named("toUserSummary")
	public DietAssignmentResponse.UserSummary toUserSummary(AppUser user, @Context ClientEntity client) {
		if (user == null) {
			return null;
		}
		String firstName = "";
		String lastName = "";
		String profilePhotoUrl = null;
		if (client != null) {
			profilePhotoUrl = client.getProfilePhotoUrl();
			String fullName = client.getFullName();

			if (fullName != null && !fullName.trim().isEmpty()) {
				String[] parts = fullName.trim().split("\\s+");
				if (parts.length == 1) {
					firstName = parts[0];
				}
				else if (parts.length > 1) {
					lastName = parts[parts.length - 1];
					StringBuilder sb = new StringBuilder();
					for (int i = 0; i < parts.length - 1; i++) {
						if (i > 0) {
							sb.append(" ");
						}
						sb.append(parts[i]);
					}
					firstName = sb.toString();
				}
			}
		}
		else {
			firstName = user.getEmail();
		}
		return new DietAssignmentResponse.UserSummary(user.getId(), firstName, lastName, profilePhotoUrl);
	}

	@Named("toDietProgramSummary")
	public DietAssignmentResponse.DietProgramSummary toDietProgramSummary(DietProgram program) {
		if (program == null) {
			return null;
		}
		return new DietAssignmentResponse.DietProgramSummary(program.getId(), program.getName(), program.getCreatedAt(),
				null);
	}

	@Named("toTemplateDetailResponse")
	public MealTemplateDetailResponse toTemplateDetailResponse(MealTemplate template, @Context Long userId) {
		if (template == null) {
			return null;
		}

		List<MealIngredientResponse> ingredients = template.getIngredients()
			.stream()
			.map(ing -> nutrientCalculator.toIngredientResponse(ing, userId))
			.toList();

		NutrientSummary summary = nutrientCalculator.calculateTotal(ingredients);

		return new MealTemplateDetailResponse(template.getId(), template.getName(), template.getApplicableMealTypes(),
				ingredients, summary.calories(), summary.protein(), summary.carbs(), summary.fat(), summary.sugar(),
				summary.fiber(), summary.sodium(), summary.potassium(), summary.cholesterol());
	}

	@Named("decrypt")
	public String decrypt(String encryptedValue) {
		return encryptionConverter.decrypt(encryptedValue);
	}

	@Named("identity")
	public String identity(String value) {
		return value;
	}

}
