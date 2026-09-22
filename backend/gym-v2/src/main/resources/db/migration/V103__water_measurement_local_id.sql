-- G-86: İnternetsiz eklenen su ve ölçüm kuyruktan ya da zaman aşımında yeniden gelirse ikinci kez yazılmasın
-- (G-79 deseni). Aynı kullanıcı + aynı cihaz kimliği ikinci satır açamaz; kimlik göndermeyen istekte sütun boş kalır.
ALTER TABLE water_intake ADD COLUMN local_id VARCHAR(36);
ALTER TABLE water_intake ADD CONSTRAINT uq_water_intake_user_local UNIQUE (user_id, local_id);

ALTER TABLE measurements ADD COLUMN local_id VARCHAR(36);
ALTER TABLE measurements ADD CONSTRAINT uq_measurements_user_local UNIQUE (user_id, local_id);
