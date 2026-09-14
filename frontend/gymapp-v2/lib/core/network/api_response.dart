class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String timestamp;

  /// Hata durumlarında sunucunun döndürdüğü HTTP durum kodu (örn. doğrulanmamış
  /// telefon için 403). Başarılı yanıtlarda null'dır.
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.timestamp,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: (json['success'] as bool?) ?? false,
      message: (json['message'] as String?) ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      timestamp: (json['timestamp'] as String?) ?? '',
    );
  }

  factory ApiResponse.error(String message) {
    return ApiResponse<T>(
      success: false,
      message: message,
      timestamp: DateTime.now().toIso8601String(),
    );
  }
}
