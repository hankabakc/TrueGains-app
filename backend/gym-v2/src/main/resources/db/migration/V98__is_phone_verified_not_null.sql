-- V98: is_phone_verified kolonuna NOT NULL kısıtı.
--
-- Kolon V66'da `BOOLEAN DEFAULT FALSE` olarak eklendi ama NOT NULL yazılmadı. Kod alanı üç
-- yerde doğrudan açıyor (AuthenticationService: verifyOtp, resendOtp, login —
-- `if (user.getIsPhoneVerified())`), yani değer NULL olsa NullPointerException → 500 döner
-- ve o kullanıcı giriş yapamaz.
--
-- Uygulama içindeki hiçbir yol NULL yazmıyor (hem entity alanı hem builder alanı `false`
-- ile başlıyor); risk yalnızca dışarıdan yazma — elle SQL, veri taşıma, tohum verisi.
-- Kısıt bu ihtimali tamamen kaldırıyor.

UPDATE app_user SET is_phone_verified = FALSE WHERE is_phone_verified IS NULL;

ALTER TABLE app_user ALTER COLUMN is_phone_verified SET NOT NULL;
