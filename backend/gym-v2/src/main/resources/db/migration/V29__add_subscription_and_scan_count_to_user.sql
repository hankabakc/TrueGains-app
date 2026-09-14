-- V29: Kullanıcı abonelik ve günlük OCR tarama limiti alanlarının eklenmesi

ALTER TABLE app_user 
ADD COLUMN is_premium BOOLEAN DEFAULT FALSE,
ADD COLUMN daily_scan_count INTEGER DEFAULT 0,
ADD COLUMN last_scan_date DATE;
