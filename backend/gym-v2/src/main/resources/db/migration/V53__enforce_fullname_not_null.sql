-- V53: full_name alanının zorunlu hale getirilmesi ve mevcut null verilerin temizlenmesi
UPDATE coach SET full_name = 'Bilinmeyen Antrenör' WHERE full_name IS NULL;
UPDATE client SET full_name = 'Bilinmeyen Danışan' WHERE full_name IS NULL;

ALTER TABLE coach ALTER COLUMN full_name SET NOT NULL;
ALTER TABLE client ALTER COLUMN full_name SET NOT NULL;
