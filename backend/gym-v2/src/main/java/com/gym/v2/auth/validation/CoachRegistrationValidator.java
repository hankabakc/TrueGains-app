package com.gym.v2.auth.validation;

import com.gym.v2.auth.dto.RegisterRequest;
import com.gym.v2.auth.entity.UserRole;
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

/**
 * CoachRegistrationValid anotasyonu için doğrulama mantığını uygulayan validator sınıfı.
 * Koç rolüyle kaydolan kullanıcılarda bio, uzmanlık ve profil fotoğrafının zorunlu
 * olmasını sağlar.
 */
public class CoachRegistrationValidator implements ConstraintValidator<CoachRegistrationValid, RegisterRequest> {

	@Override
	public boolean isValid(RegisterRequest value, ConstraintValidatorContext context) {
		if (value == null) {
			return true;
		}

		// Sadece COACH rolü için doğrulama yap
		if (value.role() != UserRole.COACH) {
			return true;
		}

		boolean valid = true;
		context.disableDefaultConstraintViolation();

		// Biyografi doğrulaması
		if (value.bio() == null || value.bio().isBlank()) {
			context.buildConstraintViolationWithTemplate("{validation.profile.bio.notBlank}")
				.addPropertyNode("bio")
				.addConstraintViolation();
			valid = false;
		}

		// Uzmanlık alanı doğrulaması
		if (value.specialization() == null || value.specialization().isBlank()) {
			context.buildConstraintViolationWithTemplate("{validation.profile.specialization.notBlank}")
				.addPropertyNode("specialization")
				.addConstraintViolation();
			valid = false;
		}

		// Profil fotoğrafı doğrulaması
		if (value.profilePhotoUrl() == null || value.profilePhotoUrl().isBlank()) {
			context.buildConstraintViolationWithTemplate("{validation.profile.photo.notBlank}")
				.addPropertyNode("profilePhotoUrl")
				.addConstraintViolation();
			valid = false;
		}

		// Boy doğrulaması (Koç için zorunlu)
		if (value.heightCm() == null) {
			context.buildConstraintViolationWithTemplate("{validation.profile.height.notNull}")
				.addPropertyNode("heightCm")
				.addConstraintViolation();
			valid = false;
		}

		// Kilo doğrulaması (Koç için zorunlu)
		if (value.weightKg() == null) {
			context.buildConstraintViolationWithTemplate("{validation.profile.weight.notNull}")
				.addPropertyNode("weightKg")
				.addConstraintViolation();
			valid = false;
		}

		return valid;
	}

}
