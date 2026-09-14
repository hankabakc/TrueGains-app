import 'package:gymapp_v2/features/auth/data/models/user_role.dart';

/// Kayıt akışı üç ayrı rotaya bölünmüş olsa da kullanıcı için tek bir yolculuk:
/// intro soruları → kimlik formu → profil adımları. Üçü de aynı ilerleme barını
/// doldurur. Adım numaralarını sayfalara tek tek gömmek kırılgan olur; sayaç
/// yalnızca burada tanımlanır.
///
/// Sporcu  : 8 intro sorusu + 1 form + 3 profil adımı = 12
/// Antrenör: 3 intro sorusu + 1 form + 4 profil adımı = 8
///
/// Antrenöre hedef/kalori sorulmaz ama boy ve kilo backend'de zorunlu
/// (CoachRegistrationValidator), bu yüzden rol sorusuyla birlikte 3 soru.
int signupIntroSteps(UserRole role) => role == UserRole.COACH ? 3 : 8;

int signupProfileSteps(UserRole role) => role == UserRole.COACH ? 4 : 3;

int signupTotalSteps(UserRole role) =>
    signupIntroSteps(role) + 1 + signupProfileSteps(role);

/// Kimlik formunun (telefon / e-posta / şifre) akıştaki sıfır tabanlı indeksi.
int signupFormStep(UserRole role) => signupIntroSteps(role);

/// Profil adımlarının akıştaki sıfır tabanlı indeksi.
int signupProfileStep(UserRole role, int page) =>
    signupFormStep(role) + 1 + page;

/// Bar üstündeki etiket. Akış boyunca tek biçim: "SORU x / 8" ve "ADIM x / 2"
/// gibi iki ayrı sayaç kullanıcıya iki ayrı süreç gibi görünüyordu.
String signupStepLabel(int step, int total) => 'ADIM ${step + 1} / $total';
