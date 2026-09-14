ALTER TABLE subscription_package ADD COLUMN features TEXT;

UPDATE subscription_package SET features = 'Haftalık antrenman programı
Beslenme danışmanlığı' WHERE id = 1;

UPDATE subscription_package SET features = '7/24 WhatsApp desteği
Haftalık görüntülü analiz
Kişiselleştirilmiş beslenme' WHERE id = 2;

UPDATE subscription_package SET features = 'Birebir özel takip
Günlük form ve teknik analizi
Detaylı supplement planlaması
VIP WhatsApp grubu' WHERE id = 3;
