import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';
import 'package:gymapp_v2/features/training/models/exercise.dart';

enum CreatePersonalProgramStatus { initial, loading, success, failure }

class CreatePersonalProgramState extends Equatable {
  final CreatePersonalProgramStatus status;
  final List<WorkoutDay> draftDays;
  final List<bool> isOffDays;
  final List<bool> isMagnetEnabled;
  final List<Set<String>> expandedGroups;
  final int selectedDayIndex;
  final List<Exercise> allExercises;
  final bool isLoadingExercises;
  final String? error;

  final bool isTemplate;
  final int? editingProgramId;
  final int durationWeeks;

  const CreatePersonalProgramState({
    this.status = CreatePersonalProgramStatus.initial,
    this.draftDays = const [],
    this.isOffDays = const [],
    this.isMagnetEnabled = const [],
    this.expandedGroups = const [],
    this.selectedDayIndex = 0,
    this.allExercises = const [],
    this.isLoadingExercises = true,
    this.isTemplate = false,
    this.editingProgramId,
    this.durationWeeks = 4,
    this.error,
  });

  CreatePersonalProgramState copyWith({
    CreatePersonalProgramStatus? status,
    List<WorkoutDay>? draftDays,
    List<bool>? isOffDays,
    List<bool>? isMagnetEnabled,
    List<Set<String>>? expandedGroups,
    int? selectedDayIndex,
    List<Exercise>? allExercises,
    bool? isLoadingExercises,
    bool? isTemplate,
    int? editingProgramId,
    int? durationWeeks,
    String? error,
  }) {
    return CreatePersonalProgramState(
      status: status ?? this.status,
      draftDays: draftDays ?? this.draftDays,
      isOffDays: isOffDays ?? this.isOffDays,
      isMagnetEnabled: isMagnetEnabled ?? this.isMagnetEnabled,
      expandedGroups: expandedGroups ?? this.expandedGroups,
      selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
      allExercises: allExercises ?? this.allExercises,
      isLoadingExercises: isLoadingExercises ?? this.isLoadingExercises,
      isTemplate: isTemplate ?? this.isTemplate,
      editingProgramId: editingProgramId ?? this.editingProgramId,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        draftDays,
        isOffDays,
        isMagnetEnabled,
        expandedGroups,
        selectedDayIndex,
        allExercises,
        isLoadingExercises,
        isTemplate,
        editingProgramId,
        durationWeeks,
        error,
      ];
}
