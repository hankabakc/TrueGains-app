package com.gym.v2.auth.dto;

import com.gym.v2.auth.entity.UserRole;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import com.gym.v2.auth.validation.CoachRegistrationValid;
import java.time.LocalDate;

/**
 * Yeni bir kullanıcı kaydı (registration) oluşturmak için gerekli tüm verileri bir arada
 * taşıyan record.
 * <p>
 * Hem temel kimlik doğrulama bilgilerini hem de kullanıcı rolüne (CLIENT veya COACH) özgü
 * profil detaylarını içerir.
 * </p>
 *
 * <h2>Nasıl Çalışır?</h2> İstemci, kullanıcının seçtiği role göre ilgili alanları
 * doldurarak bu nesneyi sunucuya gönderir. Sunucu tarafında bu veriler hem Jakarta Bean
 * Validation hem de iş mantığı seviyesinde doğrulanır.
 *
 * <h2>Neden Bu Nesne Var?</h2> Kullanıcı kaydı sırasında parçalı istekler yerine, atomik
 * ve bütünleşik bir yapı sunarak istemci-sunucu arasındaki veri transferini optimize
 * etmek için kullanılır.
 *
 * @param email Kullanıcının sisteme kayıt olacağı e-posta adresi. Benzersiz olmalıdır.
 * @param password Kullanıcının güvenli şifresi (En az 10 karakter, büyük/küçük harf,
 * rakam ve özel karakter içermelidir).
 * @param role Kullanıcının sistemdeki rolü (CLIENT veya COACH).
 * @param firstName Kullanıcının adı.
 * @param lastName Kullanıcının soyadı.
 * @param bio Kullanıcının kısa özgeçmişi veya açıklaması.
 * @param dateOfBirth Kullanıcının doğum tarihi (Client için).
 * @param gender Kullanıcının cinsiyeti (Client için).
 * @param heightCm Kullanıcının boyu (Client için).
 * @param weightKg Kullanıcının kilosu (Client için).
 * @param goal Kullanıcının spor hedefi (Client için).
 * @param activityLevel Kullanıcının günlük aktivite seviyesi (Client için).
 * @param showAge Yaş bilgisinin profilinde gösterilip gösterilmeyeceği.
 * @param showHeight Boy bilgisinin profilinde gösterilip gösterilmeyeceği.
 * @param showWeight Kilo bilgisinin profilinde gösterilip gösterilmeyeceği.
 * @param specialization Antrenörün uzmanlık alanları (Coach için).
 * @param instagramUrl Antrenörün Instagram profil bağlantısı (Coach için).
 * @param websiteUrl Antrenörün kişisel veya profesyonel web sitesi bağlantısı (Coach
 * için).
 */
@CoachRegistrationValid
public record RegisterRequest(
		// Auth Info
		@NotBlank(message = "{validation.email.notblank}") @Email(message = "{validation.email.invalid}") @Pattern(
				regexp = "^[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}$",
				message = "{validation.email.pattern}") @Size(max = 255,
						message = "{validation.email.size}") String email,

		@NotBlank(message = "{validation.password.notblank}") @Size(min = 10, max = 128,
				message = "{validation.password.size}") @Pattern(
						regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&.\\-_])[A-Za-z\\d@$!%*?&.\\-_]{10,}$",
						message = "{validation.password.pattern}") String password,

		@NotNull(message = "{validation.role.notnull}") UserRole role,

		@NotBlank(message = "{validation.phone.notblank}") @Pattern(regexp = "^\\+?[1-9]\\d{1,14}$",
				message = "{validation.phone.pattern}") String phoneNumber,

		// Common Profile Info
		@NotBlank(message = "{validation.firstname.notblank}") @Size(min = 2, max = 100,
				message = "{validation.firstname.size}") @Pattern(regexp = "^[\\p{L}\\s'\\-\\.]{2,100}$",
						message = "{validation.name.pattern}") String firstName,

		@NotBlank(message = "{validation.lastname.notblank}") @Size(min = 2, max = 100,
				message = "{validation.lastname.size}") @Pattern(regexp = "^[\\p{L}\\s'\\-\\.]{2,100}$",
						message = "{validation.name.pattern}") String lastName,

		@Size(max = 2000, message = "{validation.bio.size}") String bio,

		@NotBlank(message = "İl seçimi zorunludur.") @Size(max = 50,
				message = "İl en fazla 50 karakter olabilir.") String province,

		@NotBlank(message = "İlçe seçimi zorunludur.") @Size(max = 50,
				message = "İlçe en fazla 50 karakter olabilir.") String district,
		@Size(max = 20, message = "Deneyim seviyesi en fazla 20 karakter olabilir.") String experienceLevel,

		// Client Specific
		@Past(message = "{validation.dob.past}") LocalDate dateOfBirth,
		@Size(max = 20, message = "{validation.gender.size}") @Pattern(regexp = "^(MALE|FEMALE|OTHER|UNSPECIFIED)?$",
				message = "{validation.gender.pattern}") String gender,
		@Min(value = 50, message = "{validation.height.min}") @Max(value = 300,
				message = "{validation.height.max}") Integer heightCm,
		@Positive(message = "{validation.weight.positive}") @Digits(integer = 3, fraction = 2,
				message = "{validation.weight.digits}") BigDecimal weightKg,
		@Size(max = 500, message = "{validation.goal.size}") String goal,
		@Size(max = 50, message = "{validation.activitylevel.size}") String activityLevel,
		@Size(max = 500, message = "{validation.url.size}") @Pattern(
				regexp = "^(https?://)(?:[a-zA-Z0-9.-]+)(?::\\d+)?(?:/[^<>\\s]*)?$",
				message = "{validation.url.pattern}") String profilePhotoUrl,
		Boolean showAge, Boolean showHeight, Boolean showWeight,

		// Coach Specific
		@Size(max = 255, message = "{validation.specialization.size}") String specialization,
		@Size(max = 500, message = "{validation.instagram.size}") @Pattern(
				regexp = "^https://www\\.instagram\\.com/[a-zA-Z0-9._-]+/?$",
				message = "{validation.instagram.pattern}") String instagramUrl,
		@Size(max = 500, message = "{validation.website.size}") @Pattern(
				regexp = "^(https?://)(?:[a-zA-Z0-9.-]+)(?::\\d+)?(?:/[^<>\\s]*)?$",
				message = "{validation.url.pattern}") String websiteUrl) {
}
