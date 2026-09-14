-- V56: training_blocks tablosuna is_template kolonunun eklenmesi
ALTER TABLE training_blocks ADD COLUMN IF NOT EXISTS is_template BOOLEAN DEFAULT FALSE NOT NULL;
