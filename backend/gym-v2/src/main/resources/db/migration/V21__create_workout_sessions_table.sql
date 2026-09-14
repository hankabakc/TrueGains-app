-- GYMAPP-V2 İdman Oturumu (Session) ve Geçmiş Sistemi
CREATE TABLE workout_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_user(id),
    workout_day_name VARCHAR(255) NOT NULL,
    total_seconds INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- WorkoutLog tablosuna session_id ekleyelim
-- Dikkat: WorkoutLog tablosu V10 migrasyonunda oluşturulmuştu.
ALTER TABLE workout_logs ADD COLUMN session_id BIGINT REFERENCES workout_sessions(id) ON DELETE CASCADE;

-- İndeksler (Performans için)
CREATE INDEX idx_workout_sessions_user ON workout_sessions(user_id);
CREATE INDEX idx_workout_logs_session ON workout_logs(session_id);
