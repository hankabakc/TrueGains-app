-- V72__weekly_progress_and_rest_day.sql
-- Antrenman günlerine dinlenme günü (is_rest_day) alanı eklenmesi ve haftalık ilerleme takibi için kalıcı tablonun oluşturulması.

-- 1. workout_days tablosuna is_rest_day alanı ekleme
ALTER TABLE workout_days ADD COLUMN is_rest_day BOOLEAN NOT NULL DEFAULT FALSE;

-- 2. Eski veriler için egzersizi olmayan günleri rest day (dinlenme günü) olarak işaretleme
UPDATE workout_days wd 
SET is_rest_day = TRUE 
WHERE NOT EXISTS (
    SELECT 1 FROM workout_exercises we WHERE we.day_id = wd.id
);

-- 3. Haftalık kalıcı ilerleme tablosunun (weekly_progress) oluşturulması
CREATE TABLE weekly_progress (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
    training_block_id BIGINT NOT NULL REFERENCES training_blocks(id) ON DELETE CASCADE,
    week_start_date DATE NOT NULL,
    target_days INT NOT NULL DEFAULT 0,
    completed_days INT NOT NULL DEFAULT 0,
    completion_rate DOUBLE PRECISION NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_weekly_progress UNIQUE (user_id, training_block_id, week_start_date)
);
