import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'app_logger.dart';
import 'dart:developer' as developer;

/// GYMAPP-V2 Merkezi BLoC Gözlemcisi.
/// Tüm BLoC/Cubit olaylarını izler ve hataları merkezi logger üzerinden raporlar.
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    developer.log('onError(${bloc.runtimeType}, $error, $stackTrace)');

    // BLoC katmanındaki hataları merkezi logger üzerinden raporla
    final sl = GetIt.instance;
    if (sl.isRegistered<AppLogger>()) {
      sl<AppLogger>().error(
        error,
        stackTrace: stackTrace,
        tags: {'bloc': bloc.runtimeType.toString()},
      );
    }

    super.onError(bloc, error, stackTrace);
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
  }
}
