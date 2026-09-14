-- GYMAPP-V2 Phase 2: Atıl (Legacy) Tabloların Temizlenmesi
-- Faz 1'den kalan ve artık kullanılmayan tekil isimli tablolar siliniyor.
-- Veriler zaten V15 ile yeni 'exercises' tablosuna taşınmıştı.

DROP TABLE IF EXISTS workout_exercise_set_log CASCADE;
DROP TABLE IF EXISTS workout_exercise CASCADE;
DROP TABLE IF EXISTS workout_day CASCADE;
DROP TABLE IF EXISTS exercise CASCADE;

-- Not: Beslenme (Nutrition) tabloları henüz taşınmadığı için onlara dokunulmadı.
