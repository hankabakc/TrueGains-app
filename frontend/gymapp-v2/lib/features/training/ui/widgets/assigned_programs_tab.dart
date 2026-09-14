import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/network_avatar.dart';
import 'package:gymapp_v2/features/training/bloc/training_bloc.dart';
import 'package:gymapp_v2/features/training/bloc/training_event.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/assigned_programs/assigned_programs_cubit.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/assigned_programs/assigned_programs_state.dart';
import 'package:gymapp_v2/features/training/models/assigned_program_models.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';

/// Koç paneli için atanmış programları hiyerarşik yapıda listeleyen sekme widget'ı.
class AssignedProgramsTab extends StatelessWidget {

	const AssignedProgramsTab({super.key});

	@override
	Widget build(BuildContext context) {
		return BlocProvider(
			create: (context) => sl<AssignedProgramsCubit>()..loadAssignedPrograms(),
			child: const _AssignedProgramsView(),
		);
	}

}

class _AssignedProgramsView extends StatelessWidget {

	const _AssignedProgramsView();

	@override
	Widget build(BuildContext context) {
		return BlocBuilder<AssignedProgramsCubit, AssignedProgramsState>(
			builder: (context, state) {
				if (state.status == AssignedProgramsStatus.loading) {
					return const Center(
						child: CircularProgressIndicator(color: AppColors.primary),
					);
				}

				if (state.status == AssignedProgramsStatus.failure) {
					return Center(
						child: Padding(
							padding: const EdgeInsets.all(24),
							child: Column(
								mainAxisAlignment: MainAxisAlignment.center,
								children: [
									const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
									const SizedBox(height: 16),
									Text(
										state.error ?? 'Veriler yüklenirken hata oluştu.',
										textAlign: TextAlign.center,
										style: const TextStyle(color: Colors.white70),
									),
									TextButton(
										onPressed: () => context.read<AssignedProgramsCubit>().loadAssignedPrograms(),
										child: const Text('Tekrar Dene'),
									),
								],
							),
						),
					);
				}

				if (state.programs.isEmpty) {
					return const _EmptyAssignedState();
				}

				return ListView.builder(
					padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
					itemCount: state.programs.length,
					itemBuilder: (context, index) {
						final program = state.programs[index];
						return _ProgramGroup(program: program);
					},
				);
			},
		);
	}

}

class _ProgramGroup extends StatelessWidget {

	final ProgramWithAssignments program;

	const _ProgramGroup({required this.program});

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Padding(
					padding: const EdgeInsets.fromLTRB(4, 20, 4, 12),
					child: Row(
						children: [
							const Icon(Icons.folder_shared_outlined, color: AppColors.primary, size: 20),
							const SizedBox(width: 8),
							Expanded(
								child: Text(
									program.programName,
									style: const TextStyle(
										color: Colors.white,
										fontSize: 18,
										fontWeight: FontWeight.bold,
										letterSpacing: 0.5,
									),
								),
							),
							Container(
								padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
								decoration: BoxDecoration(
									color: AppColors.primary.withValues(alpha: 0.1),
									borderRadius: BorderRadius.circular(6),
								),
								child: Text(
									'${program.assignedStudents.length} Sporcu',
									style: const TextStyle(
										color: AppColors.primary,
										fontSize: 12,
										fontWeight: FontWeight.w600,
									),
								),
							),
						],
					),
				),
				...program.assignedStudents.map((student) => _StudentCard(
					program: program,
					student: student,
				)),
				const SizedBox(height: 8),
			],
		);
	}

}

class _StudentCard extends StatelessWidget {

	final ProgramWithAssignments program;

	final AssignedStudentSummary student;

	const _StudentCard({required this.program, required this.student});

