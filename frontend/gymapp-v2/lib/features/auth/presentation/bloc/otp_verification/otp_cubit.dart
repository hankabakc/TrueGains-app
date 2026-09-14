import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/auth/data/repositories/auth_repository.dart';
import 'otp_state.dart';

class OtpCubit extends Cubit<OtpState> {
  final AuthRepository _repository;
  Timer? _timer;

  OtpCubit(this._repository) : super(const OtpState()) {
    _startResendTimer();
  }

  void _startResendTimer() {
    _timer?.cancel();
    emit(state.copyWith(resendTimer: 60));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendTimer > 0) {
        emit(state.copyWith(resendTimer: state.resendTimer - 1));
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> verifyOtp(String email, String code) async {
    if (code.length != 6) {
      emit(state.copyWith(status: OtpStatus.failure, error: 'Doğrulama kodu 6 haneli olmalıdır.'));
      return;
    }

    emit(state.copyWith(status: OtpStatus.loading));
    final resp = await _repository.verifyOtp(email, code);

    if (resp.success && resp.data != null) {
      emit(state.copyWith(status: OtpStatus.success, auth: resp.data));
    } else {
      emit(state.copyWith(status: OtpStatus.failure, error: resp.message));
    }
  }

  Future<void> resendOtp(String email) async {
    if (state.resendTimer > 0) return;

    emit(state.copyWith(status: OtpStatus.resending));
    final resp = await _repository.resendOtp(email);

    if (resp.success) {
      emit(state.copyWith(status: OtpStatus.resendSuccess));
      _startResendTimer();
    } else {
      emit(state.copyWith(status: OtpStatus.failure, error: resp.message));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
