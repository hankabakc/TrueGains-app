package com.gym.v2.finance.controller;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.core.exception.GlobalExceptionHandler;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.service.LogService;
import com.gym.v2.finance.dto.PaymentTransactionDTO;
import com.gym.v2.finance.service.FinanceService;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.MessageSource;
import org.springframework.http.MediaType;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class FinanceControllerTest {

	private MockMvc mockMvc;

	@Mock
	private FinanceService financeService;

	@Mock
	private MessageSource messageSource;

	@Mock
	private LogService logService;

	private Clock fixedClock;

	private AppUser mockUser;

	@BeforeEach
	void setUp() {
		fixedClock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);

		mockUser = AppUser.builder().email("client@test.com").build();
		ReflectionTestUtils.setField(mockUser, "id", 1L);

		GlobalExceptionHandler exceptionHandler = new GlobalExceptionHandler(messageSource, fixedClock, logService);
		FinanceController controller = new FinanceController(financeService, fixedClock);

		mockMvc = MockMvcBuilders.standaloneSetup(controller).setControllerAdvice(exceptionHandler).build();
	}

	@Test
	void addToCart_validPackage_returnsOkWithSuccessResponse() throws Exception {
		PaymentTransactionDTO dto = new PaymentTransactionDTO(100L, 10L, "Standard", 30, new BigDecimal("100.00"),
				"PENDING", Instant.now());

		when(financeService.getCurrentUser()).thenReturn(mockUser);
		when(financeService.addToCart(1L, 10L)).thenReturn(dto);

		mockMvc.perform(post("/api/v1/finance/cart/add/10").contentType(MediaType.APPLICATION_JSON))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.success").value(true))
			.andExpect(jsonPath("$.data.id").value(100));
	}

	@Test
	void addToCart_packageNotFound_returnsNotFound() throws Exception {
		when(financeService.getCurrentUser()).thenReturn(mockUser);
		when(financeService.addToCart(1L, 10L)).thenThrow(new NotFoundException("Paket bulunamadı."));

		mockMvc.perform(post("/api/v1/finance/cart/add/10").contentType(MediaType.APPLICATION_JSON))
			.andExpect(status().isNotFound())
			.andExpect(jsonPath("$.success").value(false))
			.andExpect(jsonPath("$.message").value("Paket bulunamadı."));
	}

	@Test
	void removeFromCart_transactionBelongsToOtherUser_returnsForbidden() throws Exception {
		when(financeService.getCurrentUser()).thenReturn(mockUser);
		doThrow(new SecurityException("Bu işlem size ait değildir.")).when(financeService).removeFromCart(1L, 100L);

		mockMvc.perform(delete("/api/v1/finance/cart/cancel/100").contentType(MediaType.APPLICATION_JSON))
			.andExpect(status().isForbidden())
			.andExpect(jsonPath("$.success").value(false))
			.andExpect(jsonPath("$.message").value("Bu işlem size ait değildir."));
	}

}
