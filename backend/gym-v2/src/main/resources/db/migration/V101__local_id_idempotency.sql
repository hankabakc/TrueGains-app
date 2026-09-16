-- G-79: Çevrimdışı kuyruk ya da zaman aşımında yeniden gönderilen istek aynı kaydı ikinci kez yazmasın.
-- Cihaz her kayda bir kimlik (UUID metni) verir; aynı kullanıcı + aynı kimlik ikinci satır açamaz.
-- Kimliği göndermeyen eski istemcide sütun boş kalır; UNIQUE birden çok NULL'a izin verir.
ALTER TABLE workout_sessions ADD COLUMN local_id VARCHAR(36);
ALTER TABLE workout_sessions ADD CONSTRAINT uq_workout_sessions_user_local UNIQUE (user_id, local_id);

ALTER TABLE message ADD COLUMN local_id VARCHAR(36);
ALTER TABLE message ADD CONSTRAINT uq_message_sender_local UNIQUE (sender_id, local_id);