import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/auth_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/chat_bloc.dart';
import 'package:gymapp_v2/features/dashboard/presentation/bloc/navigation/navigation_cubit.dart';
import 'package:gymapp_v2/core/navigation/last_route_store.dart';

// --- States ---
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthAuthenticated extends AuthState {
  final AuthModel auth;
  const AuthAuthenticated(this.auth);
  @override
  List<Object?> get props => [auth];
}

/// Kayıt/giriş başarılı ama telefon doğrulanmadı: OTP ekranına yönlendirilmeli.
/// Bu durumda kullanıcı henüz oturum açmış SAYILMAZ (token verilmez).
class AuthOtpRequired extends AuthState {
  final String email;
  const AuthOtpRequired(this.email);
  @override
  List<Object?> get props => [email];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// --- Events ---
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  const LoginSubmitted(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmitted extends AuthEvent {
  final Map<String, dynamic> data;
  const RegisterSubmitted(this.data);
  @override
  List<Object?> get props => [data];
}

class LogoutRequested extends AuthEvent {
  /// false: oturum düştü ya da hesap silindi; bekleyen kayıtlar gönderilmeye çalışılmaz.
  final bool syncPending;
  const LogoutRequested({this.syncPending = true});
  @override
  List<Object?> get props => [syncPending];
}

/// Uygulama açılışında tetiklenir: kalıcı refresh cookie'si ile oturumu
/// sessizce geri yüklemeyi dener ("oturumda kal").
class AppStarted extends AuthEvent {}

/// OTP doğrulaması başarıyla tamamlandı; oturum token'ı ile kullanıcı yetkilendirilir.
class AuthVerified extends AuthEvent {
  final AuthModel auth;
  const AuthVerified(this.auth);
  @override
  List<Object?> get props => [auth];
}

// --- Bloc ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(AuthInitial()) {
    // Açılışta sessiz oturum geri yükleme. Bilerek AuthLoading YAYMAZ: durum
    // çözülene kadar AuthInitial kalır; böylece router redirect'i cold-start
    // restore'u (AuthInitial → splash) login akışından (AuthLoading) ayırır.
    on<AppStarted>((event, emit) async {
      final result = await _repository.restoreSession();
      if (result.success && result.data != null && result.data!.accessToken.isNotEmpty) {
        emit(AuthAuthenticated(result.data!));
      } else {
        emit(AuthUnauthenticated());
      }
    });

    on<LoginSubmitted>((event, emit) async {
      emit(AuthLoading());
      final result = await _repository.login(event.email, event.password);
      if (result.success && result.data != null) {
        emit(AuthAuthenticated(result.data!));
      } else if (result.statusCode == 403) {
        // Telefon doğrulanmamış: OTP ekranına yönlendir (token verilmedi).
        emit(AuthOtpRequired(event.email));
      } else {
        emit(AuthError(result.message));
      }
    });

    on<RegisterSubmitted>((event, emit) async {
      emit(AuthLoading());
      final result = await _repository.register(event.data);
      if (result.success) {
        // Kayıt token vermez; telefon doğrulaması için OTP ekranına geçilir.
        emit(AuthOtpRequired(event.data['email'] as String));
      } else {
        emit(AuthError(result.message));
      }
    });

    on<AuthVerified>((event, emit) {
      emit(AuthAuthenticated(event.auth));
    });

    on<LogoutRequested>((event, emit) async {
      // Durum temizlik bittikten sonra yayımlanır: önce yayımlansa giriş ekranı açılır ve
      // arkada süren temizlik, o arada giriş yapan kullanıcının jetonunu silebilirdi.
      await _repository.logout(syncPending: event.syncPending);
      // ChatBloc singleton'ı sıfırla (LazySingleton olduğu için bir sonraki kullanımda taze başlar)
      sl.resetLazySingleton<ChatBloc>();
      sl.resetLazySingleton<NavigationCubit>();
      sl<LastRouteStore>().clear();
      emit(AuthUnauthenticated());
    });
  }
}
