package com.gym.v2.training.service;

import com.gym.v2.core.config.CentralMapperConfig;
import com.gym.v2.training.dto.*;
import com.gym.v2.training.entity.*;
import org.mapstruct.*;

import java.util.List;

@Mapper(config = CentralMapperConfig.class)
public interface TrainingMapper {

	ExerciseDTO toExerciseDTO(Exercise exercise);

	List<ExerciseDTO> toExerciseDTOList(List<Exercise> exercises);

	@Mapping(target = "exerciseId",
			expression = "java(log.getPerformedExercise() != null ? " + "log.getPerformedExercise().getId() : "
					+ "log.getWorkoutExercise().getExercise().getId())")
	@Mapping(target = "exerciseName", expression = "java(log.getPerformedExercise() != null ? "
			+ "log.getPerformedExercise().getName() : " + "log.getWorkoutExercise().getExercise().getName())")
	WorkoutLogDTO toWorkoutLogDTO(WorkoutLog log);

	List<WorkoutLogDTO> toWorkoutLogDTOList(List<WorkoutLog> logs);

	@Mapping(target = "exerciseId", source = "exercise.id")
	@Mapping(target = "exerciseName", source = "exercise.name")
	@Mapping(target = "muscleGroup", source = "exercise.muscleGroup")
	WorkoutExerciseDTO toWorkoutExerciseDTO(WorkoutExercise workoutExercise);

	List<WorkoutExerciseDTO> toWorkoutExerciseDTOList(List<WorkoutExercise> workoutExercises);

	WorkoutDayDTO toWorkoutDayDTO(WorkoutDay workoutDay);

	List<WorkoutDayDTO> toWorkoutDayDTOList(List<WorkoutDay> workoutDays);

	@Mapping(target = "coachId", source = "coach.id")
	@Mapping(target = "clientId", source = "client.id")
	@Mapping(target = "coachName", ignore = true)
	@Mapping(target = "clientName", ignore = true)
	@Mapping(target = "isPersonal",
			expression = "java(trainingBlock.getCoach() == null && !trainingBlock.getIsTemplate())")
	TrainingBlockDTO toTrainingBlockDTO(TrainingBlock trainingBlock);

	List<TrainingBlockDTO> toTrainingBlockDTOList(List<TrainingBlock> trainingBlocks);

	@Mapping(target = "workoutDayName", source = "workoutDayName")
	WorkoutSessionDTO toWorkoutSessionDTO(WorkoutSession session);

	List<WorkoutSessionDTO> toWorkoutSessionDTOList(List<WorkoutSession> sessions);

}
