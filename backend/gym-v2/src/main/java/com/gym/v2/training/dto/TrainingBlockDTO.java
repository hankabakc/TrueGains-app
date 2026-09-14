package com.gym.v2.training.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.List;

/**
 * GYMAPP-V2 Antrenman Bloğu Record DTO: Programın genel bilgilerini ve günlerini taşır.
 * <p>
 * Doğrulama anotasyonları yalnızca istek (request) yönünde çalışır; yanıt üretilirken
 * denetlenmez. Daha önce bu DTO'da hiç doğrulama yoktu ve {@code startDate} boş
 * geldiğinde {@code TrainingBlockService.createPersonalProgram} içindeki
 * {@code request.startDate().plusWeeks(...)} çağrısı NPE ile 500 üretiyordu.
 * </p>
 */
public record TrainingBlockDTO(@JsonProperty("id") Long id,

		@JsonProperty("name") @NotBlank(message = "Program adı zorunludur.") @Size(max = 150,
				message = "Program adı en fazla 150 karakter olabilir.") String name,

		@JsonProperty("description") @Size(max = 1000,
				message = "Açıklama en fazla 1000 karakter olabilir.") String description,

		@JsonProperty("coach_id") Long coachId, @JsonProperty("coach_name") String coachName,
		@JsonProperty("client_id") Long clientId, @JsonProperty("client_name") String clientName,

		@JsonProperty("start_date") @NotNull(message = "Başlangıç tarihi zorunludur.") LocalDate startDate,

		@JsonProperty("end_date") LocalDate endDate, @JsonProperty("is_active") Boolean isActive,

		@JsonProperty("duration_weeks") @Min(value = 1, message = "Program süresi en az 1 hafta olmalıdır.") @Max(
				value = 104, message = "Program süresi en fazla 104 hafta olabilir.") Integer durationWeeks,

		@JsonProperty("workout_days") @Valid @Size(max = 31,
				message = "Bir programda en fazla 31 gün olabilir.") List<WorkoutDayDTO> workoutDays,

		@JsonProperty("is_personal") Boolean isPersonal, @JsonProperty("is_template") Boolean isTemplate,
		@JsonProperty("is_orphaned") Boolean isOrphaned) {
}
