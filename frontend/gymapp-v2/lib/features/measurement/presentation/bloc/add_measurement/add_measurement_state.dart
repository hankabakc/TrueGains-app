import 'package:equatable/equatable.dart';

class AddMeasurementState extends Equatable {
  final bool isSaving;
  final String? error;
  final bool isSuccess;
  final Map<String, dynamic>? initialData;

  const AddMeasurementState({
    this.isSaving = false,
    this.error,
    this.isSuccess = false,
    this.initialData,
  });

  AddMeasurementState copyWith({
    bool? isSaving,
    String? error,
    bool? isSuccess,
    Map<String, dynamic>? initialData,
  }) {
    return AddMeasurementState(
      isSaving: isSaving ?? this.isSaving,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
      initialData: initialData ?? this.initialData,
    );
  }

  @override
  List<Object?> get props => [isSaving, error, isSuccess, initialData];
}
