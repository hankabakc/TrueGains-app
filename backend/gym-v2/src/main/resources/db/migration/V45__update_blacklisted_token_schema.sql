-- BlacklistedToken tablosu için performans ve kapasite iyileştirmeleri
ALTER TABLE blacklisted_token ALTER COLUMN token TYPE VARCHAR(1024);
CREATE INDEX idx_blacklisted_token ON blacklisted_token(token);
