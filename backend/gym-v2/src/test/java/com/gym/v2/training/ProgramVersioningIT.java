package com.gym.v2.training;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.support.IntegrationTestBase;
import com.gym.v2.training.dto.TrainingBlockDTO;
import com.gym.v2.training.entity.TrainingBlock;
import com.gym.v2.training.repository.TrainingBlockRepository;
import com.gym.v2.training.service.TrainingBlockService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * {@code TrainingBlock.version} alanının iyimser kilit olarak doğru çalıştığını doğrular.
 * <p>
 * Bu alan {@code @Version} ile işaretlidir; sürümü <b>Hibernate</b> yönetir. Servis kodu
 * daha önce her güncellemede ayrıca {@code block.setVersion(getVersion() + 1)} yazıyordu.
 * <p>
 * Ölçüldü (14.08.2026): elle yazılan değeri Hibernate kendi artırımıyla eziyor, yani o
 * satır <b>davranışı değiştirmiyordu</b> — yanıltıcı ölü koddu ve kaldırıldı. Bu test
 * asıl değerini başka yerden alıyor: iki koçun aynı programı aynı anda düzenlemesinde
 * veri kaybını önleyen iyimser kilidin gerçekten işlediğini doğruluyor. Sürüm artmayı
 * bırakırsa kilit sessizce devre dışı kalmış demektir.
 * </p>
 */
class ProgramVersioningIT extends IntegrationTestBase {

	@Autowired
	private TrainingBlockService trainingBlockService;

	@Autowired
	private TrainingBlockRepository blockRepository;

	@PersistenceContext
	private EntityManager entityManager;

	@AfterEach
	void clearSecurityContext() {
		SecurityContextHolder.clearContext();
	}

	private TrainingBlockDTO renameRequest(TrainingBlock block, String newName) {
		return new TrainingBlockDTO(block.getId(), newName, block.getDescription(), null, null, null, null,
				block.getStartDate(), block.getEndDate(), block.getIsActive(), block.getDurationWeeks(), List.of(),
				true, false, false, null, null, null);
	}

	@Test
	void eachUpdateAdvancesTheVersionByExactlyOne() {
		AppUser client = createUser("ver_client@test.com", UserRole.CLIENT);
		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(client.getEmail(), null, List.of()));

		TrainingBlock block = new TrainingBlock("Ilk Ad", "Aciklama", null, client, LocalDate.of(2026, 1, 1),
				LocalDate.of(2026, 2, 1));
		TrainingBlock saved = blockRepository.saveAndFlush(block);
		entityManager.clear();

		long versionBefore = blockRepository.findById(saved.getId()).orElseThrow().getVersion();
		entityManager.clear();

		TrainingBlock fresh = blockRepository.findById(saved.getId()).orElseThrow();
		trainingBlockService.updatePersonalProgram(fresh.getId(), renameRequest(fresh, "Ikinci Ad"));
		entityManager.flush();
		entityManager.clear();

		long versionAfter = blockRepository.findById(saved.getId()).orElseThrow().getVersion();

