import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import '../../../repository/measurement_repository.dart';
import 'measurement_event.dart';
import 'measurement_state.dart';

class MeasurementBloc extends Bloc<MeasurementEvent, MeasurementState> {
  final MeasurementRepository _repository;

  MeasurementBloc(this._repository) : super(MeasurementInitial()) {
    on<LoadMeasurements>(_onLoadMeasurements);
    on<DeleteMeasurement>(_onDeleteMeasurement);
    on<ToggleSelectionMode>(_onToggleSelectionMode);
    on<ToggleMeasurementSelection>(_onToggleMeasurementSelection);
    on<ShareSelectedMeasurements>(_onShareSelectedMeasurements);
  }

  Future<void> _onLoadMeasurements(
    LoadMeasurements event,
    Emitter<MeasurementState> emit,
  ) async {
    emit(MeasurementLoading());
    try {
      final measurements = await _repository.getMyMeasurements(clientId: event.clientId);
      emit(MeasurementLoaded(measurements: measurements));
    } catch (e) {
      emit(MeasurementError(friendlyError(e)));
    }
  }

  Future<void> _onDeleteMeasurement(
    DeleteMeasurement event,
    Emitter<MeasurementState> emit,
  ) async {
    final MeasurementState currentState = state;
    try {
      await _repository.deleteMeasurement(event.id);
      add(const LoadMeasurements());
    } catch (e) {
      // Silme hatası ekrandaki listeyi düşürmemeli: kullanıcı bir silme denemesi
      // başarısız oldu diye tüm ölçüm geçmişini kaybediyordu. Paylaşım hatasıyla
      // aynı desen — hata Loaded içinde taşınır, snackbar'da gösterilir.
      if (currentState is MeasurementLoaded) {
        emit(currentState.copyWith(deleteError: friendlyError(e)));
      } else {
        emit(MeasurementError(friendlyError(e)));
      }
    }
  }

  void _onToggleSelectionMode(
    ToggleSelectionMode event,
    Emitter<MeasurementState> emit,
  ) {
    if (state is MeasurementLoaded) {
      final currentState = state as MeasurementLoaded;
      emit(
        currentState.copyWith(
          isSelectionMode: !currentState.isSelectionMode,
          selectedIds: {}, // Mod değişince seçilenleri sıfırla
        ),
      );
    }
  }

  void _onToggleMeasurementSelection(
    ToggleMeasurementSelection event,
    Emitter<MeasurementState> emit,
  ) {
    if (state is MeasurementLoaded) {
      final currentState = state as MeasurementLoaded;
      final newSelectedIds = Set<int>.from(currentState.selectedIds);
      if (newSelectedIds.contains(event.id)) {
        newSelectedIds.remove(event.id);
      } else {
        newSelectedIds.add(event.id);
      }
      emit(currentState.copyWith(selectedIds: newSelectedIds));
    }
  }

  Future<void> _onShareSelectedMeasurements(
    ShareSelectedMeasurements event,
    Emitter<MeasurementState> emit,
  ) async {
    if (state is MeasurementLoaded) {
      final currentState = state as MeasurementLoaded;
      if (currentState.selectedIds.isEmpty) return;

      emit(currentState.copyWith(isSharing: true, shareError: null));
      try {
        await _repository.shareMeasurements(currentState.selectedIds.toList());
        final updated = currentState.measurements
            .map((m) => currentState.selectedIds.contains(m.id)
                ? m.copyWith(isSharedWithCoach: true)
                : m)
            .toList();
        emit(
          currentState.copyWith(
            measurements: updated,
            isSharing: false,
            isSelectionMode: false,
            selectedIds: {},
            shareSuccess: true,
          ),
        );
      } catch (e) {
        emit(currentState.copyWith(isSharing: false, shareError: friendlyError(e)));
      }
    }
  }
}
