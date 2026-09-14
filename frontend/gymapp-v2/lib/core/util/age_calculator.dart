/// Doğum tarihinden yaş hesaplar.
///
/// Tarih yoksa veya okunamıyorsa **null** döner — bilinmeyen yaş için uydurma bir sayı
/// üretilmez. Önceki hâlinde profil ekranı bu durumda `0` basıyordu ve koç, sporcunun
/// yaşını sıfır görüp bunun bir hata olduğunu anlayamıyordu.
///
/// Mantık iki ekranda ayrı ayrı yazılmıştı (profil detayı ve diyet hedefleri); biri hatalı
/// dalı `0` ile, diğeri `null` ile kapatıyordu. Tek yerde toplandı.
///
/// [now] yalnızca test için verilir; verilmezse sistem saati kullanılır.
int? calculateAge(String? birthDateIso, {DateTime? now}) {
  if (birthDateIso == null) return null;

  final DateTime? birthDate = DateTime.tryParse(birthDateIso);
  if (birthDate == null) return null;

  final DateTime today = now ?? DateTime.now();
  int age = today.year - birthDate.year;

  // Doğum günü bu yıl henüz gelmediyse bir yaş geri al.
  if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
    age--;
  }

  return age;
}
