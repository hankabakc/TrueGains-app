package com.gym.v2;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.gym.v2.nutrition.dto.RecipeResponse;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class SerializationTest {

	@Test
	public void testRecipeResponseSerialization() throws Exception {
		ObjectMapper mapper = new ObjectMapper();
		mapper.registerModule(new JavaTimeModule());

		RecipeResponse resp = new RecipeResponse(8L, "Test", "Desc", "Inst", "Cat", "URL", LocalDateTime.now(),
				new ArrayList<>(), BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO);

		String json = mapper.writeValueAsString(resp);
		System.out.println("DEBUG JSON: " + json);
		assertTrue(json.contains("\"name\":\"Test\""));
	}

}
