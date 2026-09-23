-- K2-09: kuyruktaki program düzenlemesi sunucuda uygulanıp yanıtı yolda kaybolursa aynı düzenleme kimliğiyle yeniden
-- gelir. Son uygulanan düzenlemenin kimliği tutulur; tekrar gelen istek 409 yerine uygulanmış hâli alır.
ALTER TABLE training_blocks ADD COLUMN last_edit_id VARCHAR(36);
