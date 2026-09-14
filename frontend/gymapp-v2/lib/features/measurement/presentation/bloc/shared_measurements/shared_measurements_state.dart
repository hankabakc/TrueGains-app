import 'package:equatable/equatable.dart';
import '../../../models/client_measurements_summary.dart';

abstract class SharedMeasurementsState extends Equatable {
  const SharedMeasurementsState();
  @override
  List<Object?> get props => [];
}

class SharedMeasurementsInitial extends SharedMeasurementsState {}

class SharedMeasurementsLoading extends SharedMeasurementsState {}

class SharedMeasurementsLoaded extends SharedMeasurementsState {
  final List<ClientMeasurementsSummary> summaries;
  const SharedMeasurementsLoaded(this.summaries);
  @override
  List<Object?> get props => [summaries];
}

class SharedMeasurementsError extends SharedMeasurementsState {
  final String message;
  const SharedMeasurementsError(this.message);
  @override
  List<Object?> get props => [message];
}
