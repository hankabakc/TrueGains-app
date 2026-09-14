-- Refresh Token Tablosuna Cihaz Kimliği Ekleme
ALTER TABLE refresh_token ADD COLUMN device_id VARCHAR(255);

-- Bir kullanıcının aynı cihazda birden fazla aktif refresh token'ı olmamasını garantilemek için (isteğe bağlı)
-- CREATE UNIQUE INDEX idx_user_device_refresh ON refresh_token(user_id, device_id);
