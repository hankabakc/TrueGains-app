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
import java.util.List;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import static org.assertj.core.api.Assertions.assertThat;

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
				true, false, false);
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

}
