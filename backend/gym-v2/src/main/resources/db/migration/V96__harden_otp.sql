-- OTP sertleştirmesi.
--
-- Önceki durumda üretilen 6 haneli OTP kodunun ne son kullanma tarihi ne de deneme
-- sayacı vardı; kod süresiz geçerli kalıyor ve sınırsız kez denenebiliyordu. Ayrıca
-- yeniden gönderim (resend) hiçbir soğuma süresine tabi değildi.
--
-- otp_expires_at   : kodun geçerliliğini yitireceği an
-- otp_attempt_count: aynı kod için yapılan hatalı deneme sayısı
-- otp_last_sent_at : son gönderim anı (yeniden gönderim soğuması için)

ALTER TABLE app_user ADD COLUMN IF NOT EXISTS otp_expires_at TIMESTAMPTZ;
ALTER TABLE app_user ADD COLUMN IF NOT EXISTS otp_attempt_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE app_user ADD COLUMN IF NOT EXISTS otp_last_sent_at TIMESTAMPTZ;

-- Mevcut doğrulanmamış kayıtlarda süresiz geçerli kodlar dolaşıyor olabilir; hepsini
-- geçersiz kılıyoruz. Etkilenen kullanıcı "kodu yeniden gönder" ile yeni kod alır.
UPDATE app_user SET otp_code = NULL WHERE otp_code IS NOT NULL;
