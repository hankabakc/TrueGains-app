package com.gym.v2.core.exception;

import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.core.service.LogService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.core.annotation.AnnotatedElementUtils;
import org.springframework.context.MessageSource;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.http.converter.HttpMessageNotReadableException;

import java.time.Clock;
import java.util.HashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Uygulama genelinde fırlatılan istisnaları (Exceptions) merkezi olarak yakalayan sınıf.
 * Güvenlik ve mimari standartlar gereği hataları ApiResponse zarfı içinde sunar.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

	private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

	private final MessageSource messageSource;

	private final Clock clock;

	private final LogService logService;

	public GlobalExceptionHandler(MessageSource messageSource, Clock clock, LogService logService) {
		this.messageSource = messageSource;
		this.clock = clock;
		this.logService = logService;
	}

	/**
	 * @ResponseStatus annotasyonu taşıyan özel istisnaları (NotFoundException gibi) kendi
	 * durum kodları ile fırlatır.
	 */
	@ExceptionHandler(NotFoundException.class)
	@ResponseStatus(HttpStatus.NOT_FOUND)
	public ApiResponse<Void> handleNotFoundException(NotFoundException ex,
			jakarta.servlet.http.HttpServletRequest request) {
		log.warn("[NOT FOUND] {} {} → {}", request.getMethod(), request.getRequestURI(), ex.getMessage());
		return ApiResponse.error(ex.getMessage(), clock.instant());
	}

	/**
	 * Bulgu #8: İstemci kaynaklı hatalar (400) için özel yönetim. Log seviyesi 'warn'
	 * olarak set edildi (Yanlış alarmları önlemek için).
	 */
	@ExceptionHandler(BadRequestException.class)
	@ResponseStatus(HttpStatus.BAD_REQUEST)
	public ApiResponse<Void> handleBadRequestException(BadRequestException ex,
			jakarta.servlet.http.HttpServletRequest request) {
		log.warn("[BAD REQUEST] {} {} → {}", request.getMethod(), request.getRequestURI(), ex.getMessage());
		return ApiResponse.error(ex.getMessage(), clock.instant());
	}

	/**
	 * Kimlik doğrulama hataları.
	 */
	@ExceptionHandler(BadCredentialsException.class)
	@ResponseStatus(HttpStatus.UNAUTHORIZED)
	public ApiResponse<Void> handleBadCredentials(BadCredentialsException ex) {
		String msg = messageSource.getMessage("error.auth.bad-credentials", null, "Geçersiz e-posta veya şifre.",
				LocaleContextHolder.getLocale());
		return ApiResponse.error(msg, clock.instant());
	}

	/**
	 * Kilitli hesap - şifre DOĞRU girilmiş (kontrol şifreden sonra, bkz.
	 * SecurityConfig#authenticationProvider). Tasarlanmış durum: 500 değil 401, Sentry'ye
	 * gitmez.
	 * <p>
	 * 403 kullanılmaz: mobil istemci 403'ü "telefon doğrulanmadı" sayıp OTP ekranına
	 * yönlendiriyor (auth_bloc.dart:104).
	 * </p>
	 */
	@ExceptionHandler(LockedException.class)
	@ResponseStatus(HttpStatus.UNAUTHORIZED)
	public ApiResponse<Void> handleLocked(LockedException ex) {
		log.warn("[AUTH] Kilitli hesaba doğru şifreyle giriş denemesi");
		String msg = messageSource.getMessage("error.auth.account-locked", null, LocaleContextHolder.getLocale());
		return ApiResponse.error(msg, clock.instant());
	}

	/**
	 * Pasifleştirilmiş hesap - şifre doğru girilmiş. Aynı gerekçe: 401, Sentry'ye gitmez.
	 */
	@ExceptionHandler(DisabledException.class)
	@ResponseStatus(HttpStatus.UNAUTHORIZED)
	public ApiResponse<Void> handleDisabled(DisabledException ex) {
		log.warn("[AUTH] Pasif hesaba doğru şifreyle giriş denemesi");
		String msg = messageSource.getMessage("error.auth.account-disabled", null, LocaleContextHolder.getLocale());
		return ApiResponse.error(msg, clock.instant());
	}

	/**
	 * Telefonu doğrulanmamış hesapla giriş - tasarlanmış akış, hata değil; istemci 403
	 * ile OTP ekranına geçiyor. RuntimeException yakalayıcısına düşünce log.error +
	 * Sentry üretiyor, panelin Hatalar ekranını beklenen davranışla dolduruyordu. Uyarı
	 * logunu AuthenticationService zaten yazıyor.
	 */
	@ExceptionHandler(PhoneNotVerifiedException.class)
	@ResponseStatus(HttpStatus.FORBIDDEN)
	public ApiResponse<Void> handlePhoneNotVerified(PhoneNotVerifiedException ex) {
		return ApiResponse.error(ex.getMessage(), clock.instant());
	}

	/**
	 * Form doğrulama (Validation) hataları.
	 */
	@ExceptionHandler(MethodArgumentNotValidException.class)
	@ResponseStatus(HttpStatus.BAD_REQUEST)
	public ApiResponse<Object> handleValidationExceptions(MethodArgumentNotValidException ex,
			jakarta.servlet.http.HttpServletRequest request) {
		Map<String, String> errors = new HashMap<>();
		ex.getBindingResult()
			.getFieldErrors()
			.forEach(error -> errors.put(error.getField(), error.getDefaultMessage()));
		log.warn("[VALIDATION ERROR] {} {} → {}", request.getMethod(), request.getRequestURI(), errors);
		return ApiResponse.error("Validasyon hatası oluştu.", errors, clock.instant());
	}

	/**
	 * Genel Runtime istisnaları.
	 */
	@ExceptionHandler(RuntimeException.class)
	public ResponseEntity<ApiResponse<Object>> handleRuntimeException(RuntimeException ex,
			jakarta.servlet.http.HttpServletRequest request) {
		log.error("[RUNTIME EXCEPTION] {} {} → {}", request.getMethod(), request.getRequestURI(), ex.getMessage(), ex);
		logService.error(ex);

		ResponseStatus responseStatus = AnnotatedElementUtils.findMergedAnnotation(ex.getClass(), ResponseStatus.class);

		if (responseStatus != null) {
			return ResponseEntity.status(responseStatus.value())
				.body(ApiResponse.error(ex.getMessage(), clock.instant()));
		}

		String msg = messageSource.getMessage("error.system.runtime", null, "İşlem sırasında bir hata oluştu.",
				LocaleContextHolder.getLocale());
		return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ApiResponse.error(msg, clock.instant()));
	}

	/**
	 * Yetki (403 Forbidden) hataları.
	 */
	@ExceptionHandler({ AccessDeniedException.class, SecurityException.class })
	@ResponseStatus(HttpStatus.FORBIDDEN)
	public ApiResponse<Void> handleAccessDenied(Exception ex, jakarta.servlet.http.HttpServletRequest request) {
		log.warn("[ACCESS DENIED] {} {} → {}", request.getMethod(), request.getRequestURI(), ex.getMessage());
		String msg = (ex.getMessage() != null && !ex.getMessage().isBlank()) ? ex.getMessage()
				: "Bu işlem için yetkiniz bulunmamaktadır.";
		return ApiResponse.error(msg, clock.instant());
	}

	/**
	 * Geçersiz HTTP yöntemi (405 Method Not Allowed) hataları.
	 */
	@ExceptionHandler(HttpRequestMethodNotSupportedException.class)
	@ResponseStatus(HttpStatus.METHOD_NOT_ALLOWED)
	public ApiResponse<Void> handleMethodNotSupported(HttpRequestMethodNotSupportedException ex,
			jakarta.servlet.http.HttpServletRequest request) {
		log.warn("[METHOD NOT SUPPORTED] {} {} → {}", request.getMethod(), request.getRequestURI(), ex.getMessage());
		return ApiResponse.error("HTTP metodu desteklenmiyor: " + ex.getMethod(), clock.instant());
	}

	/**
	 * Bozuk veya eksik JSON gövdesi (400 Bad Request) hataları.
	 */
	@ExceptionHandler(HttpMessageNotReadableException.class)
	@ResponseStatus(HttpStatus.BAD_REQUEST)
	public ApiResponse<Void> handleMessageNotReadable(HttpMessageNotReadableException ex,
			jakarta.servlet.http.HttpServletRequest request) {
		log.warn("[MESSAGE NOT READABLE] {} {} → {}", request.getMethod(), request.getRequestURI(), ex.getMessage());
		return ApiResponse.error("İstek gövdesi okunamadı veya JSON formatı hatalı.", clock.instant());
	}

	/**
	 * Eksik veya yanlış tipte istek parametresi (400 Bad Request).
	 * <p>
	 * Bu yakalayıcılar olmadan {@code MissingServletRequestParameterException} ve
	 * {@code MethodArgumentTypeMismatchException} genel {@code Exception} yakalayıcısına
	 * düşüyor ve <b>istemci hatası 500 olarak</b> dönüyordu. Çalışan uygulamada iki uçta
	 * doğrulandı: {@code /diet/daily-log} ve {@code /social/discover} zorunlu
	 * parametresiz çağrıldığında 500 veriyordu.
	 * </p>
	 * <p>
	 * İki zararı: istemci kendi hatasını sunucu çökmesi sanıyor, ve her eksik parametre
	 * Sentry'ye kritik hata olarak gidip gerçek 500'leri gürültüye boğuyor.
	 * </p>
	 */
	@ExceptionHandler({ org.springframework.web.bind.ServletRequestBindingException.class,
			org.springframework.web.method.annotation.MethodArgumentTypeMismatchException.class })
	@ResponseStatus(HttpStatus.BAD_REQUEST)
	public ApiResponse<Void> handleRequestBinding(Exception ex, jakarta.servlet.http.HttpServletRequest request) {
		log.warn("[BAD REQUEST] {} {} → {}", request.getMethod(), request.getRequestURI(), ex.getMessage());
		return ApiResponse.error("İstek parametreleri eksik veya hatalı.", clock.instant());
	}

	/**
	 * Tanımsız yol (404 Not Found).
	 * <p>
	 * Bu yakalayıcı olmadan {@code NoResourceFoundException} aşağıdaki genel
	 * {@code Exception} yakalayıcısına düşüyor ve <b>her bilinmeyen adres 500
	 * döndürüyordu</b>. İki somut zararı vardı: adresi yanlış yazan istemci "sunucu
	 * çöktü" sanıyordu ve her 404, Sentry'ye kritik hata olarak gidip gerçek 500'leri
	 * gürültüye boğuyordu.
	 * </p>
	 */
	@ExceptionHandler(org.springframework.web.servlet.resource.NoResourceFoundException.class)
	@ResponseStatus(HttpStatus.NOT_FOUND)
	public ApiResponse<Void> handleNoResourceFound(org.springframework.web.servlet.resource.NoResourceFoundException ex,
			jakarta.servlet.http.HttpServletRequest request) {
		log.warn("[NOT FOUND] {} {}", request.getMethod(), request.getRequestURI());
		return ApiResponse.error("İstenen kaynak bulunamadı.", clock.instant());
	}

	/**
	 * Kritik sistem hataları.
	 */
	@ExceptionHandler(Exception.class)
	@ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
	public ApiResponse<Void> handleAllExceptions(Exception ex, jakarta.servlet.http.HttpServletRequest request) {
		log.error("[CRITICAL ERROR] {} {} → {}", request.getMethod(), request.getRequestURI(), ex.getMessage(), ex);
		logService.error(ex);
		String msg = messageSource.getMessage("error.system.critical", null,
				"Sistemde beklenmedik bir hata oluştu. Lütfen daha sonra tekrar deneyiniz.",
				LocaleContextHolder.getLocale());
		return ApiResponse.error(msg, clock.instant());
	}

}
