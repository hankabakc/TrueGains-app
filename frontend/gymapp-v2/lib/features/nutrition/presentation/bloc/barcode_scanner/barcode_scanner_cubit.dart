import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'barcode_scanner_state.dart';

class BarcodeScannerCubit extends Cubit<BarcodeScannerState> {
  final NutritionRepository _repository;

  BarcodeScannerCubit(this._repository) : super(BarcodeScannerInitial());

  Future<void> scanBarcode(String barcode) async {
    emit(BarcodeScannerLoading());
    try {
      final response = await _repository.getFoodByBarcode(barcode);
      if (response.success && response.data != null) {
        emit(BarcodeScannerSuccess(response.data!));
      } else {
        emit(BarcodeScannerError(response.message));
      }
    } catch (e) {
      emit(BarcodeScannerError(friendlyError(e)));
    }
  }
}
