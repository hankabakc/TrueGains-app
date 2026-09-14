import 'package:flutter_bloc/flutter_bloc.dart';

class LoginFormState {
  final bool isPasswordVisible;
  LoginFormState({this.isPasswordVisible = false});
}

class LoginFormCubit extends Cubit<LoginFormState> {
  LoginFormCubit() : super(LoginFormState());

  void togglePasswordVisibility() {
    emit(LoginFormState(isPasswordVisible: !state.isPasswordVisible));
  }
}
