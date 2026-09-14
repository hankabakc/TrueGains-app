-- V64: WorkoutSession tablosuna trainingBlockId ve workoutDayId kolonlarını ekle
ALTER TABLE workout_sessions ADD COLUMN training_block_id BIGINT;
ALTER TABLE workout_sessions ADD COLUMN workout_day_id BIGINT;

-- Geriye dönük uyumluluk için yabancı anahtar (FK) kısıtlamalarını ekliyoruz
-- CASCADE yerine SET NULL veya RESTRICT yapılabilir. Burada verilerin bütünlüğü açısından kısıt kuralı ekliyoruz ancak null bırakılabilir yapıda.
ALTER TABLE workout_sessions ADD CONSTRAINT fk_workout_sessions_training_block FOREIGN KEY (training_block_id) REFERENCES training_blocks (id) ON DELETE SET NULL;
ALTER TABLE workout_sessions ADD CONSTRAINT fk_workout_sessions_workout_day FOREIGN KEY (workout_day_id) REFERENCES workout_days (id) ON DELETE SET NULL;
