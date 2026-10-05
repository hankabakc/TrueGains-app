import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/error_message.dart';

void main() {
  final RequestOptions options = RequestOptions(path: '/test');

  test('friendlyError returns server message on 409 when message present', () {
    final dioException = DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 409,
        data: <String, dynamic>{
          'success': false,
          'message': 'Bu antrenörü zaten değerlendirdiniz.',
        },
      ),
    );

    expect(friendlyError(dioException), 'Bu antrenörü zaten değerlendirdiniz.');
  });

  test('friendlyError returns fallback conflict text on 409 when data is null', () {
    final dioException = DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: 409,
        data: null,
      ),
    );

    expect(
      friendlyError(dioException),
      'Bu kayıt başka bir yerde güncellendi. Lütfen sayfayı yenileyip tekrar deneyin.',
    );
  });
}
