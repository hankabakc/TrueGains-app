-- Kullanıcı şikâyetleri (moderasyon kuyruğu).
--
-- Neden yeni tablo: `user_block` "kullanıcı kullanıcıyı engelledi" demek — kişisel bir
-- tercih, yöneticiye bildirilmez. Şikâyet ise yönetimin görmesi ve KARARA BAĞLAMASI
-- gereken ayrı bir kayıttır.
--
-- description ŞİFRELİ (EncryptionConverter): kullanıcının serbest yazdığı metin,
-- üçüncü kişiler hakkında kişisel veri içerebilir. Şifreli alan base64 ciphertext
-- olduğu için sütun TEXT.
CREATE TABLE user_report (
    id                BIGSERIAL PRIMARY KEY,
    reporter_id       BIGINT       NOT NULL REFERENCES app_user (id) ON DELETE CASCADE,
    reported_user_id  BIGINT       NOT NULL REFERENCES app_user (id) ON DELETE CASCADE,
    reason            VARCHAR(40)  NOT NULL,
    description       TEXT,
    status            VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
    created_at        TIMESTAMPTZ  NOT NULL,
    reviewed_at       TIMESTAMPTZ,
    reviewed_by       VARCHAR(255),
    resolution_note   TEXT,
    CONSTRAINT user_report_not_self CHECK (reporter_id <> reported_user_id)
);

-- Kuyruk her zaman "bekleyenler, en yenisi üstte" diye okunuyor.
CREATE INDEX idx_user_report_status_created ON user_report (status, created_at DESC);

-- Bir kullanıcı hakkında kaç şikâyet var sorusu, kullanıcı detayında sorulacak.
CREATE INDEX idx_user_report_reported ON user_report (reported_user_id);

-- Aynı kişiyi aynı sebeple defalarca raporlamak kuyruğu şişirir; tekil kısıt
-- BEKLEYEN kayıtlar için geçerli (karara bağlandıktan sonra tekrar raporlanabilir).
CREATE UNIQUE INDEX idx_user_report_unique_pending
    ON user_report (reporter_id, reported_user_id, reason)
    WHERE status = 'PENDING';
