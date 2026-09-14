package com.gym.v2.core.service;

import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

/**
 * İşlem başarıyla commit edildikten SONRA çalışacak yan etkileri kaydeder.
 * <p>
 * WebSocket yayınları ve benzeri bildirimler {@code @Transactional} gövdesinin içinden
 * gönderildiğinde, işlem sonradan geri alınsa bile istemci "yenile" sinyalini almış olur
 * ve <b>eski veriyi</b> çeker. Bu yardımcı, yayını commit sonrasına erteler; işlem geri
 * alınırsa yayın hiç yapılmaz.
 * </p>
 * <p>
 * Aktif bir işlem yoksa eylem hemen çalıştırılır, böylece işlemsiz çağrı yerleri de
 * bozulmaz.
 * </p>
 */
@Component
public class TransactionalEvents {

	public void afterCommit(Runnable action) {
		if (!TransactionSynchronizationManager.isSynchronizationActive()) {
			action.run();
			return;
		}
		TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
			@Override
			public void afterCommit() {
				action.run();
			}
		});
	}

}
