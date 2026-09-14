import 'package:dio/dio.dart';

/// Hata nesnesini kullanıcı dostu Türkçe bir hata mesajına dönüştürür.
String friendlyError(Object? error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Bağlantı zaman aşımına uğradı, lütfen bağlantınızı kontrol edin.';
    }
    if (error.response == null) {
      return 'Sunucuya bağlanılamadı. Lütfen internet bağlantınızı kontrol edin.';
    }
    if (error.response?.statusCode == 409) {
      return 'Bu kayıt başka bir yerde güncellendi. Lütfen sayfayı yenileyip tekrar deneyin.';
    }
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'İşlem tamamlanamadı. Lütfen tekrar deneyin.';
  }
  return 'Beklenmedik bir hata oluştu. Lütfen tekrar deneyin.';
}
