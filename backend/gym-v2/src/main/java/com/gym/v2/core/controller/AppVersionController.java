package com.gym.v2.core.controller;

import com.gym.v2.core.dto.AppVersionResponse;
import com.gym.v2.core.response.ApiResponse;
import java.time.Clock;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * İstemcinin açılışta "benim sürümüm hâlâ destekleniyor mu" diye sorduğu uç.
 * <p>
 * Sürüm kilidi olmadan mağazadan güncelleme almamış bir kurulum yeni backend'e bağlanıp
 * sessizce kırılıyordu. Bu teorik değil: bu turda kimlik uçlarının sözleşmesi değişti
 * (e-posta ve OTP kodu sorgu dizesinden gövdeye taşındı), yani eski bir kurulum bugün
 * giriş yapamaz ve kullanıcı sebebini anlayamaz.
 * </p>
 * <p>
 * Kimlik doğrulaması istemez: istemci bu bilgiyi giriş yapmadan, açılışta sorar.
 * </p>
 */
@RestController
@RequestMapping("/api/v1/app")
public class AppVersionController {

	/**
	 * Desteklenen en düşük istemci sürümü. API sözleşmesini bozan her dağıtımda
	 * yükseltilir; ortam değişkeniyle (yeniden derleme gerekmeden) da verilebilir.
	 */
	@Value("${app.client.min-supported-version:1.0.0}")
	private String minSupportedVersion;

	/** Mağazadaki güncel sürüm. Zorunlu olmayan "güncelleme var" bildirimi için. */
	@Value("${app.client.latest-version:1.0.0}")
	private String latestVersion;

	private final Clock clock;

	public AppVersionController(Clock clock) {
		this.clock = clock;
	}

	@GetMapping("/version")
	public ApiResponse<AppVersionResponse> getVersionRequirements() {
		return ApiResponse.success(new AppVersionResponse(minSupportedVersion, latestVersion),
				"Sürüm bilgisi getirildi.", clock.instant());
	}

}
