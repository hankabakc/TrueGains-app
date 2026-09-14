package com.gym.v2.nutrition;

import com.gym.v2.nutrition.controller.DietEntryController;
import com.gym.v2.nutrition.service.DietEntryService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

public class DietEntryControllerTest {

	private MockMvc mockMvc;

	private DietEntryService dietEntryService;

	@BeforeEach
	void setUp() {
		dietEntryService = mock(DietEntryService.class);
		Clock clock = Clock.fixed(Instant.parse("2026-06-02T12:00:00Z"), ZoneId.of("UTC"));
		DietEntryController controller = new DietEntryController(dietEntryService, clock);
		mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
	}

	@Test
	public void testTogglePlannedMealParameterBinding() throws Exception {
		// 1. Test standard HTTP parameter list format: ingredientIds=1&ingredientIds=2
		mockMvc
			.perform(post("/api/v1/diet/log/toggle-planned").param("date", "2026-06-02")
				.param("mealId", "1")
				.param("consumed", "true")
				.param("ingredientIds", "1", "2"))
			.andExpect(status().isOk());

		ArgumentCaptor<List<Long>> captor1 = ArgumentCaptor.forClass(List.class);
		verify(dietEntryService).togglePlannedMeal(any(), any(), anyBoolean(), captor1.capture());
		List<Long> list1 = captor1.getValue();
		System.out.println(">>> Standalone test [ingredientIds]: " + list1);
		assertNotNull(list1);
		assertEquals(2, list1.size());
		assertTrue(list1.contains(1L));
		assertTrue(list1.contains(2L));

		reset(dietEntryService);

		// 2. Test bracket HTTP parameter list format: ingredientIds[]=1&ingredientIds[]=2
		mockMvc
			.perform(post("/api/v1/diet/log/toggle-planned").param("date", "2026-06-02")
				.param("mealId", "1")
				.param("consumed", "true")
				.param("ingredientIds[]", "1", "2"))
			.andExpect(status().isOk());

		ArgumentCaptor<List<Long>> captor2 = ArgumentCaptor.forClass(List.class);
		verify(dietEntryService).togglePlannedMeal(any(), any(), anyBoolean(), captor2.capture());
		List<Long> list2 = captor2.getValue();
		System.out.println(">>> Standalone test [ingredientIds[]]: " + list2);
		assertNotNull(list2);
		assertEquals(2, list2.size());
		assertTrue(list2.contains(1L));
		assertTrue(list2.contains(2L));
	}

}
