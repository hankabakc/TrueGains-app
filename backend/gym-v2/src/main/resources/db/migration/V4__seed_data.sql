-- V4: Seed Data (Full Exercise List from Backup)

-- Yonetici hesabi burada tohumlanmaz: kaynakta hesap bilgisi tutulmaz. Ilk yonetici
-- ADMIN_EMAIL / ADMIN_PASSWORD ile acilista olusturulur (AdminBootstrap). Sabit e-posta ve
-- bcrypt ozetli satir 14.09.2026'da cikarildi; mevcut veritabanlarinda bu surumun
-- flyway_schema_history checksum'i ayni gun guncellendi (flyway repair ile ayni islem).

-- Full Exercise Seed
INSERT INTO exercise (id, title, muscle_group, description) VALUES
(1, 'Chest Press Machine', 'CHEST', 'Gym - machine chest press'),
(2, 'Butterfly / Pec Deck', 'CHEST', 'Gym - pec deck fly'),
(3, 'Cable Crossover', 'CHEST', 'Gym - cable chest fly'),
(4, 'Incline Chest Press Machine', 'CHEST', 'Gym - incline chest press'),
(5, 'Lat Pulldown', 'BACK', 'Gym - lat pulldown'),
(6, 'Seated Cable Row', 'BACK', 'Gym - seated cable row'),
(7, 'Assisted Pull-Up Machine', 'BACK', 'Gym - assisted pull-up'),
(8, 'Hyperextension', 'BACK', 'Gym - back extension bench'),
(9, 'Shoulder Press Machine', 'SHOULDER', 'Gym - machine shoulder press'),
(10, 'Lateral Raise Machine', 'SHOULDER', 'Gym - machine lateral raise'),
(11, 'Face Pull (Cable)', 'SHOULDER', 'Gym - cable face pull'),
(12, 'Shrug Machine', 'SHOULDER', 'Gym - machine shrug'),
(13, 'Leg Press', 'LEGS', 'Gym - leg press'),
(14, 'Leg Extension', 'LEGS', 'Gym - leg extension'),
(15, 'Leg Curl', 'LEGS', 'Gym - lying or seated leg curl'),
(16, 'Abductor Machine', 'LEGS', 'Gym - hip abductor'),
(17, 'Calf Raise Machine', 'LEGS', 'Gym - calf raise machine'),
(18, 'Cable Pushdown', 'ARMS', 'Gym - cable triceps pushdown'),
(19, 'Triceps Extension Machine', 'ARMS', 'Gym - triceps extension machine'),
(20, 'Cable Curl', 'ARMS', 'Gym - cable biceps curl'),
(21, 'Preacher Curl Machine', 'ARMS', 'Gym - preacher curl machine'),
(22, 'Ab Crunch Machine', 'ABS', 'Gym - ab crunch machine'),
(23, 'Cable Woodchopper', 'ABS', 'Gym - cable woodchopper'),
(24, 'Standard Push-Up', 'CHEST', 'Bodyweight - standard push-up'),
(25, 'Wide Grip Push-Up', 'CHEST', 'Bodyweight - wide grip push-up'),
(26, 'Incline Push-Up', 'CHEST', 'Bodyweight - incline push-up'),
(27, 'Decline Push-Up', 'CHEST', 'Bodyweight - decline push-up'),
(28, 'Superman', 'BACK', 'Bodyweight - superman hold'),
(29, 'Reverse Snow Angel', 'BACK', 'Bodyweight - reverse snow angel'),
(30, 'Doorframe Row', 'BACK', 'Bodyweight - doorframe row'),
(31, 'Prone Cobra', 'BACK', 'Bodyweight - prone cobra'),
(32, 'Pike Push-Up', 'SHOULDER', 'Bodyweight - pike push-up'),
(33, 'Arm Circles', 'SHOULDER', 'Bodyweight - arm circles'),
(34, 'Wall Walk', 'SHOULDER', 'Bodyweight - wall walk'),
(35, 'Bodyweight Squat', 'LEGS', 'Bodyweight - squat'),
(36, 'Lunges', 'LEGS', 'Bodyweight - forward lunge'),
(37, 'Bulgarian Split Squat', 'LEGS', 'Bodyweight - bulgarian split squat'),
(38, 'Glute Bridge', 'LEGS', 'Bodyweight - glute bridge'),
(39, 'Calf Raise', 'LEGS', 'Bodyweight - calf raise'),
(40, 'Bench Dips', 'ARMS', 'Bodyweight - bench dips'),
(41, 'Diamond Push-Up', 'ARMS', 'Bodyweight - diamond push-up'),
(42, 'Plank', 'ABS', 'Bodyweight - plank hold'),
(43, 'Crunch', 'ABS', 'Bodyweight - crunch'),
(44, 'Leg Raise', 'ABS', 'Bodyweight - lying leg raise'),
(45, 'Mountain Climber', 'ABS', 'Bodyweight - mountain climber');

-- Select next sequence value
SELECT setval('exercise_id_seq', 45, true);
