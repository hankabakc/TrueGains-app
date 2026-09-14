import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/training/repository/training_repository.dart';
import 'assigned_programs_state.dart';

/// Koç paneli "Atanan Programlar" sekmesinin iş mantığını yöneten Cubit.
class AssignedProgramsCubit extends Cubit<AssignedProgramsState> {

	final TrainingRepository _repository;

	AssignedProgramsCubit(this._repository) : super(const AssignedProgramsState());

	/// Koçun aktif atamalarını backend'den yükler.
	Future<void> loadAssignedPrograms() async {
		emit(state.copyWith(status: AssignedProgramsStatus.loading));

		final result = await _repository.getAssignedProgramsV2();

		if (result.success) {
			emit(state.copyWith(
				status: AssignedProgramsStatus.success,
				programs: result.data ?? [],
			));
		}
		else {
			emit(state.copyWith(
				status: AssignedProgramsStatus.failure,
				error: result.message,
			));
		}
	}

	/// Belirli bir sporcudan program atamasını kaldırır.
	/// Başarılı işlem sonrası listeyi otomatik olarak yeniler.
	Future<void> unassignProgram(int programId, int studentId) async {
		final result = await _repository.unassignProgram(programId, studentId);

		if (result.success) {
			// Başarılı silme sonrası listeyi tekrar yükle
			await loadAssignedPrograms();
		}
		else {
			emit(state.copyWith(
				status: AssignedProgramsStatus.failure,
				error: result.message,
			));
		}
	}

}
