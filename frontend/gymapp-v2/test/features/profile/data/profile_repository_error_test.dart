import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/error_message.dart';

void main() {
  test('sunucunun mesajı kullanıcıya iletilir', () {
    final e = DioException(
      requestOptions: RequestOptions(path: '/profile/me'),
      response: Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/profile/me'),
        statusCode: 400,
        data: const {'message': 'Aktif aboneliğiniz var.'},
      ),
    );

    expect(friendlyError(e), 'Aktif aboneliğiniz var.');
  });

  test('bağlantı yoksa anlaşılır mesaj döner', () {
    final e = DioException(
      requestOptions: RequestOptions(path: '/profile/me'),
      type: DioExceptionType.connectionTimeout,
    );

    expect(friendlyError(e), contains('zaman aşımı'));
  });
}
