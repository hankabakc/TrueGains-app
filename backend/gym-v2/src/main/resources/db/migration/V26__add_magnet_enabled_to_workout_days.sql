-- Antrenman günlerine mıknatıs modu (magnet mode) kalıcılığı için sütun eklenmesi
ALTER TABLE workout_days ADD COLUMN is_magnet_enabled BOOLEAN DEFAULT TRUE;
