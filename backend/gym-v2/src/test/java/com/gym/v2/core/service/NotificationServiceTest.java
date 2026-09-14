package com.gym.v2.core.service;

import com.gym.v2.auth.entity.UserDeviceToken;
import com.gym.v2.auth.repository.UserDeviceTokenRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

/**
 * Bildirim gönderimi, çağıranın işlemini asla geri aldırmamalıdır.
 * <p>
 * {@code sendPushNotification} çağıranın {@code @Transactional} gövdesinden çalışır
 * ({@code ChatService.sendMessage}, {@code TrainingBlockService.assignTemplateToClient}).
 * Buradan kaçan her istisna asıl işlemi geri alır — yani gönderilen mesaj hiç
 * kaydedilmez. Bildirim mesajın <b>yan etkisidir</b>, ön koşulu değil.
 * </p>
 * <p>
 * Test veritabanı yerine sahte depo kullanır: amaç Firebase'in davranışını değil,
 * servisin <b>hiçbir istisnayı dışarı sızdırmadığını</b> doğrulamaktır.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class NotificationServiceTest {

	@Mock
	private UserDeviceTokenRepository deviceTokenRepository;

	@Test
	void repositoryFailure_isSwallowedSoTheCallersTransactionSurvives() {
		NotificationService service = new NotificationService(deviceTokenRepository);
		when(deviceTokenRepository.findAllByUserId(any())).thenThrow(new IllegalStateException("veritabanı hatası"));

		assertThatCode(() -> service.sendPushNotification(1L, "Baslik", "Icerik"))
			.as("bildirim yolundan kaçan istisna çağıranın işlemini geri alır ve mesaj kaybolur")
			.doesNotThrowAnyException();
	}

	@Test
	void recipientWithNoRegisteredDevice_isSwallowed() {
		NotificationService service = new NotificationService(deviceTokenRepository);
		when(deviceTokenRepository.findAllByUserId(any())).thenReturn(java.util.List.<UserDeviceToken>of());

		assertThatCode(() -> service.sendPushNotification(999L, "Baslik", "Icerik"))
			.as("kayıtlı cihazı olmayan kullanıcıya bildirim denemesi göndericinin mesajını yok etmemeli")
			.doesNotThrowAnyException();
	}

}
