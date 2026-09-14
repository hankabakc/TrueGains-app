package com.gym.v2.core.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.MessagingErrorCode;
import com.google.firebase.messaging.Notification;
import com.gym.v2.auth.entity.UserDeviceToken;
import com.gym.v2.auth.repository.UserDeviceTokenRepository;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Firebase Cloud Messaging (FCM) üzerinden push bildirim gönderimini yöneten servis.
 */
@Service
public class NotificationService {

	private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

	private final UserDeviceTokenRepository deviceTokenRepository;

	public NotificationService(UserDeviceTokenRepository deviceTokenRepository) {
		this.deviceTokenRepository = deviceTokenRepository;
	}

	/**
	 * Belirtilen kullanıcıya push bildirim gönderir.
	 * @param targetUserId Hedef kullanıcının ID'si.
	 * @param title Bildirim başlığı.
	 * @param body Bildirim içeriği.
	 */
	public void sendPushNotification(Long targetUserId, String title, String body) {
		try {
			List<UserDeviceToken> devices = deviceTokenRepository.findAllByUserId(targetUserId);
			if (devices.isEmpty()) {
				log.debug("Kullanıcının kayıtlı cihazı yok, bildirim atlanıyor. UserID: {}", targetUserId);
				return;
			}

			Notification notification = Notification.builder().setTitle(title).setBody(body).build();
			for (UserDeviceToken device : devices) {
				sendToDevice(device, notification, targetUserId);
			}
		}
		catch (RuntimeException e) {
			// Bilinçli olarak GENİŞ yakalama. Bu metot çağıranın @Transactional
			// gövdesinden
			// çalışıyor (ChatService.sendMessage,
			// TrainingBlockService.assignTemplateToClient);
			// buradan kaçan her istisna ASIL İŞLEMİ geri alır, yani mesaj hiç
			// kaydedilmez.
			// Bildirim mesajın yan etkisidir, ön koşulu değil.
			log.error("Bildirim gönderilemedi, asıl işlem etkilenmeyecek. UserID: {}", targetUserId, e);
		}
	}

	/**
	 * Tek bir cihaza gönderir ve <b>ölü token'ı siler</b>.
	 * <p>
	 * Uygulamayı silmiş bir kullanıcının token'ı daha önce hiç temizlenmiyordu: her
	 * bildirim denemesi sonsuza kadar hata üretiyordu. FCM bu durumu {@code UNREGISTERED}
	 * (uygulama kaldırılmış) ve {@code INVALID_ARGUMENT} (token bozuk) koduyla bildirir;
	 * ikisi de kalıcıdır, tekrar denemenin anlamı yoktur.
	 * </p>
	 */
	private void sendToDevice(UserDeviceToken device, Notification notification, Long targetUserId) {
		try {
			Message message = Message.builder().setToken(device.getToken()).setNotification(notification).build();
			FirebaseMessaging.getInstance().send(message);
		}
		catch (FirebaseMessagingException e) {
			MessagingErrorCode code = e.getMessagingErrorCode();
			if (code == MessagingErrorCode.UNREGISTERED || code == MessagingErrorCode.INVALID_ARGUMENT) {
				deviceTokenRepository.delete(device);
				log.info("Ölü cihaz token'ı silindi. UserID: {}, Sebep: {}", targetUserId, code);
			}
			else {
				log.error("FCM bildirimi gönderilemedi. UserID: {}, Kod: {}", targetUserId, code);
			}
		}
	}

}
