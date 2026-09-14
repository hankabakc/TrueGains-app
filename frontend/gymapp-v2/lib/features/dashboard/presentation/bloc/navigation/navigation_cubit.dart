import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/navigation/last_route_store.dart';

class NavigationCubit extends Cubit<int> {
  final LastRouteStore _store;

  NavigationCubit(this._store) : super(_store.readTabIndex());

  void setPage(int index) {
    _store.saveTabIndex(index);
    emit(index);
  }
}
