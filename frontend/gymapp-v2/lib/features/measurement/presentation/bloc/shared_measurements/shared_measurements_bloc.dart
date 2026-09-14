import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import '../../../repository/measurement_repository.dart';
import 'shared_measurements_event.dart';
import 'shared_measurements_state.dart';

class SharedMeasurementsBloc
    extends Bloc<SharedMeasurementsEvent, SharedMeasurementsState> {
  final MeasurementRepository _repository;

  SharedMeasurementsBloc(this._repository) : super(SharedMeasurementsInitial()) {
    on<LoadSharedMeasurements>(_onLoadSharedMeasurements);
  }

  Future<void> _onLoadSharedMeasurements(
    LoadSharedMeasurements event,
    Emitter<SharedMeasurementsState> emit,
  ) async {
    emit(SharedMeasurementsLoading());
    try {
      final summaries = await _repository.getSharedMeasurements();
      emit(SharedMeasurementsLoaded(summaries));
    } catch (e) {
      emit(SharedMeasurementsError(friendlyError(e)));
    }
  }
}
