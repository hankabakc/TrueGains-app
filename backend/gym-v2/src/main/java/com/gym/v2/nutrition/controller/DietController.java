package com.gym.v2.nutrition.controller;

import com.gym.v2.core.response.ApiResponse;
import java.time.Clock;
import org.springframework.security.access.prepost.PreAuthorize;
import com.gym.v2.nutrition.dto.BulkIngredientRequest;
import com.gym.v2.nutrition.dto.DietAssignmentResponse;
import com.gym.v2.nutrition.dto.DietProgramResponse;
import com.gym.v2.nutrition.dto.RecipeRequest;
import com.gym.v2.nutrition.dto.UpdateNutritionGoalsRequest;
import com.gym.v2.nutrition.service.DietIngredientService;
import com.gym.v2.nutrition.service.DietProgramService;
import com.gym.v2.nutrition.service.DietTemplateService;
import jakarta.validation.Valid;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

/**
 * Diyet Programı Kontrolcüsü (DietController) - SRP Uyumlu.
 */
@RestController
@RequestMapping("/api/v1/nutrition/diet")
@Validated
public class DietController {

	private final DietProgramService programService;

	private final DietIngredientService ingredientService;

	private final DietTemplateService templateService;

	private final Clock clock;

	public DietController(DietProgramService programService, DietIngredientService ingredientService,
			DietTemplateService templateService, Clock clock) {
		this.programService = programService;
		this.ingredientService = ingredientService;
		this.templateService = templateService;
		this.clock = clock;
	}

	@GetMapping("/my-programs")
	public ApiResponse<List<DietProgramResponse>> getMyPrograms() {
		return ApiResponse.success(programService.getMyPrograms(), "Programlarınız getirildi.", clock.instant());
	}

	@GetMapping("/main")
	public ApiResponse<DietProgramResponse> getMainProgram() {
		return ApiResponse.success(programService.getMainProgram(), "Aktif program getirildi.", clock.instant());
	}

	@GetMapping("/{id}")
	public ApiResponse<DietProgramResponse> getProgram(@PathVariable Long id) {
		return ApiResponse.success(programService.getProgram(id), "Program detayı getirildi.", clock.instant());
	}

	@PostMapping("/create")
	public ApiResponse<DietProgramResponse> createProgram(@RequestParam String name,
			@RequestParam(defaultValue = "false") boolean isMain) {
		return ApiResponse.success(programService.createProgram(name, isMain), "Diyet programı oluşturuldu.",
				clock.instant());
	}

	@PutMapping("/{id}/activate")
	public ApiResponse<Void> activateProgram(@PathVariable Long id) {
		programService.activateProgram(id);
		return ApiResponse.success(null, "Program aktif edildi.", clock.instant());
	}

	@PostMapping("/{id}/copy")
	public ApiResponse<DietProgramResponse> copyProgram(@PathVariable Long id, @RequestParam String newName) {
		return ApiResponse.success(programService.copyProgram(id, newName), "Program kopyalandı.", clock.instant());
	}

	@PutMapping("/{id}/goals")
	public ApiResponse<DietProgramResponse> updateProgramGoals(@PathVariable Long id,
			@Valid @RequestBody UpdateNutritionGoalsRequest request) {
		return ApiResponse.success(programService.updateProgramGoals(id, request), "Haftalık hedefler güncellendi.",
				clock.instant());
	}

	@PostMapping("/meals/{mealId}/ingredients/bulk")
	public ApiResponse<DietProgramResponse> addIngredientsBulk(@PathVariable Long mealId,
			@Valid @RequestBody List<BulkIngredientRequest> requests) {
		return ApiResponse.success(ingredientService.addIngredientsBulk(mealId, requests),
				"Besinler toplu olarak eklendi.", clock.instant());
	}

	@PostMapping("/meals/{mealId}/ingredients")
	public ApiResponse<DietProgramResponse> addIngredient(@PathVariable Long mealId,
			@RequestParam(required = false) Long foodId, @RequestParam(required = false) Long recipeId,
			@RequestParam BigDecimal amount, @RequestParam(required = false) String note,
			@RequestParam(defaultValue = "false") boolean ignoreOverride,
			@RequestParam(required = false) Long userRecipeId) {
		DietProgramResponse response = ingredientService.addIngredient(mealId, foodId, amount, note, ignoreOverride,
				recipeId, userRecipeId);
		return ApiResponse.success(response, "Besin/Tarif öğüne eklendi.", clock.instant());
	}

	@DeleteMapping("/meals/{mealId}")
	public ApiResponse<DietProgramResponse> deleteMeal(@PathVariable Long mealId) {
		return ApiResponse.success(ingredientService.deleteMeal(mealId), "Öğün silindi.", clock.instant());
	}

	@PutMapping("/{id}/rename")
	public ApiResponse<DietProgramResponse> renameProgram(@PathVariable Long id, @RequestParam String name) {
		return ApiResponse.success(programService.renameProgram(id, name), "Program adı güncellendi.", clock.instant());
	}

