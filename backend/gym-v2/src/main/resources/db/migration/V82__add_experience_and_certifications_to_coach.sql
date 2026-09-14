-- Koç profilini zenginleştirmek için deneyim yılı ve sertifikalar kolonları ekleniyor.
ALTER TABLE coach ADD COLUMN experience_years INTEGER;
ALTER TABLE coach ADD COLUMN certifications TEXT;
