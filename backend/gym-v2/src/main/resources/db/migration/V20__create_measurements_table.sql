-- =====================================================
-- V20: Ölçüm (Measurement) tablosu
-- Kullanıcıların vücut ölçülerini ve kilo takibini
-- yapabilmesi için gerekli veri yapısını oluşturur.
-- =====================================================

CREATE TABLE measurements (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,

    -- Temel metrikler
    weight          DECIMAL(5,2),       -- Kilo (kg), örn: 85.50
    body_fat_pct    DECIMAL(4,1),       -- Yağ oranı (%), örn: 18.5

    -- Bölgesel ölçüler (cm cinsinden)
    chest           DECIMAL(5,1),       -- Göğüs çevresi
    waist           DECIMAL(5,1),       -- Bel çevresi
    shoulders       DECIMAL(5,1),       -- Omuz çevresi
    left_arm        DECIMAL(5,1),       -- Sol kol çevresi
    right_arm       DECIMAL(5,1),       -- Sağ kol çevresi
    left_leg        DECIMAL(5,1),       -- Sol bacak çevresi
    right_leg       DECIMAL(5,1),       -- Sağ bacak çevresi
    hips            DECIMAL(5,1),       -- Kalça çevresi

    -- Ek bilgiler
    notes           TEXT,               -- Kullanıcı notları
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Performans: Kullanıcıya göre hızlı sorgulama
CREATE INDEX idx_measurements_user_id ON measurements(user_id);

-- Performans: Tarih bazlı sıralama
CREATE INDEX idx_measurements_created_at ON measurements(created_at DESC);
