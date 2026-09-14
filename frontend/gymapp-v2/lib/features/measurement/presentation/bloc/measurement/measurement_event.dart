import 'package:equatable/equatable.dart';

abstract class MeasurementEvent extends Equatable {
  const MeasurementEvent();
  @override
  List<Object?> get props => [];
}

class LoadMeasurements extends MeasurementEvent {
  final int? clientId;
  const LoadMeasurements({this.clientId});
  @override
  List<Object?> get props => [clientId];
}

class DeleteMeasurement extends MeasurementEvent {
  final int id;
  const DeleteMeasurement(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleSelectionMode extends MeasurementEvent {}

class ToggleMeasurementSelection extends MeasurementEvent {
  final int id;
  const ToggleMeasurementSelection(this.id);
  @override
  List<Object?> get props => [id];
}

class ShareSelectedMeasurements extends MeasurementEvent {}
