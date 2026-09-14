import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/nutrition_dashboard_model.dart';
import '../../../data/repositories/nutrition_repository.dart';

// Events
abstract class NutritionAnalyticsEvent extends Equatable {
  const NutritionAnalyticsEvent();
  @override
  List<Object?> get props => [];
}

class FetchDashboardData extends NutritionAnalyticsEvent {
  final int? programId;
  final int? targetUserId;
  const FetchDashboardData({this.programId, this.targetUserId});

  @override
  List<Object?> get props => [programId, targetUserId];
}

class ToggleDashboardView extends NutritionAnalyticsEvent {
  final bool isPercentageView;
  const ToggleDashboardView(this.isPercentageView);
  @override
  List<Object?> get props => [isPercentageView];
}

class ToggleFoodDetailView extends NutritionAnalyticsEvent {
  final bool showMacros;
  const ToggleFoodDetailView(this.showMacros);
  @override
  List<Object?> get props => [showMacros];
}

// States
abstract class NutritionAnalyticsState extends Equatable {
  const NutritionAnalyticsState();
  @override
  List<Object?> get props => [];
}

class NutritionAnalyticsInitial extends NutritionAnalyticsState {}

class NutritionAnalyticsLoading extends NutritionAnalyticsState {}

class NutritionAnalyticsLoaded extends NutritionAnalyticsState {
  final NutritionDashboardModel dashboardData;
  final bool isPercentageView;
  final bool showMacrosInFoodSummary;

  const NutritionAnalyticsLoaded({
    required this.dashboardData,
    this.isPercentageView = false,
    this.showMacrosInFoodSummary = false,
  });

  NutritionAnalyticsLoaded copyWith({
    NutritionDashboardModel? dashboardData,
    bool? isPercentageView,
    bool? showMacrosInFoodSummary,
  }) {
    return NutritionAnalyticsLoaded(
      dashboardData: dashboardData ?? this.dashboardData,
      isPercentageView: isPercentageView ?? this.isPercentageView,
      showMacrosInFoodSummary: showMacrosInFoodSummary ?? this.showMacrosInFoodSummary,
    );
  }

  @override
  List<Object?> get props => [dashboardData, isPercentageView, showMacrosInFoodSummary];
}

class NutritionAnalyticsError extends NutritionAnalyticsState {
  final String message;
  const NutritionAnalyticsError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class NutritionAnalyticsBloc extends Bloc<NutritionAnalyticsEvent, NutritionAnalyticsState> {
  final NutritionRepository _repository;

  NutritionAnalyticsBloc(this._repository) : super(NutritionAnalyticsInitial()) {
    on<FetchDashboardData>(_onFetchDashboardData);
    on<ToggleDashboardView>(_onToggleDashboardView);
    on<ToggleFoodDetailView>(_onToggleFoodDetailView);
  }

  Future<void> _onFetchDashboardData(
    FetchDashboardData event,
    Emitter<NutritionAnalyticsState> emit,
  ) async {
    emit(NutritionAnalyticsLoading());
    final result = await _repository.getDashboardData(event.programId, event.targetUserId);
    // Veri gelmeden başarı bildirilirse `data!` fırlatır ve hata durumu hiç
    // yayınlanmaz; ekran sonsuza kadar yükleniyor kalır.
    if (result.success && result.data != null) {
      emit(NutritionAnalyticsLoaded(dashboardData: result.data!));
    } else {
      emit(NutritionAnalyticsError(result.message));
    }
  }

  void _onToggleDashboardView(
    ToggleDashboardView event,
    Emitter<NutritionAnalyticsState> emit,
  ) {
    if (state is NutritionAnalyticsLoaded) {
      final currentState = state as NutritionAnalyticsLoaded;
      emit(currentState.copyWith(isPercentageView: event.isPercentageView));
    }
  }

  void _onToggleFoodDetailView(
    ToggleFoodDetailView event,
    Emitter<NutritionAnalyticsState> emit,
  ) {
    if (state is NutritionAnalyticsLoaded) {
      final currentState = state as NutritionAnalyticsLoaded;
      emit(currentState.copyWith(showMacrosInFoodSummary: event.showMacros));
    }
  }
}
