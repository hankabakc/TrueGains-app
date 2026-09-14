package com.gym.v2;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.gym.v2.training.dto.WorkoutExerciseDTO;
import com.gym.v2.training.entity.MuscleGroup;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.util.ArrayList;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class TrainingSerializationTest {

	@Test
	public void testWorkoutExerciseDTOSerialization() throws Exception {
		ObjectMapper mapper = new ObjectMapper();
		mapper.registerModule(new JavaTimeModule());

		WorkoutExerciseDTO dto = new WorkoutExerciseDTO(1L, 10L, "Bench Press", MuscleGroup.CHEST, 4, "10-12",
				new BigDecimal("60.0"), 60, "A1", 0, "Focus on form", false, new ArrayList<>());

		String json = mapper.writeValueAsString(dto);
		System.out.println("DEBUG JSON: " + json);

		// Master Strategy gereği snake_case kontrolü
		assertTrue(json.contains("\"exercise_id\":10"), "exercise_id snake_case olmalı");
		assertTrue(json.contains("\"target_sets\":4"), "target_sets snake_case olmalı");
		assertTrue(json.contains("\"target_reps\":\"10-12\""), "target_reps snake_case olmalı");
		assertTrue(json.contains("\"rest_time_seconds\":60"), "rest_time_seconds snake_case olmalı");
		assertTrue(json.contains("\"coach_notes\":\"Focus on form\""), "coach_notes snake_case olmalı");
	}

}
