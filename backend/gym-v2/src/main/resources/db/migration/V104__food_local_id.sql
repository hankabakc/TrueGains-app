-- G-87: İnternetsiz oluşturulan özel besin kuyruktan ya da zaman aşımında yeniden gelirse ikinci kez yazılmasın; aynı
-- cihazda internetsiz kaydedilen öğün bu besine cihaz kimliğiyle bağlanır (KR13 mimarisi, madde 2). Aynı oluşturan + aynı
-- kimlik ikinci satır açamaz; kimlik göndermeyen istekte sütun boş kalır.
ALTER TABLE food ADD COLUMN local_id VARCHAR(36);
ALTER TABLE food ADD CONSTRAINT uq_food_creator_local UNIQUE (creator_id, local_id);
