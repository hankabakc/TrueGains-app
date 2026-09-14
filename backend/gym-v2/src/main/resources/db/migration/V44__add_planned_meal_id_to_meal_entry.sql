-- V44: MealEntry tablosuna planned_meal_id kolonu eklenmesi
-- Diyet programındaki spesifik öğün (Meal) referansı için kullanılır.

ALTER TABLE meal_entry ADD COLUMN planned_meal_id BIGINT;

-- İndeksleme (Performans için)
CREATE INDEX idx_meal_entry_planned_meal_id ON meal_entry(planned_meal_id);
