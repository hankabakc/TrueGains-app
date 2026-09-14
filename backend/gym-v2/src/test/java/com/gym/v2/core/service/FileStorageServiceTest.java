package com.gym.v2.core.service;

import com.gym.v2.core.exception.BadRequestException;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockMultipartFile;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * {@code FileStorageService} yükleme kuralları.
 * <p>
 * Yükleme ucu kayıt akışı gereği kimlik doğrulaması istemez (koç kaydı profil fotoğrafını
 * hesap açılmadan önce yükler). Kimliksiz bir uca dosya yazılabildiği için içerik
 * denetimi tek savunma hattıdır: uzantı adına bakmak yetmez, dosyanın gerçekten iddia
 * ettiği tür olması gerekir.
 * </p>
 */
class FileStorageServiceTest {

	@TempDir
	Path uploadDir;

	private FileStorageService service;

	private static final byte[] JPEG_HEADER = { (byte) 0xFF, (byte) 0xD8, (byte) 0xFF };

	private static final byte[] PNG_HEADER = { (byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A };

	@BeforeEach
	void setUp() {
		service = new FileStorageService(uploadDir.toString(), 5242880L);
	}

	private MockMultipartFile file(String name, byte[] header, int padding) {
		byte[] content = new byte[header.length + padding];
		System.arraycopy(header, 0, content, 0, header.length);
		return new MockMultipartFile("file", name, null, content);
	}

	@Test
	void storeFile_realJpeg_isStored() {
		String stored = service.storeFile(file("foto.jpg", JPEG_HEADER, 100));

		assertThat(uploadDir.resolve(stored)).exists();
		// Özgün ad korunmaz; çakışma ve yol manipülasyonu engellenir.
		assertThat(stored).endsWith(".jpg").doesNotContain("foto");
	}

	@Test
	void storeFile_realPng_isStored() {
		String stored = service.storeFile(file("foto.png", PNG_HEADER, 100));

		assertThat(uploadDir.resolve(stored)).exists();
	}

	@Test
	void storeFile_htmlDisguisedAsJpeg_isRejectedAndWritesNothing() throws IOException {
		MockMultipartFile disguised = new MockMultipartFile("file", "zararli.jpg", "image/jpeg",
				"<html><script>alert(1)</script></html>".getBytes(StandardCharsets.UTF_8));

		assertThatThrownBy(() -> service.storeFile(disguised)).isInstanceOf(BadRequestException.class);

		assertThat(Files.list(uploadDir)).isEmpty();
	}

	@Test
	void storeFile_executableDisguisedAsPdf_isRejected() {
		// "MZ" — Windows çalıştırılabilir dosya imzası.
		MockMultipartFile disguised = new MockMultipartFile("file", "belge.pdf", "application/pdf",
				new byte[] { 0x4D, 0x5A, (byte) 0x90, 0x00 });

		assertThatThrownBy(() -> service.storeFile(disguised)).isInstanceOf(BadRequestException.class);
	}

	@Test
	void storeFile_fileShorterThanItsMagicNumber_isRejected() {
		MockMultipartFile truncated = new MockMultipartFile("file", "foto.png", null, new byte[] { (byte) 0x89, 0x50 });

		assertThatThrownBy(() -> service.storeFile(truncated)).isInstanceOf(BadRequestException.class);
	}

	@Test
	void storeFile_disallowedExtension_isRejected() {
		MockMultipartFile script = new MockMultipartFile("file", "script.sh", null,
				"#!/bin/sh".getBytes(StandardCharsets.UTF_8));

		assertThatThrownBy(() -> service.storeFile(script)).isInstanceOf(BadRequestException.class);
	}

	@Test
	void storeFile_oversizedFile_isRejected() {
		service = new FileStorageService(uploadDir.toString(), 64L);

		assertThatThrownBy(() -> service.storeFile(file("foto.jpg", JPEG_HEADER, 200)))
			.isInstanceOf(BadRequestException.class);
	}

	@Test
	void storeFile_emptyFile_isRejected() {
		MockMultipartFile empty = new MockMultipartFile("file", "foto.jpg", null, new byte[0]);

		assertThatThrownBy(() -> service.storeFile(empty)).isInstanceOf(BadRequestException.class);
	}

}
