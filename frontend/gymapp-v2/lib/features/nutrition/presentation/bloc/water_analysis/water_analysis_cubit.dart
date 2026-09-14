import 'package:flutter_bloc/flutter_bloc.dart';
import 'water_analysis_state.dart';

class WaterAnalysisCubit extends Cubit<WaterAnalysisState> {
  WaterAnalysisCubit() : super(const WaterAnalysisState());

  void setWeeklyView(bool isWeekly) {
    emit(state.copyWith(isWeeklyView: isWeekly));
  }

  void toggleLogsExpanded() {
    emit(state.copyWith(isLogsExpanded: !state.isLogsExpanded));
  }
}
