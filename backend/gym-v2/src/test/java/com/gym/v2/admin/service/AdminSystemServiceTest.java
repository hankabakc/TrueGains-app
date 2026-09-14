package com.gym.v2.admin.service;

import com.gym.v2.admin.dto.AdminSystemDto;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Duration;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Sunucu durumu okumasi.
 */
class AdminSystemServiceTest {

	/**
	 * Panel, metrikler henuz olusmamisken de acilabilmeli. Bos kayit defterinde hicbir
	 * olcum yok; uc patlamak yerine sifir dondurmeli.
	 */
	@Test
	void getSystemStatus_emptyRegistry_returnsZerosInsteadOfFailing() {
		AdminSystemDto dto = new AdminSystemService(new SimpleMeterRegistry()).getSystemStatus();

		assertThat(dto.requestsTotal()).isZero();
		assertThat(dto.avgResponseMs()).isZero();
		assertThat(dto.heapUsedBytes()).isZero();
		assertThat(dto.dbActive()).isZero();
	}

	/**
	 * Istekler etikete gore ayrilmali: 4xx ile 5xx ayni kefeye konursa "sunucu saglikli
	 * mi" sorusu cevapsiz kalir.
	 */
	@Test
	void getSystemStatus_separatesServerErrorsFromClientErrors() {
		MeterRegistry registry = new SimpleMeterRegistry();

		Timer ok = registry.timer("http.server.requests", "outcome", "SUCCESS");
		Timer clientError = registry.timer("http.server.requests", "outcome", "CLIENT_ERROR");
		Timer serverError = registry.timer("http.server.requests", "outcome", "SERVER_ERROR");

		ok.record(Duration.ofMillis(100));
		ok.record(Duration.ofMillis(300));
		clientError.record(Duration.ofMillis(20));
		serverError.record(Duration.ofMillis(80));

		AdminSystemDto dto = new AdminSystemService(registry).getSystemStatus();

		assertThat(dto.requestsTotal()).isEqualTo(4);
		assertThat(dto.serverErrorsTotal()).isEqualTo(1);
		assertThat(dto.clientErrorsTotal()).isEqualTo(1);
		assertThat(dto.avgResponseMs()).isEqualTo(125.0);
		assertThat(dto.maxResponseMs()).isEqualTo(300.0);
	}

	/** Yigin disi bellek alanlari toplama girmemeli. */
	@Test
	void getSystemStatus_heapOnly_ignoresNonHeapMemory() {
		MeterRegistry registry = new SimpleMeterRegistry();
		registry.gauge("jvm.memory.used", io.micrometer.core.instrument.Tags.of("area", "heap"),
				new AtomicInteger(500));
		registry.gauge("jvm.memory.used", io.micrometer.core.instrument.Tags.of("area", "nonheap"),
				new AtomicInteger(900));

		AdminSystemDto dto = new AdminSystemService(registry).getSystemStatus();

		assertThat(dto.heapUsedBytes()).isEqualTo(500);
	}

	/** Micrometer CPU'yu 0..1 verir; panelde yuzde bekleniyor. */
	@Test
	void getSystemStatus_convertsCpuRatioToPercent() {
		MeterRegistry registry = new SimpleMeterRegistry();
		registry.gauge("process.cpu.usage", new AtomicInteger(0));
		registry.more().counter("ignored", io.micrometer.core.instrument.Tags.empty(), 1);

		AdminSystemDto dto = new AdminSystemService(registry).getSystemStatus();

		assertThat(dto.processCpuPercent()).isZero();
	}

}
