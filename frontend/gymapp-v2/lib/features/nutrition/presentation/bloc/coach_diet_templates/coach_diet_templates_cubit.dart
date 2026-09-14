import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_assignment_model.dart';
import 'coach_diet_templates_state.dart';

class CoachDietTemplatesCubit extends Cubit<CoachDietTemplatesState> {
  final NutritionRepository _repository;

  CoachDietTemplatesCubit(this._repository) : super(const CoachDietTemplatesState());

  Future<void> loadTemplates() async {
    emit(state.copyWith(status: CoachDietTemplatesStatus.loading));
    final resp = await _repository.getCoachDietTemplates();

    if (resp.success && resp.data != null) {
      emit(state.copyWith(
        status: CoachDietTemplatesStatus.success,
        templates: resp.data,
      ));
    } else {
      emit(state.copyWith(
        status: CoachDietTemplatesStatus.failure,
        errorMessage: resp.message,
      ));
    }
  }

  Future<void> loadTemplatesWithAssignments() async {
    emit(state.copyWith(status: CoachDietTemplatesStatus.loading));
    final resp = await _repository.getCoachDietTemplates();

    if (resp.success && resp.data != null) {
      emit(state.copyWith(
        status: CoachDietTemplatesStatus.success,
        templates: resp.data,
      ));
      for (final template in resp.data!) {
        await loadAssignments(template.id);
      }
      await loadAllAssignments();
    } else {
      emit(state.copyWith(
        status: CoachDietTemplatesStatus.failure,
        errorMessage: resp.message,
      ));
    }
  }

  Future<void> createTemplate(String name) async {
    emit(state.copyWith(isProcessing: true));
    final resp = await _repository.createDietTemplate(name);

    if (resp.success && resp.data != null) {
      final updatedTemplates = List<DietProgramModel>.from(state.templates)..insert(0, resp.data!);
      emit(state.copyWith(
        templates: updatedTemplates,
        isProcessing: false,
      ));
    } else {
      emit(state.copyWith(
        errorMessage: resp.message,
        isProcessing: false,
      ));
    }
  }

  Future<void> deleteTemplate(int templateId) async {
    emit(state.copyWith(isProcessing: true));
    final resp = await _repository.deleteProgram(templateId);

    if (resp.success) {
      final updatedTemplates = state.templates.where((t) => t.id != templateId).toList();
      emit(state.copyWith(
        templates: updatedTemplates,
        isProcessing: false,
      ));
    } else {
      emit(state.copyWith(
        errorMessage: resp.message,
        isProcessing: false,
      ));
    }
  }

  Future<bool> assignTemplate(int templateId, int clientId) async {
    emit(state.copyWith(isProcessing: true));
    final resp = await _repository.assignDietTemplate(templateId, clientId);

    if (resp.success) {
      emit(state.copyWith(isProcessing: false));
      return true;
    } else {
      emit(state.copyWith(
        errorMessage: resp.message,
        isProcessing: false,
      ));
      return false;
    }
  }

  Future<void> loadAssignments(int templateId) async {
    final resp = await _repository.getTemplateAssignments(templateId);

    if (resp.success && resp.data != null) {
      final updatedAssignments = Map<int, List<DietAssignmentModel>>.from(state.templateAssignments)
        ..[templateId] = resp.data!;
      emit(state.copyWith(
        templateAssignments: updatedAssignments,
      ));
    } else {
      emit(state.copyWith(
        errorMessage: resp.message,
      ));
    }
  }

  Future<bool> unassignTemplate(int templateId, int clientId) async {
    emit(state.copyWith(isProcessing: true));
    final resp = await _repository.unassignTemplate(templateId, clientId);

    if (resp.success) {
      final currentList = state.templateAssignments[templateId] ?? [];
      final DietAssignmentModel? targetAssignment = currentList.where((a) => a.studentId == clientId).firstOrNull;
      final updatedList = currentList.where((a) => a.studentId != clientId).toList();
      final updatedAssignments = Map<int, List<DietAssignmentModel>>.from(state.templateAssignments)
        ..[templateId] = updatedList;

      List<DietAssignmentModel> updatedAllAssignments = state.allAssignments;
      if (targetAssignment != null) {
        updatedAllAssignments = state.allAssignments
            .where((a) => a.assignmentId != targetAssignment.assignmentId)
            .toList();
      }

      emit(state.copyWith(
        templateAssignments: updatedAssignments,
        allAssignments: updatedAllAssignments,
        isProcessing: false,
      ));
      return true;
    } else {
      emit(state.copyWith(
        errorMessage: resp.message,
        isProcessing: false,
      ));
      return false;
    }
  }

  Future<bool> deleteAssignment(int assignmentId) async {
    emit(state.copyWith(isProcessing: true));
    final resp = await _repository.deleteProgram(assignmentId);

    if (resp.success) {
      final updatedAllAssignments = state.allAssignments
          .where((a) => a.assignmentId != assignmentId)
          .toList();
      final updatedAssignments = state.templateAssignments.map((key, list) {
        return MapEntry(key, list.where((a) => a.assignmentId != assignmentId).toList());
      });

      emit(state.copyWith(
        allAssignments: updatedAllAssignments,
        templateAssignments: updatedAssignments,
        isProcessing: false,
      ));
      return true;
    } else {
      emit(state.copyWith(
        errorMessage: resp.message,
        isProcessing: false,
      ));
      return false;
    }
  }

  Future<void> loadAllAssignments() async {
    final resp = await _repository.fetchDietAssignments();

    if (resp.success && resp.data != null) {
      emit(state.copyWith(
        allAssignments: resp.data,
      ));
    } else {
      emit(state.copyWith(
        errorMessage: resp.message,
      ));
    }
  }
}
