-- V55: diet_program tablosuna is_template kolonunun eklenmesi
ALTER TABLE diet_program ADD COLUMN IF NOT EXISTS is_template BOOLEAN DEFAULT FALSE;
