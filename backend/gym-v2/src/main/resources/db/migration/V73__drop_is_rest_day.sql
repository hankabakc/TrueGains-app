-- V73__drop_is_rest_day.sql
-- workout_days tablosundan is_rest_day kolonunun kaldırılması. 
-- "Egzersiz yoksa dinlenme günüdür" (exercises.isEmpty) kuralı tek doğruluk kaynağı olarak kullanılacaktır.

ALTER TABLE workout_days DROP COLUMN is_rest_day;
