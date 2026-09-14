import 'package:equatable/equatable.dart';
import '../../../models/measurement.dart';

abstract class MeasurementState extends Equatable {
  const MeasurementState();
  @override
  List<Object?> get props => [];
}

class MeasurementInitial extends MeasurementState {}

class MeasurementLoading extends MeasurementState {}

class MeasurementLoaded extends MeasurementState {
  final List<Measurement> measurements;
  final bool isSelectionMode;
  final Set<int> selectedIds;
  final bool isSharing;
  final String? shareError;
  final String? deleteError;
  final bool shareSuccess;

  const MeasurementLoaded({
    required this.measurements,
    this.isSelectionMode = false,
    this.selectedIds = const {},
    this.isSharing = false,
    this.shareError,
    this.deleteError,
    this.shareSuccess = false,
  });

  MeasurementLoaded copyWith({
    List<Measurement>? measurements,
    bool? isSelectionMode,
    Set<int>? selectedIds,
    bool? isSharing,
    String? shareError,
    String? deleteError,
    bool? shareSuccess,
  }) {
    return MeasurementLoaded(
      measurements: measurements ?? this.measurements,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
      isSharing: isSharing ?? this.isSharing,
      shareError: shareError,
      deleteError: deleteError,
      shareSuccess: shareSuccess ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [measurements, isSelectionMode, selectedIds, isSharing, shareError, deleteError, shareSuccess];
}

class MeasurementError extends MeasurementState {
  final String message;
  const MeasurementError(this.message);
  @override
  List<Object?> get props => [message];
}
