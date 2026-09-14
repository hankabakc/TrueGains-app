import 'package:equatable/equatable.dart';

class WaterAnalysisState extends Equatable {
  final bool isWeeklyView;
  final bool isLogsExpanded;

  const WaterAnalysisState({
    this.isWeeklyView = true,
    this.isLogsExpanded = false,
  });

  WaterAnalysisState copyWith({
    bool? isWeeklyView,
    bool? isLogsExpanded,
  }) {
    return WaterAnalysisState(
      isWeeklyView: isWeeklyView ?? this.isWeeklyView,
      isLogsExpanded: isLogsExpanded ?? this.isLogsExpanded,
    );
  }

  @override
  List<Object?> get props => [isWeeklyView, isLogsExpanded];
}
