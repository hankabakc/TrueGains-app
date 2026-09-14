-- GYMAPP-V2 Phase 2: Kas Grubu İsimlendirme Uyumluluğu
-- DB'deki eski 'SHOULDER' (tekil) ve 'ARMS' (genel) isimlerini 
-- Java Enum (MuscleGroup.java) sabitleri ile birebir uyumlu hale getiriyoruz.
-- Bu uyumsuzluk "400 Bad Request" (IllegalArgumentException) hatasına sebep oluyordu.

UPDATE exercises SET muscle_group = 'SHOULDERS' WHERE muscle_group = 'SHOULDER';
UPDATE exercises SET muscle_group = 'BICEPS' WHERE muscle_group = 'ARMS';
