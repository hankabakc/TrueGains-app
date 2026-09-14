import 'package:equatable/equatable.dart';

abstract class SharedMeasurementsEvent extends Equatable {
  const SharedMeasurementsEvent();
  @override
  List<Object?> get props => [];
}

class LoadSharedMeasurements extends SharedMeasurementsEvent {}
