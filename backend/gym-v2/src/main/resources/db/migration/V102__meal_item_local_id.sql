-- G-72: Çevrimdışı kuyruktan ya da zaman aşımında yeniden gönderilen öğün kaydı aynı besini ikinci kez yazmasın.
-- Cihaz her kaleme bir kimlik (UUID metni) verir; aynı öğün kaydında aynı kimlik ikinci satır açamaz.
-- Kimliği göndermeyen eski istemcide sütun boş kalır; UNIQUE birden çok NULL'a izin verir.
ALTER TABLE meal_item ADD COLUMN local_id VARCHAR(36);
ALTER TABLE meal_item ADD CONSTRAINT uq_meal_item_entry_local UNIQUE (meal_entry_id, local_id);
