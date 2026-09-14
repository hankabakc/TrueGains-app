import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';

class DashboardState extends Equatable {
  final TrainingBlock? selectedProgram;
  final int selectedGlassMl;

  const DashboardState({
    this.selectedProgram,
    this.selectedGlassMl = 250,
  });

  DashboardState copyWith({
    TrainingBlock? selectedProgram,
    int? selectedGlassMl,
  }) {
    return DashboardState(
      selectedProgram: selectedProgram ?? this.selectedProgram,
      selectedGlassMl: selectedGlassMl ?? this.selectedGlassMl,
    );
  }

  @override
  List<Object?> get props => [selectedProgram, selectedGlassMl];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(const DashboardState());

  void selectProgram(TrainingBlock program) {
    emit(state.copyWith(selectedProgram: program));
  }

  void selectGlassMl(int ml) {
    emit(state.copyWith(selectedGlassMl: ml));
  }
}
