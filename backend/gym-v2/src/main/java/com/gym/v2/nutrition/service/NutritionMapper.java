package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.core.config.CentralMapperConfig;
import com.gym.v2.nutrition.dto.*;
import com.gym.v2.nutrition.entity.*;
import org.mapstruct.*;

import java.util.List;

/**
 * MapStruct Mapper - Nutrition Module Optimized for Record DTOs. Adheres to "Anayasa" by
 * using NutritionMappingHelper for complex logic and avoiding @Autowired.
 */
@Mapper(config = CentralMapperConfig.class, uses = { NutritionMappingHelper.class, NutrientCalculator.class })
public interface NutritionMapper {

	@Mapping(target = "ownerId", source = "program.owner.id")
	@Mapping(target = "isMain", source = "program.main")
	@Mapping(target = "isTemplate", source = "program.template")
	@Mapping(target = "coach", source = "program.coach")
	@Mapping(target = "version", source = "program.version")
	@Mapping(target = "isOrphaned", source = "program.orphaned")
	DietProgramResponse toProgramResponse(DietProgram program, @Context Long userId);

	@Mapping(target = "fullName", source = "email")
	DietProgramResponse.CoachInfo toCoachInfo(AppUser coach);

	@Mapping(target = "name", source = "meal.mealType", qualifiedByName = "getMealName")
	MealResponse toMealResponse(Meal meal, @Context Long userId);

	@Mapping(target = "isOverridden", source = "isOverridden")
	@Mapping(target = "isBrandVerified", source = "isBrandVerified")
	@Mapping(target = "name", source = "food.name", qualifiedByName = "identity")
	@Mapping(target = "brand", source = "food.brand", qualifiedByName = "identity")
	FoodResponse toFoodResponse(Food food, boolean isOverridden, boolean isBrandVerified);

	@Mapping(target = "isOverridden", ignore = true)
	@Mapping(target = "isBrandVerified", ignore = true)
	@Mapping(target = "name", source = "food.name", qualifiedByName = "identity")
	@Mapping(target = "brand", source = "food.brand", qualifiedByName = "identity")
	FoodResponse toFoodResponseSimple(Food food);

	@Mapping(target = "date", source = "intakeDate")
	WaterIntakeResponse toWaterResponse(WaterIntake intake);

	List<WaterIntakeResponse> toWaterResponseList(List<WaterIntake> intakes);

	CustomGlassResponse toGlassResponse(CustomGlass glass);

	List<CustomGlassResponse> toGlassResponseList(List<CustomGlassResponse> glasses);

	MealTemplateResponse toTemplateResponse(MealTemplate template, @Context Long userId);

	@Mapping(target = "id", source = "template.id")
	@Mapping(target = "name",
			expression = "java(nutritionMappingHelper.toTemplateDetailResponse(template, userId).name())")
	@Mapping(target = "applicableMealTypes",
			expression = "java(nutritionMappingHelper.toTemplateDetailResponse(template, userId).applicableMealTypes())")
	@Mapping(target = "ingredients",
			expression = "java(nutritionMappingHelper.toTemplateDetailResponse(template, userId).ingredients())")
	@Mapping(target = "totalCalories",
			expression = "java(nutritionMappingHelper.toTemplateDetailResponse(template, userId).totalCalories())")
	@Mapping(target = "totalProtein",
			expression = "java(nutritionMappingHelper.toTemplateDetailResponse(template, userId).totalProtein())")
	@Mapping(target = "totalCarbs",
			expression = "java(nutritionMappingHelper.toTemplateDetailResponse(template, userId).totalCarbs())")
	@Mapping(target = "totalFat",
			expression = "java(nutritionMappingHelper.toTemplateDetailResponse(template, userId).totalFat())")
	@Mapping(target = "totalSugar",
			expression = "java(nutritionMappingHelper.toTemplateDetailResponse(template, userId).totalSugar())")
	@Mapping(target = "totalFiber",
			expression = "java(nutritionMappingHelper.toTemplateDetailResponse(template, userId).totalFiber())")
	@Mapping(target = "totalSodium",
			expression = "java(nutritionMappingHelper.toTemplateDetailResponse(template, userId).totalSodium())")
	@Mapping(target = "totalPotassium",
			expression = "java(nutritionMappingHelper.toTemplateDetailResponse(template, userId).totalPotassium())")
	@Mapping(target = "totalCholesterol",
			expression = "java(nutritionMappingHelper.toTemplateDetailResponse(template, userId).totalCholesterol())")
	MealTemplateDetailResponse toTemplateDetailResponse(MealTemplate template, @Context Long userId);

	@Mapping(target = "foodId", expression = "java(mealItem.getFood() != null ? "
			+ "mealItem.getFood().getId() : (mealItem.getRecipe() != null ? " + "mealItem.getRecipe().getId() : null))")
	@Mapping(target = "foodName",
			expression = "java(mealItem.getFood() != null ? "
					+ "mealItem.getFood().getName() : (mealItem.getRecipe() != null ? "
					+ "mealItem.getRecipe().getName() : \"Bilinmeyen\"))")
	@Mapping(target = "brand", expression = "java(mealItem.getFood() != null ? mealItem.getFood().getBrand() : null)")
	@Mapping(target = "recipe", ignore = true)
	MealItemResponse toMealItemResponse(MealItem mealItem, @Context Long userId);

	@Mapping(target = "clientId", source = "mealEntry.client.id")
	MealEntryResponse toMealEntryResponse(MealEntry mealEntry, @Context Long userId);

	@Mapping(target = "assignmentId", source = "program.id")
	@Mapping(target = "user", expression = "java(nutritionMappingHelper.toUserSummary(program.getOwner(), client))")
	@Mapping(target = "dietProgram", expression = "java(nutritionMappingHelper.toDietProgramSummary(program))")
	@Mapping(target = "status", expression = "java(program.isMain() ? \"ACTIVE\" : \"INACTIVE\")")
	DietAssignmentResponse toAssignmentResponse(DietProgram program, @Context ClientEntity client);

}
