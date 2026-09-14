import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_source.dart';
import 'diet_program_selection_state.dart';

class DietProgramSelectionCubit extends Cubit<DietProgramSelectionState> {
  final NutritionRepository _repository;

  DietProgramSelectionCubit(this._repository) : super(const DietProgramSelectionState());

  void setPage(int page) => emit(state.copyWith(currentPage: page));

  Future<void> loadPrograms(DietSource sourceFilter) async {
    emit(state.copyWith(status: DietProgramSelectionStatus.loading));
    final resp = await _repository.getMyPrograms();

    if (resp.success && resp.data != null) {
      var programs = resp.data!.where((p) => p.source == sourceFilter).toList();
      programs.sort((a, b) {
        if (a.isMain && !b.isMain) return -1;
        if (!a.isMain && b.isMain) return 1;
        return 0;
      });
      emit(state.copyWith(status: DietProgramSelectionStatus.success, programs: programs));
    } else {
      emit(state.copyWith(status: DietProgramSelectionStatus.failure, error: resp.message));
    }
  }

  Future<void> deleteProgram(int programId) async {
    final resp = await _repository.deleteProgram(programId);
    if (resp.success) {
      final updatedPrograms = state.programs.where((p) => p.id != programId).toList();
      emit(state.copyWith(programs: updatedPrograms));
    } else {
      emit(state.copyWith(error: resp.message));
    }
  }

  Future<void> activateProgram(int programId, DietSource sourceFilter) async {
    final resp = await _repository.activateProgram(programId);
    if (resp.success) {
      await loadPrograms(sourceFilter);
    } else {
      emit(state.copyWith(error: resp.message));
    }
  }

  Future<void> approveOrphaned(int programId, bool keep, DietSource sourceFilter) async {
    final resp = await _repository.approveOrphan(programId, keep);
    if (resp.success) {
      await loadPrograms(sourceFilter);
    } else {
      emit(state.copyWith(error: resp.message));
    }
  }

  Future<DietProgramModel?> createProgram(String name, DietSource sourceFilter) async {
    final resp = await _repository.createProgram(name, false);
    if (resp.success && resp.data != null) {
      final newProgram = resp.data!;

      // Inherit goals from main program
      try {
        final mainProgram = state.programs.firstWhere((p) => p.isMain);
        await _repository.updateProgramGoals(
          newProgram.id,
          targetCalories: mainProgram.targetCalories,
          targetProtein: mainProgram.targetProtein,
          targetCarbs: mainProgram.targetCarbs,
          targetFat: mainProgram.targetFat,
          targetSugar: mainProgram.targetSugar,
          targetFiber: mainProgram.targetFiber,
          targetSodium: mainProgram.targetSodium,
          targetCholesterol: mainProgram.targetCholesterol,
          targetPotassium: mainProgram.targetPotassium,
        );
      } catch (_) {}

      await loadPrograms(sourceFilter);
      return newProgram;
    } else {
      emit(state.copyWith(error: resp.message));
      return null;
    }
  }
}
