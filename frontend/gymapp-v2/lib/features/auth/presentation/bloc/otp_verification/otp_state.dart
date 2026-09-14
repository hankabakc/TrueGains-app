import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/auth/data/models/auth_model.dart';

enum OtpStatus { initial, loading, success, failure, resending, resendSuccess }

class OtpState extends Equatable {
  final OtpStatus status;
  final String? error;
  final int resendTimer;

  /// Doğrulama başarıyla tamamlandığında dönen oturum bilgisi (token vb.).
  final AuthModel? auth;

  const OtpState({
    this.status = OtpStatus.initial,
    this.error,
    this.resendTimer = 60,
    this.auth,
  });

  OtpState copyWith({
    OtpStatus? status,
    String? error,
    int? resendTimer,
    AuthModel? auth,
  }) {
    return OtpState(
      status: status ?? this.status,
      error: error,
      resendTimer: resendTimer ?? this.resendTimer,
      auth: auth ?? this.auth,
    );
  }

  @override
  List<Object?> get props => [status, error, resendTimer, auth];
}