	@override
	Widget build(BuildContext context) {
		final int haftaDonguIcinde = student.durationWeeks > 0
				? ((student.weeksElapsed - 1) % student.durationWeeks) + 1
				: 1;
		Color progressColor;
		String? statusLabel;
		if (haftaDonguIcinde == student.durationWeeks) {
			progressColor = AppColors.warning;
			statusLabel = 'Son süre yaklaştı';
		} else {
			progressColor = AppColors.primary;
		}

		return GlassContainer(
			margin: const EdgeInsets.only(bottom: 12),
			padding: const EdgeInsets.all(12),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							Expanded(
								child: GestureDetector(
									behavior: HitTestBehavior.opaque,
									onTap: () async {
										final trainingState = context.read<TrainingBloc>().state;
										TrainingBlock? programCopy;
										for (final p in trainingState.assignedPrograms) {
											if (p.id == student.assignedProgramId) {
												programCopy = p;
												break;
											}
										}
										if (programCopy != null) {
											final v = await context.push<dynamic>(
												'/create-personal-program',
												extra: programCopy,
											);
											if (v == true && context.mounted) {
												context.read<TrainingBloc>().add(const LoadCoachAssignedPrograms());
												context.read<AssignedProgramsCubit>().loadAssignedPrograms();
											}
										} else {
											ScaffoldMessenger.of(context).showSnackBar(
												const SnackBar(
													content: Text('Atanan program verisi yüklenemedi. Lütfen sayfayı yenileyin.'),
													backgroundColor: AppColors.error,
												),
											);
										}
									},
									child: Row(
										children: [
											NetworkAvatar(
												imageUrl: student.profileImageUrl,
												fallbackText: student.fullName,
												size: 40,
											),
											const SizedBox(width: 16),
											Expanded(
												child: Column(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														Text(
															student.fullName,
															style: const TextStyle(
																color: Colors.white,
																fontWeight: FontWeight.w600,
																fontSize: 15,
															),
														),
														Text(
															student.isActive ? 'Aktif Program Ataması' : 'Gönderildi (Aktif Değil)',
															style: const TextStyle(
																color: AppColors.textMuted,
																fontSize: 12,
															),
														),
													],
												),
											),
										],
									),
								),
							),
							IconButton(
								icon: const Icon(Icons.person_remove_outlined, color: AppColors.error, size: 22),
								tooltip: 'Atamayı Kaldır',
								onPressed: () => _showUnassignConfirm(context),
							),
						],
					),
					const SizedBox(height: 12),
					Padding(
						padding: const EdgeInsets.symmetric(horizontal: 4),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Row(
									mainAxisAlignment: MainAxisAlignment.spaceBetween,
									children: [
										const Text(
											'SÜRE',
											style: TextStyle(
												color: AppColors.textMuted,
												fontSize: 12,
												fontWeight: FontWeight.w600,
											),
										),
										Text(
											'Hafta $haftaDonguIcinde / ${student.durationWeeks}',
											style: const TextStyle(
												color: Colors.white70,
												fontSize: 12,
												fontWeight: FontWeight.w600,
											),
										),
									],
								),
								const SizedBox(height: AppSpacing.xs),
								ClipRRect(
									borderRadius: BorderRadius.circular(4),
									child: LinearProgressIndicator(
										value: (student.durationWeeks > 0) ? (haftaDonguIcinde / student.durationWeeks) : 0.0,
										backgroundColor: Colors.white.withValues(alpha: 0.05),
										valueColor: AlwaysStoppedAnimation<Color>(progressColor),
										minHeight: 6,
									),
								),
								const SizedBox(height: AppSpacing.xs),
								Row(
									mainAxisAlignment: MainAxisAlignment.spaceBetween,
									children: [
										if (statusLabel != null)
											Text(
												statusLabel,
												style: TextStyle(
													color: progressColor,
													fontSize: 11,
													fontWeight: FontWeight.w500,
												),
											)
										else
											const SizedBox.shrink(),
										if (!student.isActive)
											Container(
												padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
												decoration: BoxDecoration(
													color: AppColors.textMuted.withValues(alpha: 0.1),
													borderRadius: BorderRadius.circular(4),
												),
												child: const Text(
													'Bekliyor (aktif edilmedi)',
													style: TextStyle(
														color: AppColors.textMuted,
														fontSize: 10,
														fontWeight: FontWeight.w500,
													),
												),
											)
										else
											Container(
												padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
												decoration: BoxDecoration(
													color: AppColors.primary.withValues(alpha: 0.1),
													borderRadius: BorderRadius.circular(4),
												),
												child: const Text(
													'Aktif',
													style: TextStyle(
														color: AppColors.primary,
														fontSize: 10,
														fontWeight: FontWeight.w500,
													),
												),
											),
									],
								),
							],
						),
					),
				],
			),
		);
	}

	void _showUnassignConfirm(BuildContext context) {
		showDialog<void>(
			context: context,
			builder: (dialogContext) => AlertDialog(
				backgroundColor: AppColors.background,
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
				title: const Text(
					'Atamayı Kaldır',
					style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
				),
				content: Text(
					'${student.fullName} isimli sporcudan bu programı kaldırmak istediğinize emin misiniz?',
					style: const TextStyle(color: Colors.white70),
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(dialogContext),
						child: const Text(
							'VAZGEÇ',
							style: TextStyle(color: AppColors.textMuted),
						),
					),
					TextButton(
						onPressed: () {
							Navigator.pop(dialogContext);
							context.read<AssignedProgramsCubit>().unassignProgram(
								program.programId,
								student.studentId,
							);
						},
						child: const Text(
							'KALDIR',
							style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
						),
					),
				],
			),
		);
	}

}

class _EmptyAssignedState extends StatelessWidget {

	const _EmptyAssignedState();

	@override
	Widget build(BuildContext context) {
		return Center(
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					Icon(
						Icons.assignment_ind_outlined,
						size: 64,
						color: AppColors.textMuted.withValues(alpha: 0.2),
					),
					const SizedBox(height: 24),
					const Text(
						'Henüz atanan program yok.',
						style: TextStyle(
							color: Colors.white,
							fontSize: 18,
							fontWeight: FontWeight.bold,
						),
					),
					const SizedBox(height: 8),
					const Text(
						'Sporcularınıza program atadığınızda\nburada görebilirsiniz.',
						textAlign: TextAlign.center,
						style: TextStyle(color: AppColors.textMuted),
					),
				],
			),
		);
	}

}
