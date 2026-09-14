-- Mesajlaşma Sistemi (Chat) Altyapısı - Robust Idempotent Version

-- 1. Konuşma Tablosunu Oluştur (Yoksa)
CREATE TABLE IF NOT EXISTS conversation (
    id BIGSERIAL PRIMARY KEY,
    client_id BIGINT NOT NULL,
    coach_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_conv_client FOREIGN KEY (client_id) REFERENCES app_user(id),
    CONSTRAINT fk_conv_coach FOREIGN KEY (coach_id) REFERENCES app_user(id),
    CONSTRAINT unique_conv_pair UNIQUE (client_id, coach_id)
);

-- 2. Eksik Kolonları Ekle (Varsa hata vermez)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='conversation' AND column_name='last_message_at') THEN
        ALTER TABLE conversation ADD COLUMN last_message_at TIMESTAMP;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='conversation' AND column_name='is_active') THEN
        ALTER TABLE conversation ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_conv_pair') THEN
        ALTER TABLE conversation ADD CONSTRAINT unique_conv_pair UNIQUE (client_id, coach_id);
    END IF;
END $$;

-- 3. Mesaj Tablosunu Oluştur (Yoksa)
CREATE TABLE IF NOT EXISTS message (
    id BIGSERIAL PRIMARY KEY,
    conversation_id BIGINT NOT NULL,
    sender_id BIGINT NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_msg_conv FOREIGN KEY (conversation_id) REFERENCES conversation(id) ON DELETE CASCADE,
    CONSTRAINT fk_msg_sender FOREIGN KEY (sender_id) REFERENCES app_user(id)
);

-- Eğer message tablosu V3'ten gelip sender_user_id veya created_at içeriyorsa bunları güncelle:
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='message' AND column_name='sender_user_id') THEN
        ALTER TABLE message RENAME COLUMN sender_user_id TO sender_id;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='message' AND column_name='created_at') THEN
        ALTER TABLE message RENAME COLUMN created_at TO sent_at;
    END IF;
END $$;

-- 4. İndeksleri Güvenli Şekilde Oluştur
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_msg_conv_id') THEN
        CREATE INDEX idx_msg_conv_id ON message(conversation_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_conv_client_id') THEN
        CREATE INDEX idx_conv_client_id ON conversation(client_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_conv_coach_id') THEN
        CREATE INDEX idx_conv_coach_id ON conversation(coach_id);
    END IF;
END $$;
