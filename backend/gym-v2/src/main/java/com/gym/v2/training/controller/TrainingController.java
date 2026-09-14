package com.gym.v2.training.controller;

import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.training.dto.*;
import com.gym.v2.training.service.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;
import jakarta.validation.Valid;
import java.time.Clock;
import java.util.List;

/**
 * GYMAPP-V2 Antrenman Motoru API: Koç ve Sporcu arasındaki antrenman akışını yönetir. SRP
 * prensibi gereği iş mantığı parçalanmış servislere delege edilmiştir.
 */
@RestController
@RequestMapping("/api/v1/training")
public class TrainingController {

	private final TrainingBlockService blockService;

	private final WorkoutSessionService sessionService;

	private final WeeklyProgressService progressService;

	private final ExerciseService exerciseService;

	private final Clock clock;

	public TrainingController(TrainingBlockService blockService, WorkoutSessionService sessionService,
			WeeklyProgressService progressService, ExerciseService exerciseService, Clock clock) {
		this.blockService = blockService;
		this.sessionService = sessionService;
		this.progressService = progressService;
		this.exerciseService = exerciseService;
		this.clock = clock;
	}

	@GetMapping("/exercises")
	@PreAuthorize("hasAnyRole('CLIENT', 'COACH')")
	public ApiResponse<List<ExerciseDTO>> getAllExercises() {
		return ApiResponse.success(exerciseService.getAllExercises(), "Egzersiz kütüphanesi listelendi.",
				clock.instant());
	}

	@GetMapping("/programs")
	@PreAuthorize("hasAnyRole('CLIENT', 'COACH')")
	public ApiResponse<List<TrainingBlockDTO>> getMyActivePrograms() {
		return ApiResponse.success(blockService.getMyActivePrograms(), "Aktif programlarınız listelendi.",
				clock.instant());
	}

	@PostMapping("/programs/personal")
	@PreAuthorize("hasAnyRole('CLIENT', 'COACH')")
	public ApiResponse<TrainingBlockDTO> createPersonalProgram(@Valid @RequestBody TrainingBlockDTO request) {
		return ApiResponse.success(blockService.createPersonalProgram(request),
				"Kişisel program başarıyla oluşturuldu.", clock.instant());
	}

	@PostMapping("/log/{workoutExerciseId}")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<WorkoutLogDTO> logSet(@PathVariable Long workoutExerciseId,
			@Valid @RequestBody WorkoutLogDTO logDto) {
		return ApiResponse.success(sessionService.logSet(workoutExerciseId, logDto), "Set performansı kaydedildi.",
				clock.instant());
	}

	@PutMapping("/programs/personal/{id}")
	@PreAuthorize("hasAnyRole('CLIENT', 'COACH')")
	public ApiResponse<TrainingBlockDTO> updatePersonalProgram(@PathVariable Long id,
			@Valid @RequestBody TrainingBlockDTO request) {
		return ApiResponse.success(blockService.updatePersonalProgram(id, request),
				"Kişisel program başarıyla güncellendi.", clock.instant());
	}

	@DeleteMapping("/programs/personal/{id}")
	@PreAuthorize("hasAnyRole('CLIENT', 'COACH')")
	public ApiResponse<Void> deletePersonalProgram(@PathVariable Long id) {
		blockService.deletePersonalProgram(id);
		return ApiResponse.success(null, "Kişisel program başarıyla silindi.", clock.instant());
	}

	@PostMapping("/sessions")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<WorkoutSessionDTO> logWorkoutSession(@Valid @RequestBody WorkoutSessionRequestDTO request) {
		return ApiResponse.success(sessionService.logWorkoutSession(request), "İdman oturumu başarıyla kaydedildi.",
				clock.instant());
	}

	@DeleteMapping("/sessions/{id}")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<Void> deleteWorkoutSession(@PathVariable Long id) {
		sessionService.deleteWorkoutSession(id);
		return ApiResponse.success(null, "İdman kaydı silindi.", clock.instant());
	}

	@GetMapping("/sessions/history")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<List<WorkoutSessionDTO>> getWorkoutHistory() {
		return ApiResponse.success(sessionService.getWorkoutHistory(), "İdman geçmişi listelendi.", clock.instant());
	}

	@GetMapping("/sessions/history/{clientId}")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<List<WorkoutSessionDTO>> getClientWorkoutHistory(@PathVariable Long clientId) {
		return ApiResponse.success(sessionService.getClientWorkoutHistory(clientId), "Sporcu idman geçmişi listelendi.",
				clock.instant());
	}

