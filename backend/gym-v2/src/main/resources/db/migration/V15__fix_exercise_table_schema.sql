-- GYMAPP-V2 Phase 2: Egzersiz Verisi Taşınması
-- Phase 1'deki (V10) yeni tablo yapısında exercises isimli boş bir tablo oluşmuştu 
-- ancak V4'teki seed veriler eski "exercise" tablosunda kaldı.
-- Bu verileri yeni "exercises" tablosuna aktarıyoruz.

INSERT INTO exercises (id, name, muscle_group, description)
SELECT id, title, muscle_group, description FROM exercise
ON CONFLICT (id) DO NOTHING;

-- Gelecekteki eklemelerin hata vermemesi için sequence'i ayarla
SELECT setval('exercises_id_seq', (SELECT COALESCE(MAX(id), 1) FROM exercises));
