package com.gym.v2.training.controller;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.service.UserService;
import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.training.dto.ProgramWithAssignmentsRecord;
import com.gym.v2.training.entity.TrainingBlock;
import com.gym.v2.training.service.ProgramAssignmentService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Clock;
import java.util.List;

/**
 * Koçların program atamalarını ve bu atamaların yönetimini sağlayan API Controller.
 */
@RestController
@RequestMapping("/api/v1/coaches/programs")
public class ProgramAssignmentController {

	private final ProgramAssignmentService assignmentService;

	private final UserService userService;

	private final Clock clock;

	/**
	 * Constructor injection. Lombok yasaktır.
	 */
	public ProgramAssignmentController(ProgramAssignmentService assignmentService, UserService userService,
			Clock clock) {
		this.assignmentService = assignmentService;
		this.userService = userService;
		this.clock = clock;
	}

	/**
	 * Koçun aktif olarak öğrenciye atanmış programlarını hiyerarşik olarak getirir.
	 * @return ApiResponse içerisinde ProgramWithAssignmentsRecord listesi
	 */
	@GetMapping("/assigned")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<List<ProgramWithAssignmentsRecord>> getAssignedPrograms() {
		AppUser coach = this.userService.getCurrentUser();
		List<ProgramWithAssignmentsRecord> response = this.assignmentService.getAssignedPrograms(coach.getId());

		return ApiResponse.success(response, "Atanmış programlar ve öğrenci listesi başarıyla getirildi.",
				this.clock.instant());
	}

	/**
	 * Bir sporcuya atanmış olan programı kaldırır.
	 * @param programId Şablon ID
	 * @param studentId Sporcu ID
	 * @return ApiResponse
	 */
	@DeleteMapping("/unassign/{programId}/{studentId}")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<Void> unassignProgramFromStudent(@PathVariable Long programId, @PathVariable Long studentId) {
		AppUser coach = this.userService.getCurrentUser();
		this.assignmentService.unassignProgramFromStudent(coach.getId(), programId, studentId);

		return ApiResponse.success(null, "Program ataması sporcudan başarıyla kaldırıldı.", this.clock.instant());
	}

	/**
	 * GET /api/v1/coaches/programs/assigned/{clientId} Antrenörün yetkili olduğu belirli
	 * bir sporcunun atanmış aktif antrenman bloklarını getirir. IDOR güvenliği: Servis
	 * katmanında koç-sporcu ilişkisi doğrulanır.
	 * @param clientId Sorgulanacak sporcunun ID'si
	 * @return ApiResponse içerisinde TrainingBlock listesi
	 */
	@GetMapping("/assigned/{clientId}")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<List<TrainingBlock>> getAssignedProgramsForClient(@PathVariable Long clientId) {
		AppUser coach = this.userService.getCurrentUser();
		List<TrainingBlock> response = this.assignmentService.getAssignedProgramsForClient(coach.getId(), clientId);

		return ApiResponse.success(response, "Sporcunun atanmış antrenman programları başarıyla getirildi.",
				this.clock.instant());
	}

}
