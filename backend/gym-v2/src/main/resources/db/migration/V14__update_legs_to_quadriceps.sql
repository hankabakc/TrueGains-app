-- GYMAPP-V2 Phase 2: Bacak (LEGS) kas grubunun daha spesifik kas gruplarına ayrılması
-- Eski 'LEGS' verilerini varsayılan olarak 'QUADRICEPS' (Ön Bacak / Baldır) e çeviriyoruz
-- ki uygulama başlarken Enum Mapping hatası (IllegalArgumentException) fırlatmasın.

UPDATE exercise SET muscle_group = 'QUADRICEPS' WHERE muscle_group = 'LEGS';
