package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.nutrition.dto.MealTemplateDetailResponse;
import com.gym.v2.nutrition.dto.MealTemplateResponse;
import com.gym.v2.nutrition.dto.TemplateUpdateRequest;
import com.gym.v2.nutrition.entity.*;
import com.gym.v2.nutrition.repository.FoodRepository;
import com.gym.v2.nutrition.repository.MealTemplateRepository;
import com.gym.v2.nutrition.repository.RecipeRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * MealTemplateService - Yemek şablonlarının yönetimi. SRP ve Anayasa uyumlu olarak
 * refaktör edildi. Mapping işlemleri NutritionMapper'a devredildi.
 */
@Service
public class MealTemplateService {

	private final MealTemplateRepository mealTemplateRepository;

	private final NutritionMapper nutritionMapper;

	private final FoodRepository foodRepository;

	private final RecipeRepository recipeRepository;

	private final UserContextService userContextService;

	public MealTemplateService(MealTemplateRepository mealTemplateRepository, UserContextService userContextService,
			NutritionMapper nutritionMapper, FoodRepository foodRepository, RecipeRepository recipeRepository) {
		this.mealTemplateRepository = mealTemplateRepository;
		this.userContextService = userContextService;
		this.nutritionMapper = nutritionMapper;
		this.foodRepository = foodRepository;
		this.recipeRepository = recipeRepository;
	}

	@Transactional(readOnly = true)
	public List<MealTemplateResponse> getTemplates() {
		AppUser currentUser = userContextService.getCurrentUser();
		List<MealTemplate> templates = mealTemplateRepository.findAllByOwnerId(currentUser.getId());
		return templates.stream().map(t -> nutritionMapper.toTemplateResponse(t, currentUser.getId())).toList();
	}

	@Transactional(readOnly = true)
	public MealTemplateDetailResponse getTemplateDetail(Long templateId) {
		AppUser currentUser = userContextService.getCurrentUser();
		MealTemplate template = mealTemplateRepository.findByIdAndOwnerId(templateId, currentUser.getId())
			.orElseThrow(() -> new RuntimeException("Şablon bulunamadı."));

		return nutritionMapper.toTemplateDetailResponse(template, currentUser.getId());
	}

	@Transactional
	public MealTemplateResponse createTemplate(String name) {
		AppUser currentUser = userContextService.getCurrentUser();
		MealTemplate template = new MealTemplate(currentUser, name);
		template = mealTemplateRepository.save(template);
		return nutritionMapper.toTemplateResponse(template, currentUser.getId());
	}

	@Transactional
	public void updateTemplate(Long id, TemplateUpdateRequest request) {
		AppUser currentUser = userContextService.getCurrentUser();
		MealTemplate template = mealTemplateRepository.findByIdAndOwnerId(id, currentUser.getId())
			.orElseThrow(() -> new RuntimeException("Şablon bulunamadı."));

		template.setName(request.name());
		template.setApplicableMealTypes(request.applicableMealTypes());

		template.getIngredients().clear();
		for (var ingReq : request.ingredients()) {
			MealTemplateIngredient ingredient;
			if (ingReq.recipeId() != null) {
				Recipe recipe = recipeRepository.findById(ingReq.recipeId())
					.orElseThrow(() -> new RuntimeException("Tarif bulunamadı: " + ingReq.recipeId()));
				ingredient = new MealTemplateIngredient(template, recipe, ingReq.amount());
			}
			else {
				Food food = foodRepository.findById(ingReq.foodId())
					.orElseThrow(() -> new RuntimeException("Besin bulunamadı: " + ingReq.foodId()));
				ingredient = new MealTemplateIngredient(template, food, ingReq.amount(), ingReq.ignoreOverride());
			}
			template.getIngredients().add(ingredient);
		}
		mealTemplateRepository.save(template);
	}

	@Transactional
	public void deleteTemplate(Long id) {
		AppUser currentUser = userContextService.getCurrentUser();
		MealTemplate template = mealTemplateRepository.findByIdAndOwnerId(id, currentUser.getId())
			.orElseThrow(() -> new RuntimeException("Şablon bulunamadı."));
		mealTemplateRepository.delete(template);
	}

}
