import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';
import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/experience_level.dart';
import 'package:gymapp_v2/features/auth/data/models/goal.dart';
import 'package:gymapp_v2/features/profile/data/models/client_profile_response_model.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_form/profile_form_cubit.dart';

/// Profil kaydetme gövdesinin testleri.
///
/// Sunucu `updateClientProfile` içinde alanların tamamını koşulsuz yazar:
/// gövdede eksik veya `null` gelen bir alan mevcut değeri **siler**. Bu yüzden
/// buradaki asıl soru "gövde doğru mu" değil, **"kullanıcının verisi kayboluyor mu"**.
void main() {
  ClientProfileResponseModel profile({
    String? websiteUrl,
    String? instagramUrl,
    String? bio,
  }) {
    return ClientProfileResponseModel(
      userId: 1,
      fullName: 'Ahmet Yilmaz',
      email: 'ahmet@test.com',
      profilePhotoUrl: 'https://example.com/foto.jpg',
      dateOfBirth: '2000-01-15',
      gender: Gender.male,
      heightCm: 180,
      weightKg: 80.0,
      goal: Goal.kiloVer,
      activityLevel: ActivityLevel.moderatelyActive,
      bio: bio,
      instagramUrl: instagramUrl,
      websiteUrl: websiteUrl,
      tiktokUrl: null,
      publicPhotos: const [],
      showAge: true,
      showHeight: true,
      showWeight: false,
      province: 'Istanbul',
      district: 'Kadikoy',
      experienceLevel: ExperienceLevel.orta,
    );
  }

  group('kaydetme gövdesi mevcut veriyi korur', () {
    test('web sitesi ekranda düzenlenmese bile silinmez', () {
      final cubit = ProfileFormCubit(profile(websiteUrl: 'https://ahmet.com'));

      final payload = cubit.buildUpdatePayload(instagramInput: '', tiktokInput: '');

      // Ekranda web sitesi alanı yok; değer kayıt sırasında girilmiş olabilir.
      // Gövdeye null yazılırsa sunucu mevcut adresi siler.
      expect(payload['websiteUrl'], 'https://ahmet.com');
    });

    test('dokunulmayan alanlar profilden geldiği gibi gider', () {
      final cubit = ProfileFormCubit(profile(bio: 'Merhaba'));

      final payload = cubit.buildUpdatePayload(instagramInput: '', tiktokInput: '');

      expect(payload['fullName'], 'Ahmet Yilmaz');
      expect(payload['bio'], 'Merhaba');
      expect(payload['heightCm'], 180);
      expect(payload['weightKg'], 80.0);
      expect(payload['dateOfBirth'], '2000-01-15');
      expect(payload['profilePhotoUrl'], 'https://example.com/foto.jpg');
      expect(payload['showAge'], true);
      expect(payload['showWeight'], false);
    });

    test('düzenlenen alan gövdeye yansır', () {
      final cubit = ProfileFormCubit(profile());
      cubit.updateBio('Yeni biyografi');
      cubit.updateWeightKg(78.5);

      final payload = cubit.buildUpdatePayload(instagramInput: '', tiktokInput: '');

      expect(payload['bio'], 'Yeni biyografi');
      expect(payload['weightKg'], 78.5);
    });

    test('web sitesi hiç yoksa null gider', () {
      final cubit = ProfileFormCubit(profile());

      final payload = cubit.buildUpdatePayload(instagramInput: '', tiktokInput: '');

      expect(payload['websiteUrl'], isNull);
    });
  });

  group('sosyal medya adresi normalleştirme', () {
    test('kullanıcı adı tam adrese çevrilir', () {
      expect(ProfileFormCubit.normalizeInstagram('ahmet'), 'www.instagram.com/ahmet');
      expect(ProfileFormCubit.normalizeTiktok('@ahmet'), 'www.tiktok.com/@ahmet');
    });

    test('zaten tam adres verilmişse ikinci kez sarmalanmaz', () {
      expect(
        ProfileFormCubit.normalizeInstagram('www.instagram.com/ahmet'),
        'www.instagram.com/ahmet',
      );
      expect(
        ProfileFormCubit.normalizeTiktok('www.tiktok.com/@ahmet'),
        'www.tiktok.com/@ahmet',
      );
    });

    test('boş giriş null döner; boş metin adres olarak kaydedilmez', () {
      expect(ProfileFormCubit.normalizeInstagram(''), isNull);
      expect(ProfileFormCubit.normalizeInstagram('   '), isNull);
      expect(ProfileFormCubit.normalizeTiktok(''), isNull);
    });
  });
}
