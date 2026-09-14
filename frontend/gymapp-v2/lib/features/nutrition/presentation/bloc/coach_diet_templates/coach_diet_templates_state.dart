import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_assignment_model.dart';

enum CoachDietTemplatesStatus { initial, loading, success, failure }

class CoachDietTemplatesState extends Equatable {
  final CoachDietTemplatesStatus status;
  final List<DietProgramModel> templates;
  final String? errorMessage;
  final bool isProcessing; // For background actions like assign/delete/unassign
  final Map<int, List<DietAssignmentModel>> templateAssignments;
  final List<DietAssignmentModel> allAssignments;

  const CoachDietTemplatesState({
    this.status = CoachDietTemplatesStatus.initial,
    this.templates = const [],
    this.errorMessage,
    this.isProcessing = false,
    this.templateAssignments = const {},
    this.allAssignments = const [],
  });

  CoachDietTemplatesState copyWith({
    CoachDietTemplatesStatus? status,
    List<DietProgramModel>? templates,
    String? errorMessage,
    bool? isProcessing,
    Map<int, List<DietAssignmentModel>>? templateAssignments,
    List<DietAssignmentModel>? allAssignments,
  }) {
    return CoachDietTemplatesState(
      status: status ?? this.status,
      templates: templates ?? this.templates,
      errorMessage: errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
      templateAssignments: templateAssignments ?? this.templateAssignments,
      allAssignments: allAssignments ?? this.allAssignments,
    );
  }

  @override
  List<Object?> get props => [
        status,
        templates,
        errorMessage,
        isProcessing,
        templateAssignments,
        allAssignments,
      ];
}
