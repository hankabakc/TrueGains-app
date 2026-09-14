-- V50: NULL Versiyon kolonlarının düzeltilmesi (NPE Önleyici)
UPDATE diet_program SET version = 0 WHERE version IS NULL;
UPDATE training_blocks SET version = 0 WHERE version IS NULL;
UPDATE pairing_request SET version = 0 WHERE version IS NULL;
