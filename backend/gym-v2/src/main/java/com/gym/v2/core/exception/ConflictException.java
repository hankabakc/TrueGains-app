package com.gym.v2.core.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * İstek, kaydın sunucudaki güncel hâliyle çelişiyor (409): istemci eski bir sürümün
 * üstüne yazmak istedi (G-74, KR13). Çevrimdışı kuyruk 409'u kalıcı ret sayar; kayıt
 * silinmez, "aktarılamadı" listesinde kullanıcıya gösterilir.
 */
@ResponseStatus(HttpStatus.CONFLICT)
public class ConflictException extends RuntimeException {

	public ConflictException(String message) {
		super(message);
	}

}
