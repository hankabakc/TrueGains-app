import 'api_response.dart';
import 'error_message.dart';

mixin ApiErrorHandler {
  ApiResponse<T> handleError<T>(dynamic e, {String? defaultMessage}) {
    final message = defaultMessage ?? friendlyError(e);
    return ApiResponse<T>.error(message);
  }
}