	@DeleteMapping("/meals/ingredients/{ingredientId}")
	public ApiResponse<DietProgramResponse> deleteIngredient(@PathVariable Long ingredientId) {
		DietProgramResponse response = ingredientService.deleteIngredient(ingredientId);
		return ApiResponse.success(response, "Besin öğünden silindi.", clock.instant());
	}

	@PutMapping("/meals/ingredients/{ingredientId}/recipe")
	public ApiResponse<DietProgramResponse> updateRecipeIngredient(@PathVariable Long ingredientId,
			@Valid @RequestBody RecipeRequest updatedRecipe) {
		DietProgramResponse response = ingredientService.updateRecipeIngredient(ingredientId, updatedRecipe);
		return ApiResponse.success(response, "Öğündeki tarif başarıyla güncellendi.", clock.instant());
	}

	@PutMapping("/meals/ingredients/{ingredientId}")
	public ApiResponse<DietProgramResponse> updateIngredientAmount(@PathVariable Long ingredientId,
			@RequestParam BigDecimal amount) {
		DietProgramResponse response = ingredientService.updateIngredientAmount(ingredientId, amount);
		return ApiResponse.success(response, "Besin miktarı güncellendi.", clock.instant());
	}

	@DeleteMapping("/{id}")
	public ApiResponse<Void> deleteProgram(@PathVariable Long id) {
		programService.deleteProgram(id);
		return ApiResponse.success(null, "Diyet programı başarıyla silindi.", clock.instant());
	}

	@PostMapping("/programs/approve-orphan/{id}")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<DietProgramResponse> approveOrphanedDietProgram(@PathVariable Long id,
			@RequestParam(defaultValue = "true") boolean keep) {
		DietProgramResponse response = programService.approveOrphanedDietProgram(id, keep);
		return ApiResponse.success(response, "İşlem tamamlandı.", clock.instant());
	}

	// --- Coach Template Endpoints ---

	@GetMapping("/templates")
	public ApiResponse<List<DietProgramResponse>> getCoachTemplates() {
		return ApiResponse.success(templateService.getCoachTemplates(), "Diyet şablonlarınız getirildi.",
				clock.instant());
	}

	@PostMapping("/templates/create")
	public ApiResponse<DietProgramResponse> createTemplate(@RequestParam String name) {
		return ApiResponse.success(templateService.createTemplate(name), "Diyet şablonu oluşturuldu.", clock.instant());
	}

	@PostMapping("/assign/{templateId}/{clientId}")
	public ApiResponse<DietProgramResponse> assignTemplate(@PathVariable Long templateId, @PathVariable Long clientId) {
		return ApiResponse.success(templateService.assignTemplateToClient(templateId, clientId),
				"Şablon öğrenciye başarıyla atandı.", clock.instant());
	}

	/**
	 * Antrenörün belirli bir diyet şablonunu hangi sporculara atadığını listeler.
	 * @param templateId Diyet şablonu kimliği
	 * @return Atama yapılan sporcuların listesi
	 */
	@GetMapping("/templates/{templateId}/assignments")
	public ApiResponse<List<DietAssignmentResponse>> getTemplateAssignments(@PathVariable Long templateId) {
		return ApiResponse.success(templateService.getTemplateAssignments(templateId),
				"Şablon atamaları başarıyla getirildi.", clock.instant());
	}

	/**
	 * Antrenörün bir sporcuya atadığı diyet şablon kopyasını (atamasını) iptal
	 * eder/siler.
	 * @param templateId Diyet şablonu kimliği
	 * @param clientId Sporcu kimliği
	 * @return Boş başarı dönüşü
	 */
	@DeleteMapping("/templates/{templateId}/unassign/{clientId}")
	public ApiResponse<Void> unassignTemplate(@PathVariable Long templateId, @PathVariable Long clientId) {
		templateService.unassignTemplate(templateId, clientId);
		return ApiResponse.success(null, "Diyet ataması başarıyla kaldırıldı.", clock.instant());
	}

	/**
	 * Antrenörün kendi atadığı tüm diyet şablon atamalarını listeler.
	 * @return Atama yapılan tüm diyet programlarının ve sporcuların listesi
	 */
	@GetMapping("/assignments")
	public ApiResponse<List<DietAssignmentResponse>> getCoachAssignments() {
		return ApiResponse.success(templateService.getCoachAssignments(), "Tüm diyet atamaları başarıyla getirildi.",
				clock.instant());
	}

	/**
	 * Antrenörün yetkili olduğu sporcunun (öğrencinin) aktif diyet programı atamasını
	 * getirir.
	 * @param clientId Bilgisi istenecek sporcunun ID'si
	 * @return DietAssignmentResponse Diyet programı atama bilgisi
	 */
	@GetMapping("/assignments/{clientId}")
	public ApiResponse<DietAssignmentResponse> getClientAssignmentForCoach(@PathVariable Long clientId) {
		return ApiResponse.success(templateService.getClientAssignmentForCoach(clientId),
				"Sporcunun aktif diyet programı ataması başarıyla getirildi.", clock.instant());
	}

}
