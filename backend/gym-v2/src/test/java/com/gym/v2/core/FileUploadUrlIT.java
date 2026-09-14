package com.gym.v2.core;

import com.gym.v2.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.startsWith;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Dosya yükleme ucunun URL dönüş biçimini doğrulayan entegrasyon testi.
 */
class FileUploadUrlIT extends IntegrationTestBase {

	/**
	 * Yüklenen dosyanın adresi sunucu adı taşımamalı. Mutlak adres saklanırsa alan adı
	 * veya IP değiştiği anda o güne kadar yüklenmiş tüm görseller kırılır (bu bir kez
	 * yaşandı).
	 */
	@Test
	void uploadedFileUrl_isRelativePath() throws Exception {
		MockMultipartFile file = new MockMultipartFile("file", "foto.jpg", MediaType.IMAGE_JPEG_VALUE,
				new byte[] { (byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0 });

		mockMvc.perform(multipart("/api/v1/files/upload").file(file))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.url").value(startsWith("/api/v1/files/")))
			.andExpect(jsonPath("$.data.url").value(not(containsString("http"))));
	}

}
