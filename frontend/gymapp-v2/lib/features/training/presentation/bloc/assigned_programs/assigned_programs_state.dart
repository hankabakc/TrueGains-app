import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/training/models/assigned_program_models.dart';

/// Atanmış programların listelenme durumlarını temsil eden enum.
enum AssignedProgramsStatus { initial, loading, success, failure }

/// AssignedProgramsCubit için durum sınıfı.
/// Equatable kullanılarak gereksiz UI render işlemleri önlenir.
class AssignedProgramsState extends Equatable {

	final AssignedProgramsStatus status;

	final List<ProgramWithAssignments> programs;

	final String? error;

	const AssignedProgramsState({
		this.status = AssignedProgramsStatus.initial,
		this.programs = const [],
		this.error,
	});

	AssignedProgramsState copyWith({
		AssignedProgramsStatus? status,
		List<ProgramWithAssignments>? programs,
		String? error,
	}) {
		return AssignedProgramsState(
			status: status ?? this.status,
			programs: programs ?? this.programs,
			error: error ?? this.error,
		);
	}

	@override
	List<Object?> get props => [status, programs, error];

}
