-- G-74: İnternetsiz oluşturulan programın egzersizi cihazda negatif geçici kimlik alır; sunucu yeni satırı açarken bu
-- kimliği saklar. İnternetsiz yapılan antrenmanın setleri egzersize bu kimlikle bağlanır (KR13 mimarisi, madde 2).
ALTER TABLE workout_exercises ADD COLUMN local_id VARCHAR(36);
CREATE INDEX idx_workout_exercises_local_id ON workout_exercises (local_id);
