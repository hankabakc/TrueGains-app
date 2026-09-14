import 'package:equatable/equatable.dart';

class SaveRecipeModalState extends Equatable {
  final int selectedDayIndex;

  const SaveRecipeModalState({this.selectedDayIndex = 0});

  SaveRecipeModalState copyWith({int? selectedDayIndex}) {
    return SaveRecipeModalState(
      selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
    );
  }

  @override
  List<Object?> get props => [selectedDayIndex];
}
