package com.gym.v2.core.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * İstemci sürüm gereksinimleri.
 *
 * @param minSupportedVersion bu sürümün altındaki kurulumlar zorunlu güncelleme ekranı
 * göstermeli; API sözleşmesi onlar için geçerli değil
 * @param latestVersion mağazadaki güncel sürüm; yalnızca bilgilendirme
 */
public record AppVersionResponse(@JsonProperty("min_supported_version") String minSupportedVersion,
		@JsonProperty("latest_version") String latestVersion) {
}
