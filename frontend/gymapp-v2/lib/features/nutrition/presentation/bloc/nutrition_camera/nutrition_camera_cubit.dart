import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'nutrition_camera_state.dart';

class NutritionCameraCubit extends Cubit<NutritionCameraState> {
  final NutritionRepository _repository;
  final ImagePicker _picker = ImagePicker();
  bool _isPicking = false;

  NutritionCameraCubit(this._repository) : super(const NutritionCameraState());

  Future<void> pickAndAnalyze(ImageSource source) async {
    if (_isPicking) return;
    _isPicking = true;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image == null) return;

      emit(state.copyWith(
        status: NutritionCameraStatus.analyzing,
        loadingMessage: 'Gemini 1.5 Flash devrede...\nBesin değerleri okunuyor...',
      ));

      final response = await _repository.scanFoodImage(image);

      if (response.success && response.data != null) {
        emit(state.copyWith(status: NutritionCameraStatus.success, scanResult: response.data));
      } else {
        emit(state.copyWith(status: NutritionCameraStatus.failure, error: response.message));
      }
    } catch (e) {
      emit(state.copyWith(status: NutritionCameraStatus.failure, error: friendlyError(e)));
    } finally {
      _isPicking = false;
    }
  }

  void reset() {
    emit(const NutritionCameraState());
  }
}
