package com.gym.v2.nutrition.service;

import com.gym.v2.nutrition.entity.UserFoodOverride;
import com.gym.v2.nutrition.repository.UserFoodOverrideRepository;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

/**
 * G-94: bir yanıt ya da istek boyunca kullanıcının besin ezmeleri. İlk erişimde
 * kullanıcının bütün ezmeleri tek sorguyla yüklenir; sonraki her besin aynı haritadan
 * okunur. Eşleyicide MapStruct {@code @Context} ile taşınır.
 */
public final class UserOverrides {

	private final Long userId;

	private Map<Long, UserFoodOverride> byFoodId;

	public UserOverrides(Long userId) {
		this.userId = userId;
	}

	public Long userId() {
		return userId;
	}

	// ponytail: kullanıcının tüm ezmeleri yüklenir; bir kullanıcıda binlerce ezme olursa
	// findByUserIdAndFoodIdIn'e geçilir.
	Optional<UserFoodOverride> find(Long foodId, UserFoodOverrideRepository repository) {
		if (userId == null || foodId == null) {
			return Optional.empty();
		}
		if (byFoodId == null) {
			byFoodId = new HashMap<>();
			for (UserFoodOverride override : repository.findAllByUserId(userId)) {
				byFoodId.put(override.getFood().getId(), override);
			}
		}
		return Optional.ofNullable(byFoodId.get(foodId));
	}

}
