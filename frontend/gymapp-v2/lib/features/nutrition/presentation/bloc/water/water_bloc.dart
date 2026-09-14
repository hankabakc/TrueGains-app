import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/water_intake_model.dart';
import '../../../data/repositories/nutrition_repository.dart';

// Events
abstract class WaterEvent extends Equatable {
  const WaterEvent();
  @override
  List<Object?> get props => [];
}

class LoadWaterSummary extends WaterEvent {
  final DateTime? date;
  const LoadWaterSummary({this.date});
  @override
  List<Object?> get props => [date];
}

class AddWaterIntake extends WaterEvent {
  final int amountMl;
  const AddWaterIntake(this.amountMl);
  @override
  List<Object?> get props => [amountMl];
}

class UpdateWaterTarget extends WaterEvent {
  final int targetMl;
  const UpdateWaterTarget(this.targetMl);
  @override
  List<Object?> get props => [targetMl];
}

class AddCustomGlass extends WaterEvent {
  final String name;
  final int sizeMl;
  const AddCustomGlass(this.name, this.sizeMl);
  @override
  List<Object?> get props => [name, sizeMl];
}

class DeleteCustomGlass extends WaterEvent {
  final int id;
  const DeleteCustomGlass(this.id);
  @override
  List<Object?> get props => [id];
}

class DeleteWaterIntake extends WaterEvent {
  final int id;
  const DeleteWaterIntake(this.id);
  @override
  List<Object?> get props => [id];
}

// State
abstract class WaterState extends Equatable {
  const WaterState();
  @override
  List<Object?> get props => [];
}

class WaterInitial extends WaterState {}

class WaterLoading extends WaterState {}

class WaterLoaded extends WaterState {
  final WaterDailySummaryModel summary;
  final List<WaterDailyTotalModel> history;

  const WaterLoaded(this.summary, {this.history = const []});

  @override
  List<Object?> get props => [summary, history];
}

class WaterError extends WaterState {
  final String message;
  const WaterError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class WaterBloc extends Bloc<WaterEvent, WaterState> {
  final NutritionRepository _repository;

  WaterBloc(this._repository) : super(WaterInitial()) {
    on<LoadWaterSummary>(_onLoadSummary);
    on<AddWaterIntake>(_onAddIntake);
    on<UpdateWaterTarget>(_onUpdateTarget);
    on<AddCustomGlass>(_onAddCustomGlass);
    on<DeleteCustomGlass>(_onDeleteCustomGlass);
    on<DeleteWaterIntake>(_onDeleteWaterIntake);
  }

  Future<void> _onLoadSummary(
    LoadWaterSummary event,
    Emitter<WaterState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WaterLoaded) {
      emit(WaterLoading());
    }

    final date = event.date ?? DateTime.now();
    final summaryResult = await _repository.getDailyWaterSummary(date);

    if (summaryResult.success) {
      final end = date;
      // Son 30 günlük veriyi çek
      final start = date.subtract(const Duration(days: 30));
      final historyResult = await _repository.getWaterRangeSummary(start, end);

      emit(
        WaterLoaded(
          summaryResult.data!,
          history: historyResult.success ? historyResult.data! : [],
        ),
      );
    } else {
      if (currentState is WaterLoaded) {
        emit(WaterError(summaryResult.message));
        emit(currentState);
      } else {
        emit(WaterError(summaryResult.message));
      }
    }
  }

  Future<void> _onAddIntake(
    AddWaterIntake event,
    Emitter<WaterState> emit,
  ) async {
    final currentState = state;
    final result = await _repository.addWater(event.amountMl);
    if (result.success) {
      add(const LoadWaterSummary());
    } else if (currentState is WaterLoaded) {
      // Eğer hata alırsak ama zaten verimiz varsa, kullanıcıya hatayı dilersek bir snackbar ile gösterebiliriz
      // Şimdilik state'i bozmuyoruz
      emit(WaterError(result.message));
      emit(currentState); // Tekrar eski veriyi göster
    } else {
      emit(WaterError(result.message));
    }
  }

  Future<void> _onUpdateTarget(
    UpdateWaterTarget event,
    Emitter<WaterState> emit,
  ) async {
    final currentState = state;
    final result = await _repository.updateWaterTarget(event.targetMl);
    if (result.success) {
      add(const LoadWaterSummary());
    } else if (currentState is WaterLoaded) {
      emit(WaterError(result.message));
      emit(currentState);
    } else {
      emit(WaterError(result.message));
    }
  }

  Future<void> _onAddCustomGlass(
    AddCustomGlass event,
    Emitter<WaterState> emit,
  ) async {
    final currentState = state;
    final result = await _repository.addCustomGlass(event.name, event.sizeMl);
    if (result.success) {
      add(const LoadWaterSummary());
    } else if (currentState is WaterLoaded) {
      emit(WaterError(result.message));
      emit(currentState);
    } else {
      emit(WaterError(result.message));
    }
  }

  Future<void> _onDeleteCustomGlass(
    DeleteCustomGlass event,
    Emitter<WaterState> emit,
  ) async {
    final currentState = state;
    final result = await _repository.deleteCustomGlass(event.id);
    if (result.success) {
      add(const LoadWaterSummary());
    } else if (currentState is WaterLoaded) {
      emit(WaterError(result.message));
      emit(currentState);
    } else {
      emit(WaterError(result.message));
    }
  }

  Future<void> _onDeleteWaterIntake(
    DeleteWaterIntake event,
    Emitter<WaterState> emit,
  ) async {
    final currentState = state;
    final result = await _repository.deleteWaterIntake(event.id);
    if (result.success) {
      add(const LoadWaterSummary());
    } else if (currentState is WaterLoaded) {
      emit(WaterError(result.message));
      emit(currentState);
    } else {
      emit(WaterError(result.message));
    }
  }
}
