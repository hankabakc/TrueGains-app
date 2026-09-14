package com.gym.v2.auth.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;
import java.lang.annotation.*;

/**
 * Koç kayıt işlemlerindeki koşullu alan zorunluluklarını doğrulamak için sınıf
 * seviyesinde kullanılan constraint anotasyonu.
 */
@Target({ ElementType.TYPE })
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = CoachRegistrationValidator.class)
public @interface CoachRegistrationValid {

	String message() default "Koç kaydı için zorunlu alanlar eksik.";

	Class<?>[] groups() default {};

	Class<? extends Payload>[] payload() default {};

}
