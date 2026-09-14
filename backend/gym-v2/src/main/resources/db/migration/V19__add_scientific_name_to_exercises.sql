-- GYMAPP-V2 Phase 5: Egzersiz kütüphanesine bilimsel isim ve hedef kas detayları ekleme.
-- Premium egzersiz detay sayfası için gerekli.

ALTER TABLE exercises ADD COLUMN scientific_name VARCHAR(255);
ALTER TABLE exercises ADD COLUMN target_muscle_details TEXT;

-- Mevcut egzersizler için bilimsel isimleri doldur
UPDATE exercises SET scientific_name = 'Pectoralis Major' WHERE muscle_group = 'CHEST';
UPDATE exercises SET scientific_name = 'Latissimus Dorsi, Trapezius' WHERE muscle_group = 'BACK';
UPDATE exercises SET scientific_name = 'Deltoideus' WHERE muscle_group = 'SHOULDERS';
UPDATE exercises SET scientific_name = 'Biceps Brachii' WHERE muscle_group = 'BICEPS';
UPDATE exercises SET scientific_name = 'Triceps Brachii' WHERE muscle_group = 'TRICEPS';
UPDATE exercises SET scientific_name = 'Quadriceps Femoris' WHERE muscle_group = 'QUADRICEPS';
UPDATE exercises SET scientific_name = 'Biceps Femoris, Semitendinosus' WHERE muscle_group = 'HAMSTRINGS';
UPDATE exercises SET scientific_name = 'Gastrocnemius, Soleus' WHERE muscle_group = 'CALVES';
UPDATE exercises SET scientific_name = 'Rectus Abdominis, Obliques' WHERE muscle_group = 'ABS';
UPDATE exercises SET scientific_name = 'Multiple Muscle Groups' WHERE muscle_group = 'FULL_BODY';
UPDATE exercises SET scientific_name = 'Cardiovascular System' WHERE muscle_group = 'CARDIO';
