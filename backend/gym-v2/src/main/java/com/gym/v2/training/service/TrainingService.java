package com.gym.v2.training.service;

import com.gym.v2.training.dto.*;
import org.springframework.stereotype.Service;
import java.util.List;

/**
 * Antrenman modülü için Facade servis. SRP prensibi gereği iş mantığı alt servislere
 * (TrainingBlockService, WorkoutSessionService, WeeklyProgressService, ExerciseService)
 * parçalanmıştır. Bu sınıf geriye dönük uyumluluk ve merkezi erişim için Facade görevi
 * görür.
 */
@Service
public class TrainingService {

	private final TrainingBlockService blockService;

	private final WorkoutSessionService sessionService;

	private final WeeklyProgressService progressService;

	private final ExerciseService exerciseService;

	public TrainingService(TrainingBlockService blockService, WorkoutSessionService sessionService,
			WeeklyProgressService progressService, ExerciseService exerciseService) {
		this.blockService = blockService;
		this.sessionService = sessionService;
		this.progressService = progressService;
		this.exerciseService = exerciseService;
	}

	public List<ExerciseDTO> getAllExercises() {
		return exerciseService.getAllExercises();
	}

	public TrainingBlockDTO createPersonalProgram(TrainingBlockDTO request) {
		return blockService.createPersonalProgram(request);
	}

	public TrainingBlockDTO updatePersonalProgram(Long id, TrainingBlockDTO request) {
		return blockService.updatePersonalProgram(id, request);
	}

	public void deletePersonalProgram(Long id) {
		blockService.deletePersonalProgram(id);
	}

	public List<TrainingBlockDTO> getMyActivePrograms() {
		return blockService.getMyActivePrograms();
	}

	public WorkoutLogDTO logSet(Long workoutExerciseId, WorkoutLogDTO request) {
		return sessionService.logSet(workoutExerciseId, request);
	}

	public WorkoutSessionDTO logWorkoutSession(WorkoutSessionRequestDTO request) {
		return sessionService.logWorkoutSession(request);
	}

	public void deleteWorkoutSession(Long sessionId) {
		sessionService.deleteWorkoutSession(sessionId);
	}

	public List<WorkoutSessionDTO> getWorkoutHistory() {
		return sessionService.getWorkoutHistory();
	}

	public List<WorkoutSessionDTO> getClientWorkoutHistory(Long clientId) {
		return sessionService.getClientWorkoutHistory(clientId);
	}

	public List<TrainingBlockDTO> getCoachTemplates() {
		return blockService.getCoachTemplates();
	}

	public List<TrainingBlockDTO> getCoachAssignedPrograms() {
		return blockService.getCoachAssignedPrograms();
	}

	public TrainingBlockDTO createCoachTemplate(TrainingBlockDTO request) {
		return blockService.createCoachTemplate(request);
	}

	public TrainingBlockDTO updateCoachTemplate(Long id, TrainingBlockDTO request) {
		return blockService.updateCoachTemplate(id, request);
	}

	public void deleteCoachTemplate(Long id) {
		blockService.deleteCoachTemplate(id);
	}

	public TrainingBlockDTO assignTemplateToClient(Long templateId, Long clientId) {
		return blockService.assignTemplateToClient(templateId, clientId);
	}

	public void activateProgram(Long id) {
		blockService.activateProgram(id);
	}

	public WeeklyProgressDTO getWeeklyProgressForCurrentUser() {
		return progressService.getWeeklyProgressForCurrentUser();
	}

	public WeeklyProgressDTO getWeeklyProgressForCoach(Long clientId) {
		return progressService.getWeeklyProgressForCoach(clientId);
	}

	public List<ExerciseProgressRecord> getExerciseProgress(Long exerciseId) {
		return progressService.getExerciseProgress(exerciseId);
	}

	public TrainingBlockDTO approveOrphanedProgram(Long id, boolean keep) {
		return blockService.approveOrphanedProgram(id, keep);
	}

}
