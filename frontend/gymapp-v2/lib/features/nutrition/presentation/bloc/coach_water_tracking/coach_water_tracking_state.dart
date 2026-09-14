import '../../../data/models/client_water_tracking_model.dart';

abstract class CoachWaterTrackingState {}

class CoachWaterTrackingInitial extends CoachWaterTrackingState {}

class CoachWaterTrackingLoading extends CoachWaterTrackingState {}

class CoachWaterTrackingLoaded extends CoachWaterTrackingState {
  final List<ClientWaterTrackingModel> studentWaterIntakes;

  CoachWaterTrackingLoaded(this.studentWaterIntakes);
}

class CoachWaterTrackingError extends CoachWaterTrackingState {
  final String message;

  CoachWaterTrackingError(this.message);
}
