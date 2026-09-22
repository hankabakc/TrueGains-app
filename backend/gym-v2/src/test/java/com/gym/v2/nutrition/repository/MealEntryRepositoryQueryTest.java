package com.gym.v2.nutrition.repository;

import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.springframework.data.jpa.repository.Query;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Günlük toplamlar veritabanında güne göre gruplanır; bu sorguları hiçbir test koşmadığı
 * için metin sabitlenir (KR17, G-85). Davranışın kanıtı PostgreSQL'de:
 * {@code CAST(... AT TIME ZONE 'Europe/Istanbul' AS DATE)}.
 */
class MealEntryRepositoryQueryTest {

	@Test
	void dailyAggregations_groupByTurkishDay() throws NoSuchMethodException {
		for (String method : new String[] { "findDailyNutrientTotals", "findDailyMealBreakdown" }) {
			String sql = MealEntryRepository.class.getMethod(method, Long.class, Instant.class, Instant.class)
				.getAnnotation(Query.class)
				.value();
			assertThat(sql).as(method).contains("AT TIME ZONE 'Europe/Istanbul'").doesNotContain("'UTC'");
		}
	}

}
