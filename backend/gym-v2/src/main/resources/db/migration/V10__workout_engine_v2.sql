-- GYMAPP-V2 Antrenman Motoru (Faz 2) Tablo Yapısı
-- Bu migrasyon; Egzersiz Kütüphanesi, Blok Programlama ve Loglama sistemini kurar.

-- 1. Egzersiz Kütüphanesi
CREATE TABLE exercises (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    muscle_group VARCHAR(50) NOT NULL,
    video_url VARCHAR(500),
    image_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Antrenman Blokları (Mesocycle)
CREATE TABLE training_blocks (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    coach_id BIGINT NOT NULL REFERENCES app_user(id),
    client_id BIGINT NOT NULL REFERENCES app_user(id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Antrenman Günleri
CREATE TABLE workout_days (
    id BIGSERIAL PRIMARY KEY,
    block_id BIGINT NOT NULL REFERENCES training_blocks(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    day_order INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Antrenman Egzersizleri (Hedefler)
CREATE TABLE workout_exercises (
    id BIGSERIAL PRIMARY KEY,
    day_id BIGINT NOT NULL REFERENCES workout_days(id) ON DELETE CASCADE,
    exercise_id BIGINT NOT NULL REFERENCES exercises(id),
    target_sets INTEGER,
    target_reps VARCHAR(50),
    target_weight DECIMAL(10,2),
    rest_time_seconds INTEGER,
    superset_group_id VARCHAR(100),
    order_index INTEGER NOT NULL,
    coach_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Antrenman Logları (Gerçekleşen)
CREATE TABLE workout_logs (
    id BIGSERIAL PRIMARY KEY,
    workout_exercise_id BIGINT NOT NULL REFERENCES workout_exercises(id) ON DELETE CASCADE,
    set_index INTEGER NOT NULL,
    actual_weight DECIMAL(10,2) NOT NULL,
    actual_reps INTEGER NOT NULL,
    rpe INTEGER CHECK (rpe >= 1 AND rpe <= 10),
    duration_seconds INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- İndeksler (Performans için)
CREATE INDEX idx_training_blocks_coach ON training_blocks(coach_id);
CREATE INDEX idx_training_blocks_client ON training_blocks(client_id);
CREATE INDEX idx_workout_days_block ON workout_days(block_id);
CREATE INDEX idx_workout_exercises_day ON workout_exercises(day_id);
CREATE INDEX idx_workout_logs_exercise ON workout_logs(workout_exercise_id);