		assertThat(versionAfter)
			.as("sürüm her güncellemede tam olarak 1 artmalı; iyimser kilidin çalıştığının kanıtı budur")
			.isEqualTo(versionBefore + 1);
		assertThat(blockRepository.findById(saved.getId()).orElseThrow().getName()).as("güncelleme yine de uygulanmalı")
			.isEqualTo("Ikinci Ad");
	}

	private String updateJson(String name, Long version) throws Exception {
		return updateJson(name, version, null);
	}

	private String updateJson(String name, Long version, String editId) throws Exception {
		Map<String, Object> body = new HashMap<>(
				Map.of("name", name, "start_date", "2026-01-01", "duration_weeks", 4, "workout_days", List.of()));
		body.put("version", version);
		if (editId != null) {
			body.put("edit_id", editId);
		}
		return objectMapper.writeValueAsString(body);
	}

	/**
	 * KR13 (G-74): iki cihaz aynı programı düzenler. Önce yazan kazanır; eski sürümle
	 * gelen ikinci düzenleme 409 alır ve sunucudaki hâli bozmaz. Çevrimdışı kuyruk 409'u
	 * kalıcı ret sayıp kaydı "aktarılamadı" listesinde tutar.
	 */
	@Test
	void update_withStaleVersion_isConflictAndProgramUnchanged() throws Exception {
		AppUser client = createUser("ver_stale@test.com", UserRole.CLIENT);
		TrainingBlock saved = blockRepository.saveAndFlush(new TrainingBlock("Ilk Ad", "Aciklama", null, client,
				LocalDate.of(2026, 1, 1), LocalDate.of(2026, 2, 1)));
		long startVersion = saved.getVersion();
		entityManager.clear();

		mockMvc
			.perform(put("/api/v1/training/programs/personal/" + saved.getId())
				.header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(updateJson("Birinci Cihaz", startVersion)))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.version").value(startVersion + 1));
		entityManager.flush();
		entityManager.clear();

		mockMvc
			.perform(put("/api/v1/training/programs/personal/" + saved.getId())
				.header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(updateJson("Ikinci Cihaz", startVersion)))
			.andExpect(status().isConflict());
		entityManager.flush();
		entityManager.clear();

		TrainingBlock after = blockRepository.findById(saved.getId()).orElseThrow();
		assertThat(after.getName()).isEqualTo("Birinci Cihaz");
		assertThat(after.getVersion()).isEqualTo(startVersion + 1);
	}

	@Test
	void update_resentWithSameEditId_returnsAppliedProgramWithoutConflict() throws Exception {
		AppUser client = createUser("ver_retry_id@test.com", UserRole.CLIENT);
		TrainingBlock saved = blockRepository.saveAndFlush(new TrainingBlock("Ilk Ad", "Aciklama", null, client,
				LocalDate.of(2026, 1, 1), LocalDate.of(2026, 2, 1)));
		long startVersion = saved.getVersion();
		entityManager.clear();

		mockMvc
			.perform(put("/api/v1/training/programs/personal/" + saved.getId())
				.header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(updateJson("Birinci", startVersion, "duzenleme-1")))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.name").value("Birinci"))
			.andExpect(jsonPath("$.data.version").value(startVersion + 1));
		entityManager.flush();
		entityManager.clear();

		mockMvc
			.perform(put("/api/v1/training/programs/personal/" + saved.getId())
				.header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(updateJson("Birinci", startVersion, "duzenleme-1")))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.name").value("Birinci"))
			.andExpect(jsonPath("$.data.version").value(startVersion + 1));
		entityManager.flush();
		entityManager.clear();

		TrainingBlock after = blockRepository.findById(saved.getId()).orElseThrow();
		assertThat(after.getName()).isEqualTo("Birinci");
		assertThat(after.getVersion()).isEqualTo(startVersion + 1);
	}

	@Test
	void update_fromOtherDeviceWithSameContent_isConflict() throws Exception {
		AppUser client = createUser("ver_other_dev@test.com", UserRole.CLIENT);
		TrainingBlock saved = blockRepository.saveAndFlush(new TrainingBlock("Ilk Ad", "Aciklama", null, client,
				LocalDate.of(2026, 1, 1), LocalDate.of(2026, 2, 1)));
		long startVersion = saved.getVersion();
		entityManager.clear();

		mockMvc
			.perform(put("/api/v1/training/programs/personal/" + saved.getId())
				.header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(updateJson("Birinci", startVersion, "duzenleme-1")))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.name").value("Birinci"))
			.andExpect(jsonPath("$.data.version").value(startVersion + 1));
		entityManager.flush();
		entityManager.clear();

		mockMvc
			.perform(put("/api/v1/training/programs/personal/" + saved.getId())
				.header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(updateJson("Birinci", startVersion, "duzenleme-2")))
			.andExpect(status().isConflict());
		entityManager.flush();
		entityManager.clear();

		TrainingBlock after = blockRepository.findById(saved.getId()).orElseThrow();
		assertThat(after.getVersion()).isEqualTo(startVersion + 1);
	}

	@Test
	void update_ofAnotherClientsProgram_withItsLastEditId_isRejected() throws Exception {
		AppUser client = createUser("ver_owner@test.com", UserRole.CLIENT);
		AppUser other = createUser("ver_intruder@test.com", UserRole.CLIENT);
		TrainingBlock saved = blockRepository.saveAndFlush(new TrainingBlock("Ilk Ad", "Aciklama", null, client,
				LocalDate.of(2026, 1, 1), LocalDate.of(2026, 2, 1)));
		long startVersion = saved.getVersion();
		entityManager.clear();

		mockMvc
			.perform(put("/api/v1/training/programs/personal/" + saved.getId())
				.header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(updateJson("Birinci", startVersion, "duzenleme-1")))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.name").value("Birinci"))
			.andExpect(jsonPath("$.data.version").value(startVersion + 1));
		entityManager.flush();
		entityManager.clear();

		mockMvc
			.perform(put("/api/v1/training/programs/personal/" + saved.getId())
				.header("Authorization", bearerTokenFor(other))
				.contentType(MediaType.APPLICATION_JSON)
				.content(updateJson("Birinci", startVersion, "duzenleme-1")))
			.andExpect(status().isBadRequest())
			.andExpect(jsonPath("$.data.name").doesNotExist());
		entityManager.flush();
		entityManager.clear();

		TrainingBlock after = blockRepository.findById(saved.getId()).orElseThrow();
		assertThat(after.getName()).isEqualTo("Birinci");
	}

}
