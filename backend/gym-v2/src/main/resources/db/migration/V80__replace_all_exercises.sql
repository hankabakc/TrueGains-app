-- V80: Replace all exercises in the library with the user's custom list

-- Clean up referencing records first to preserve database constraints
DELETE FROM workout_logs;
DELETE FROM workout_exercises;
DELETE FROM exercises;

-- Restart the exercises ID sequence
ALTER SEQUENCE exercises_id_seq RESTART WITH 1;

-- 1. CHEST (Göğüs)
INSERT INTO exercises (name, muscle_group, description, image_url) VALUES
('Barbell Bench Press', 'CHEST', 'Gym - barbell bench press', 'barbell_bench_press.jpeg'),
('Dumbbell Bench Press', 'CHEST', 'Gym - dumbbell bench press', 'dumbbell_bench_press.jpeg'),
('Incline Dumbbell Press', 'CHEST', 'Gym - incline dumbbell press', 'incline_dumbbell_press.jpeg'),
('Incline Barbell Press', 'CHEST', 'Gym - incline barbell press', 'incline_barbell_press.jpeg'),
('Incline Smith Machine Press', 'CHEST', 'Gym - incline smith machine press', 'incline_smith_machine_press.png'),
('Decline Bench Press', 'CHEST', 'Gym - decline bench press', NULL),
('Chest Dips', 'CHEST', 'Gym - chest dips', 'chest_dips.png'),
('Cable Crossover', 'CHEST', 'Gym - cable crossover', 'cable_crossover.png'),
('Cable Fly', 'CHEST', 'Gym - cable fly', 'cable_fly.png'),
('Pec Deck Fly', 'CHEST', 'Gym - pec deck fly', NULL),
('Machine Fly', 'CHEST', 'Gym - machine fly', 'machine_fly.png'),
('Chest Press', 'CHEST', 'Gym - machine chest press', 'chest_press.jpeg');

-- 2. BACK (Sırt)
INSERT INTO exercises (name, muscle_group, description, image_url) VALUES
('Lat Pulldown', 'BACK', 'Gym - lat pulldown', 'lat_pulldown.png'),
('Pull-up (Barfiks)', 'BACK', 'Bodyweight - pull-up', 'pull_up.png'),
('Barbell Row', 'BACK', 'Gym - barbell row', 'barbell_row.png'),
('T-Bar Row', 'BACK', 'Gym - t-bar row', 't_bar_row.png'),
('Dumbbell Row', 'BACK', 'Gym - dumbbell row', 'dumbbell_row.png'),
('Seated Cable Row', 'BACK', 'Gym - seated cable row', 'seated_cable_row.png'),
('Chest Supported Dumbbell Row', 'BACK', 'Gym - chest supported dumbbell row', 'chest_supported_dumbbell_row.png'),
('Deadlift', 'BACK', 'Gym - deadlift', 'deadlift.png');

-- 3. BICEPS (Ön Kol)
INSERT INTO exercises (name, muscle_group, description, image_url) VALUES
('Barbell Curl', 'BICEPS', 'Gym - barbell curl', 'barbell_curl.png'),
('EZ-Bar Curl (Z-Bar)', 'BICEPS', 'Gym - ez-bar curl', 'ez_bar_curl.png'),
('Dumbbell Curl', 'BICEPS', 'Gym - dumbbell curl', 'dumbbell_curl.png'),
('Incline Dumbbell Curl', 'BICEPS', 'Gym - incline dumbbell curl', 'incline_dumbbell_curl.png'),
('Hammer Curl', 'BICEPS', 'Gym - hammer curl', NULL),
('Rope Hammer Curl', 'BICEPS', 'Gym - rope hammer curl', 'rope_hammer_curl.png'),
('Preacher Curl', 'BICEPS', 'Gym - preacher curl', 'preacher_curl.png');

-- 4. TRICEPS (Arka Kol)
INSERT INTO exercises (name, muscle_group, description, image_url) VALUES
('Triceps Pushdown', 'TRICEPS', 'Gym - triceps pushdown', 'triceps_pushdown.png'),
('Rope Pushdown', 'TRICEPS', 'Gym - rope pushdown', 'rope_pushdown.png'),
('Overhead Dumbbell Extension', 'TRICEPS', 'Gym - overhead dumbbell extension', 'overhead_dumbbell_extension.png'),
('Overhead Cable Extension', 'TRICEPS', 'Gym - overhead cable extension', 'overhead_cable_extension.png'),
('Skull Crusher', 'TRICEPS', 'Gym - skull crusher', 'skull_crusher.png'),
('Close-Grip Bench Press', 'TRICEPS', 'Gym - close-grip bench press', 'close_grip_bench_press.png');

