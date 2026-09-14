import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import 'package:gymapp_v2/features/measurement/models/measurement.dart';
import 'package:gymapp_v2/features/measurement/repository/measurement_repository.dart';
import 'add_measurement_state.dart';

class AddMeasurementCubit extends Cubit<AddMeasurementState> {
  final MeasurementRepository _repository;

  AddMeasurementCubit(this._repository) : super(const AddMeasurementState());

  Future<void> loadTodayData() async {
    try {
      final todayRecord = await _repository.getTodayMeasurement();
      if (todayRecord != null) {
        emit(state.copyWith(initialData: {
          'weight': todayRecord.weight?.toString() ?? '',
          'height': todayRecord.height?.toString() ?? '',
          'bodyFatPct': todayRecord.bodyFatPct?.toString() ?? '',
          'muscleMass': todayRecord.muscleMass?.toString() ?? '',
          'chest': todayRecord.chest?.toString() ?? '',
          'waist': todayRecord.waist?.toString() ?? '',
          'shoulders': todayRecord.shoulders?.toString() ?? '',
          'leftArm': todayRecord.leftArm?.toString() ?? '',
          'rightArm': todayRecord.rightArm?.toString() ?? '',
          'leftLeg': todayRecord.leftLeg?.toString() ?? '',
          'rightLeg': todayRecord.rightLeg?.toString() ?? '',
          'hips': todayRecord.hips?.toString() ?? '',
          'notes': todayRecord.notes ?? '',
        }));
      }
    } catch (e) {
      // Ignore error for initial load
    }
  }

  Future<void> saveMeasurement(Map<String, dynamic> data) async {
    emit(state.copyWith(isSaving: true, error: null));
    try {
      await _repository.addMeasurement(Measurement.fromJson(data));
      emit(state.copyWith(isSaving: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: friendlyError(e)));
    }
  }
}
