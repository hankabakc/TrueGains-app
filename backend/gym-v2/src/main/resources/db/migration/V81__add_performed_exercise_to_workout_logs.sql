-- V81__add_performed_exercise_to_workout_logs.sql
-- Add performed_exercise_id to workout_logs, referencing exercises(id)
ALTER TABLE workout_logs ADD COLUMN performed_exercise_id BIGINT NULL;

ALTER TABLE workout_logs ADD CONSTRAINT fk_workout_log_performed_exercise
    FOREIGN KEY (performed_exercise_id) REFERENCES exercises(id);

CREATE INDEX idx_workout_log_performed_exercise ON workout_logs(performed_exercise_id);
