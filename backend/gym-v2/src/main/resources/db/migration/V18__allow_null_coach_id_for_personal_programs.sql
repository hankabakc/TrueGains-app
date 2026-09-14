-- GYMAPP-V2 Phase 3: Kişisel Program (Personal Program) Düzeltmesi
-- V10'da 'training_blocks' tablosundaki 'coach_id' kolonu NOT NULL olarak tanımlanmıştı.
-- Ancak sporcuların kendilerine yazdığı "Kişisel Program"larda coach_id null olmak zorundadır.
-- Bu kısıtlamayı kaldırıyoruz.

ALTER TABLE training_blocks ALTER COLUMN coach_id DROP NOT NULL;
