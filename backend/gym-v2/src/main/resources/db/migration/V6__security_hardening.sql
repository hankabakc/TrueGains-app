-- Brute-Force Koruması için AppUser Tablosuna Kolon Ekleme
ALTER TABLE app_user ADD COLUMN failed_login_attempts INT DEFAULT 0;
ALTER TABLE app_user ADD COLUMN account_locked_until TIMESTAMP;
ALTER TABLE app_user ADD COLUMN last_login_at TIMESTAMP;

-- Refresh Token Tablosu
CREATE TABLE refresh_token (
    id BIGSERIAL PRIMARY KEY,
    token VARCHAR(255) NOT NULL UNIQUE,
    user_id BIGINT NOT NULL,
    expiry_date TIMESTAMP NOT NULL,
    CONSTRAINT fk_refresh_token_user FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE
);

-- Kara Liste (Blacklist) Tablosu
CREATE TABLE blacklisted_token (
    id BIGSERIAL PRIMARY KEY,
    token VARCHAR(500) NOT NULL UNIQUE,
    expiry_date TIMESTAMP NOT NULL
);

-- PII (Kişisel Veri) Alanlarını Şifreli Veri İçin Hazırlama
-- fullName ve bio alanlarını şifreli (Base64) veri tutacak şekilde genişletiyoruz
ALTER TABLE client ALTER COLUMN full_name TYPE VARCHAR(500);
ALTER TABLE client ALTER COLUMN bio TYPE TEXT;
ALTER TABLE coach ALTER COLUMN full_name TYPE VARCHAR(500);
ALTER TABLE coach ALTER COLUMN bio TYPE TEXT;
