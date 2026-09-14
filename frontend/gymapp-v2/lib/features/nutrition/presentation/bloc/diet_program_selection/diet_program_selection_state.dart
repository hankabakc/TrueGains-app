import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';

enum DietProgramSelectionStatus { initial, loading, success, failure }

class DietProgramSelectionState extends Equatable {
  final DietProgramSelectionStatus status;
  final List<DietProgramModel> programs;
  final int currentPage;
  final String? error;

  const DietProgramSelectionState({
    this.status = DietProgramSelectionStatus.initial,
    this.programs = const [],
    this.currentPage = 0,
    this.error,
  });

  DietProgramSelectionState copyWith({
    DietProgramSelectionStatus? status,
    List<DietProgramModel>? programs,
    int? currentPage,
    String? error,
  }) {
    return DietProgramSelectionState(
      status: status ?? this.status,
      programs: programs ?? this.programs,
      currentPage: currentPage ?? this.currentPage,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, programs, currentPage, error];
}
