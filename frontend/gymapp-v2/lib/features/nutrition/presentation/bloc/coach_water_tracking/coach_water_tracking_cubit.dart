import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import '../../../data/repositories/nutrition_repository.dart';
import 'coach_water_tracking_state.dart';

class CoachWaterTrackingCubit extends Cubit<CoachWaterTrackingState> {
  final NutritionRepository _nutritionRepository;

  CoachWaterTrackingCubit({
    required NutritionRepository nutritionRepository,
  })  : _nutritionRepository = nutritionRepository,
        super(CoachWaterTrackingInitial());

  Future<void> loadStudentWaterIntakes() async {
    emit(CoachWaterTrackingLoading());
    try {
      final response = await _nutritionRepository.getCoachStudentsWaterIntake();
      if (response.success && response.data != null) {
        emit(CoachWaterTrackingLoaded(response.data!));
      } else {
        emit(CoachWaterTrackingError(response.message));
      }
    } catch (e) {
      emit(CoachWaterTrackingError(friendlyError(e)));
    }
  }
}
