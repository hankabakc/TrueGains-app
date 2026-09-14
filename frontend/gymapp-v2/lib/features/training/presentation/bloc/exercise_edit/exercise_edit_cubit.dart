import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class ExerciseEditState extends Equatable {
  final bool isToFailure;

  const ExerciseEditState({required this.isToFailure});

  ExerciseEditState copyWith({bool? isToFailure}) {
    return ExerciseEditState(isToFailure: isToFailure ?? this.isToFailure);
  }

  @override
  List<Object?> get props => [isToFailure];
}

class ExerciseEditCubit extends Cubit<ExerciseEditState> {
  ExerciseEditCubit(bool initialIsToFailure) : super(ExerciseEditState(isToFailure: initialIsToFailure));

  void toggleFailure(bool value) => emit(state.copyWith(isToFailure: value));
}