-- 5. ABS (Karın)
INSERT INTO exercises (name, muscle_group, description, image_url) VALUES
('Crunch', 'ABS', 'Bodyweight - crunch', 'crunch.png'),
('Cable Crunch', 'ABS', 'Gym - cable crunch', 'cable_crunch.png'),
('Hanging Leg Raise', 'ABS', 'Bodyweight - hanging leg raise', 'hanging_leg_raise.png'),
('Lying Leg Raise', 'ABS', 'Bodyweight - lying leg raise', 'lying_leg_raise.png'),
('Plank', 'ABS', 'Bodyweight - plank', 'plank.png'),
('Russian Twist', 'ABS', 'Bodyweight - russian twist', 'russian_twist.png');

-- 6. SHOULDERS (Omuz)
INSERT INTO exercises (name, muscle_group, description, image_url) VALUES
('Overhead Press', 'SHOULDERS', 'Gym - overhead press', 'overhead_press.png'),
('Seated Dumbbell Shoulder Press', 'SHOULDERS', 'Gym - seated dumbbell shoulder press', 'seated_dumbbell_shoulder_press.png'),
('Lateral Raise', 'SHOULDERS', 'Gym - lateral raise', 'lateral_raise.png'),
('Cable Lateral Raise', 'SHOULDERS', 'Gym - cable lateral raise', 'cable_lateral_raise.png'),
('Face Pull', 'SHOULDERS', 'Gym - face pull', NULL),
('Dumbbell Rear Delt Fly', 'SHOULDERS', 'Gym - dumbbell rear delt fly', NULL);

-- 7. QUADRICEPS (Ön Bacak)
INSERT INTO exercises (name, muscle_group, description, image_url) VALUES
('Squat', 'QUADRICEPS', 'Gym - squat', 'squat.png'),
('Front Squat', 'QUADRICEPS', 'Gym - front squat', NULL),
('Leg Press', 'QUADRICEPS', 'Gym - leg press', 'leg_press.png'),
('Hack Squat', 'QUADRICEPS', 'Gym - hack squat', 'hack_squat.png'),
('Leg Extension', 'QUADRICEPS', 'Gym - leg extension', 'leg_extension.png');

-- 8. HAMSTRINGS (Arka Bacak)
INSERT INTO exercises (name, muscle_group, description, image_url) VALUES
('Romanian Deadlift (RDL)', 'HAMSTRINGS', 'Gym - romanian deadlift', NULL),
('Dumbbell RDL', 'HAMSTRINGS', 'Gym - dumbbell rdl', 'dumbbell_rdl.png'),
('Lying Leg Curl', 'HAMSTRINGS', 'Gym - lying leg curl', 'lying_leg_curl.png'),
('Seated Leg Curl', 'HAMSTRINGS', 'Gym - seated leg curl', NULL),
('Walking Lunges', 'HAMSTRINGS', 'Gym - walking lunges', 'walking_lunges.png'),
('Bulgarian Split Squat', 'HAMSTRINGS', 'Bodyweight - bulgarian split squat', 'bulgarian_split_squat.png');

-- 9. CALVES (Kalf)
INSERT INTO exercises (name, muscle_group, description, image_url) VALUES
('Standing Calf Raise', 'CALVES', 'Gym - standing calf raise', 'standing_calf_raise.png'),
('Smith Machine Calf Raise', 'CALVES', 'Gym - smith machine calf raise', NULL),
('Seated Calf Raise', 'CALVES', 'Gym - seated calf raise', 'seated_calf_raise.png');

-- Populate scientific names according to the muscle groups for the details page
UPDATE exercises SET scientific_name = 'Pectoralis Major' WHERE muscle_group = 'CHEST';
UPDATE exercises SET scientific_name = 'Latissimus Dorsi, Trapezius' WHERE muscle_group = 'BACK';
UPDATE exercises SET scientific_name = 'Deltoideus' WHERE muscle_group = 'SHOULDERS';
UPDATE exercises SET scientific_name = 'Biceps Brachii' WHERE muscle_group = 'BICEPS';
UPDATE exercises SET scientific_name = 'Triceps Brachii' WHERE muscle_group = 'TRICEPS';
UPDATE exercises SET scientific_name = 'Quadriceps Femoris' WHERE muscle_group = 'QUADRICEPS';
UPDATE exercises SET scientific_name = 'Biceps Femoris, Semitendinosus' WHERE muscle_group = 'HAMSTRINGS';
UPDATE exercises SET scientific_name = 'Gastrocnemius, Soleus' WHERE muscle_group = 'CALVES';
UPDATE exercises SET scientific_name = 'Rectus Abdominis, Obliques' WHERE muscle_group = 'ABS';
UPDATE exercises SET scientific_name = 'Multiple Muscle Groups' WHERE muscle_group = 'FULL_BODY';
UPDATE exercises SET scientific_name = 'Cardiovascular System' WHERE muscle_group = 'CARDIO';
