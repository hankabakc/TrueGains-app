package com.gym.v2.training.repository;

import com.gym.v2.training.entity.WorkoutDay;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Antrenman günleri veri erişim arayüzü.
 * <p>
 * Antrenman oturumu kaydedilirken gönderilen gün kimliğinin ({@code workoutDayId})
 * doğrudan yazılması IDOR güvenlik açığı oluşturur (K1-07). Bu arayüz, günün sahibinin ve
 * bağlı olduğu programın tek sorguda doğrulanmasını sağlar.
 * </p>
 */
public interface WorkoutDayRepository extends JpaRepository<WorkoutDay, Long> {

	/**
	 * Günün ait olduğu programın sporcu kimliğiyle (clientId) gün kaydını bulur.
	 * @param id Gün ID
	 * @param clientId Sporcu ID
	 * @return Eşleşen WorkoutDay
	 */
	@Query("SELECT d FROM WorkoutDay d WHERE d.id = :id AND d.trainingBlock.client.id = :clientId")
	Optional<WorkoutDay> findByIdAndClientId(@Param("id") Long id, @Param("clientId") Long clientId);

	/**
	 * Günün hem belirtilen programa hem de belirtilen sporcuya ait olduğunu tek sorguda
	 * doğrular.
	 * @param id Gün ID
	 * @param blockId Program ID
	 * @param clientId Sporcu ID
	 * @return Eşleşen WorkoutDay
	 */
	@Query("SELECT d FROM WorkoutDay d WHERE d.id = :id AND d.trainingBlock.id = :blockId AND d.trainingBlock.client.id = :clientId")
	Optional<WorkoutDay> findByIdAndBlockIdAndClientId(@Param("id") Long id, @Param("blockId") Long blockId,
			@Param("clientId") Long clientId);

}
