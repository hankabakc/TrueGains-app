import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/training/models/weekly_progress.dart';
import 'package:gymapp_v2/features/training/repository/training_repository.dart';
import 'package:gymapp_v2/core/network/error_message.dart';

// States
abstract class WeeklyProgressState {
  const WeeklyProgressState();
}

class WeeklyProgressInitial extends WeeklyProgressState {
  const WeeklyProgressInitial();
}

class WeeklyProgressLoading extends WeeklyProgressState {
  const WeeklyProgressLoading();
}

class WeeklyProgressLoaded extends WeeklyProgressState {
  final WeeklyProgress progress;
  const WeeklyProgressLoaded(this.progress);
}

class WeeklyHistoryLoaded extends WeeklyProgressState {
  final List<WeeklyHistoryItem> history;
  const WeeklyHistoryLoaded(this.history);
}

class WeeklyProgressError extends WeeklyProgressState {
  final String message;
  const WeeklyProgressError(this.message);
}

// Cubit
class WeeklyProgressCubit extends Cubit<WeeklyProgressState> {
  final TrainingRepository _repository;

  WeeklyProgressCubit(this._repository) : super(const WeeklyProgressInitial());

  Future<void> loadMyProgress() async {
    emit(const WeeklyProgressLoading());
    try {
      final response = await _repository.getMyWeeklyProgress();
      if (response.success && response.data != null) {
        emit(WeeklyProgressLoaded(response.data!));
      } else {
        emit(WeeklyProgressError(response.message));
      }
    } catch (e) {
      emit(WeeklyProgressError(friendlyError(e)));
    }
  }

  Future<void> loadClientProgress(int clientId) async {
    emit(const WeeklyProgressLoading());
    try {
      final response = await _repository.getClientWeeklyProgress(clientId);
      if (response.success && response.data != null) {
        emit(WeeklyProgressLoaded(response.data!));
      } else {
        emit(WeeklyProgressError(response.message));
      }
    } catch (e) {
      emit(WeeklyProgressError(friendlyError(e)));
    }
  }

  Future<void> loadMyHistory() async {
    emit(const WeeklyProgressLoading());
    try {
      final response = await _repository.getMyWeeklyHistory();
      if (response.success && response.data != null) {
        emit(WeeklyHistoryLoaded(response.data!));
      } else {
        emit(WeeklyProgressError(response.message));
      }
    } catch (e) {
      emit(WeeklyProgressError(friendlyError(e)));
    }
  }

  Future<void> loadClientHistory(int clientId) async {
    emit(const WeeklyProgressLoading());
    try {
      final response = await _repository.getClientWeeklyHistory(clientId);
      if (response.success && response.data != null) {
        emit(WeeklyHistoryLoaded(response.data!));
      } else {
        emit(WeeklyProgressError(response.message));
      }
    } catch (e) {
      emit(WeeklyProgressError(friendlyError(e)));
    }
  }
}
