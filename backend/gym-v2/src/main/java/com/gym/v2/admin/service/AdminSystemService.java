package com.gym.v2.admin.service;

import com.gym.v2.admin.dto.AdminSystemDto;
import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import io.micrometer.core.instrument.search.Search;
import java.util.concurrent.TimeUnit;
import org.springframework.stereotype.Service;

/**
 * Sunucunun calisma durumunu Micrometer kayit defterinden okur.
 * <p>
 * Ayni sayilari Prometheus da topluyor; buradan okumanin sebebi panelin izleme yiginina
 * bagimli olmamasi. Prometheus dususe gecerse panel yine calisir.
 * </p>
 */
@Service
public class AdminSystemService {

	private static final String HTTP_TIMER = "http.server.requests";

	private final MeterRegistry registry;

	public AdminSystemService(MeterRegistry registry) {
		this.registry = registry;
	}

	public AdminSystemDto getSystemStatus() {
		long requests = 0;
		double totalMs = 0;
		double maxMs = 0;

		for (Timer timer : Search.in(registry).name(HTTP_TIMER).timers()) {
			requests += timer.count();
			totalMs += timer.totalTime(TimeUnit.MILLISECONDS);
			maxMs = Math.max(maxMs, timer.max(TimeUnit.MILLISECONDS));
		}

		return new AdminSystemDto(gauge("process.uptime"), asPercent(gauge("process.cpu.usage")),
				asPercent(gauge("system.cpu.usage")), (long) heap("jvm.memory.used"), (long) heap("jvm.memory.max"),
				(int) gauge("hikaricp.connections.active"), (int) gauge("hikaricp.connections.idle"),
				(int) gauge("hikaricp.connections.max"), (int) gauge("hikaricp.connections.pending"), requests,
				requestsByOutcome("SERVER_ERROR"), requestsByOutcome("CLIENT_ERROR"),
				requests == 0 ? 0 : totalMs / requests, maxMs);
	}

	/**
	 * Ayni isimde birden fazla olcum olabilir (etiketli). Hepsi toplanir; olcum hic yoksa
	 * 0 doner - eksik metrik yuzunden panel patlamamali.
	 */
	private double gauge(String name) {
		double sum = 0;
		for (Gauge g : Search.in(registry).name(name).gauges()) {
			double value = g.value();
			if (!Double.isNaN(value)) {
				sum += value;
			}
		}
		return sum;
	}

	/** Yigin (heap) disindaki bellek alanlari haric tutulur. */
	private double heap(String name) {
		double sum = 0;
		for (Gauge g : Search.in(registry).name(name).tag("area", "heap").gauges()) {
			double value = g.value();
			if (!Double.isNaN(value)) {
				sum += value;
			}
		}
		return sum;
	}

	private long requestsByOutcome(String outcome) {
		long total = 0;
		for (Timer timer : Search.in(registry).name(HTTP_TIMER).tag("outcome", outcome).timers()) {
			total += timer.count();
		}
		return total;
	}

	/** Micrometer CPU olcumlerini 0..1 arasinda verir; panelde yuzde gosteriyoruz. */
	private static double asPercent(double ratio) {
		return Math.round(ratio * 1000.0) / 10.0;
	}

}
