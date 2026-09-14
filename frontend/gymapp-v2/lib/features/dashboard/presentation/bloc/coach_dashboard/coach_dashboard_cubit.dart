import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/coach_dashboard_stats.dart';
import '../../../../finance/repository/finance_repository.dart';

class CoachDashboardState {
  final bool isLoading;
  final CoachDashboardStats? stats;
  final String? error;

  const CoachDashboardState({
    this.isLoading = false,
    this.stats,
    this.error,
  });

  CoachDashboardState copyWith({
    bool? isLoading,
    CoachDashboardStats? stats,
    String? error,
  }) {
    return CoachDashboardState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      error: error ?? this.error,
    );
  }
}

class CoachDashboardCubit extends Cubit<CoachDashboardState> {
  final FinanceRepository _repository;

  CoachDashboardCubit(this._repository) : super(const CoachDashboardState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    final response = await _repository.getCoachDashboardStats();
    if (response.success && response.data != null) {
      emit(state.copyWith(isLoading: false, stats: response.data, error: null));
    } else {
      emit(state.copyWith(isLoading: false, error: response.message));
    }
  }
}