	@GetMapping("/templates")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<List<TrainingBlockDTO>> getCoachTemplates() {
		return ApiResponse.success(blockService.getCoachTemplates(), "Hazırladığınız şablonlar listelendi.",
				clock.instant());
	}

	@GetMapping("/assigned")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<List<TrainingBlockDTO>> getCoachAssignedPrograms() {
		return ApiResponse.success(blockService.getCoachAssignedPrograms(),
				"Öğrencilerinize atadığınız aktif programlar listelendi.", clock.instant());
	}

	@PostMapping("/templates")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<TrainingBlockDTO> createCoachTemplate(@Valid @RequestBody TrainingBlockDTO request) {
		return ApiResponse.success(blockService.createCoachTemplate(request),
				"Antrenman şablonu başarıyla oluşturuldu.", clock.instant());
	}

	@PutMapping("/templates/{id}")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<TrainingBlockDTO> updateCoachTemplate(@PathVariable Long id,
			@Valid @RequestBody TrainingBlockDTO request) {
		return ApiResponse.success(blockService.updateCoachTemplate(id, request),
				"Antrenman şablonu başarıyla güncellendi.", clock.instant());
	}

	@DeleteMapping("/templates/{id}")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<Void> deleteCoachTemplate(@PathVariable Long id) {
		blockService.deleteCoachTemplate(id);
		return ApiResponse.success(null, "Antrenman şablonu başarıyla silindi.", clock.instant());
	}

	@PostMapping("/assign/{templateId}/{clientId}")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<TrainingBlockDTO> assignTemplateToClient(@PathVariable Long templateId,
			@PathVariable Long clientId) {
		return ApiResponse.success(blockService.assignTemplateToClient(templateId, clientId),
				"Program sporcuya başarıyla atandı.", clock.instant());
	}

	@PostMapping("/activate/{id}")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<Void> activateProgram(@PathVariable Long id) {
		blockService.activateProgram(id);
		return ApiResponse.success(null, "Program başarıyla aktif edildi.", clock.instant());
	}

	@GetMapping("/progress/me")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<WeeklyProgressDTO> getMyWeeklyProgress() {
		return ApiResponse.success(progressService.getWeeklyProgressForCurrentUser(),
				"Haftalık antrenman ilerlemeniz getirildi.", clock.instant());
	}

	@GetMapping("/progress/{clientId}")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<WeeklyProgressDTO> getClientWeeklyProgress(@PathVariable Long clientId) {
		return ApiResponse.success(progressService.getWeeklyProgressForCoach(clientId),
				"Sporcunun haftalık antrenman ilerlemesi getirildi.", clock.instant());
	}

	@GetMapping("/progress/weekly-history")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<List<WeeklyHistoryItemDTO>> getMyWeeklyHistory() {
		return ApiResponse.success(progressService.getWeeklyHistoryForCurrentUser(),
				"Haftalık antrenman geçmişi ilerlemeniz getirildi.", clock.instant());
	}

	@GetMapping("/progress/weekly-history/{clientId}")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<List<WeeklyHistoryItemDTO>> getClientWeeklyHistory(@PathVariable Long clientId) {
		return ApiResponse.success(progressService.getWeeklyHistoryForCoach(clientId),
				"Sporcunun haftalık antrenman geçmişi ilerlemesi getirildi.", clock.instant());
	}

	@GetMapping("/progress/exercise/{exerciseId}")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<List<ExerciseProgressRecord>> getExerciseProgress(@PathVariable Long exerciseId) {
		return ApiResponse.success(progressService.getExerciseProgress(exerciseId),
				"Egzersiz gelişim verileri getirildi.", clock.instant());
	}

	@GetMapping("/progress/exercise/{clientId}/{exerciseId}")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<List<ExerciseProgressRecord>> getClientExerciseProgress(@PathVariable Long clientId,
			@PathVariable Long exerciseId) {
		return ApiResponse.success(progressService.getExerciseProgressForCoach(clientId, exerciseId),
				"Sporcunun egzersiz gelişim verileri getirildi.", clock.instant());
	}

	@PostMapping("/programs/approve-orphan/{id}")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<TrainingBlockDTO> approveOrphanedProgram(@PathVariable Long id,
			@RequestParam("keep") boolean keep) {
		TrainingBlockDTO response = blockService.approveOrphanedProgram(id, keep);
		String message = keep ? "Program başarıyla kişisel programlarınıza taşındı." : "Program başarıyla silindi.";
		return ApiResponse.success(response, message, clock.instant());
	}

}
