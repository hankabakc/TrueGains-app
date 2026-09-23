-- G-74: İnternetsiz oluşturulan kişisel program kuyruktan ya da zaman aşımında yeniden gelirse ikinci kez yazılmasın
-- (KR13 mimarisi, madde 2). Aynı sporcu + aynı cihaz kimliği ikinci satır açamaz; kimlik göndermeyen istekte sütun boş
-- kalır (UNIQUE birden çok NULL'a izin verir).
ALTER TABLE training_blocks ADD COLUMN local_id VARCHAR(36);
ALTER TABLE training_blocks ADD CONSTRAINT uq_training_blocks_client_local UNIQUE (client_id, local_id);
