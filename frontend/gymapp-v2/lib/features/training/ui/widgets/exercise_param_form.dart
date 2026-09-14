import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/exercise_edit/exercise_edit_cubit.dart';

class ExerciseEditModal extends StatefulWidget {
  final int exerciseOrder;
  final WorkoutExercise initialData;
  final void Function(WorkoutExercise) onSaved;
  final VoidCallback onDelete;

  const ExerciseEditModal({
    super.key,
    required this.exerciseOrder,
    required this.initialData,
    required this.onSaved,
    required this.onDelete,
  });

  @override
  State<ExerciseEditModal> createState() => _ExerciseEditModalState();
}

class _ExerciseEditModalState extends State<ExerciseEditModal> {
  late TextEditingController _setsController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController(
      text: widget.initialData.targetSets?.toString() ?? '3',
    );
    _repsController = TextEditingController(
      text: widget.initialData.targetReps ?? '10-12',
    );
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _saveAndClose(bool isToFailure) {
    final updated = WorkoutExercise(
      id: widget.initialData.id,
      exerciseId: widget.initialData.exerciseId,
      exerciseName: widget.initialData.exerciseName,
      targetSets: int.tryParse(_setsController.text) ?? 3,
      targetReps: _repsController.text,
      orderIndex: widget.initialData.orderIndex,
      isToFailure: isToFailure,
      logs: widget.initialData.logs,
      coachNotes: widget.initialData.coachNotes,
      restTimeSeconds: widget.initialData.restTimeSeconds,
      supersetGroupId: widget.initialData.supersetGroupId,
      targetWeight: widget.initialData.targetWeight,
      muscleGroup: widget.initialData.muscleGroup,
    );
    widget.onSaved(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExerciseEditCubit(widget.initialData.isToFailure),
      child: BlocBuilder<ExerciseEditCubit, ExerciseEditState>(
        builder: (context, state) {
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              border: Border(top: BorderSide(color: Colors.white10, width: 2)),
            ),
            child: Wrap(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.exerciseOrder}. ${widget.initialData.exerciseName}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        widget.onDelete();
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.delete_sweep_rounded,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            ' SET SAYISI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _setsController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              hintText: 'Set',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                              prefixIcon: const Icon(Icons.repeat_rounded, size: 20, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            ' TEKRAR HEDEFİ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _repsController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              hintText: 'Örn: 8-12',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                              prefixIcon: const Icon(Icons.ads_click_rounded, size: 20, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: state.isToFailure ? Colors.orange.withValues(alpha: 0.1) : AppColors.glassWhite,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: state.isToFailure ? Colors.orange.withValues(alpha: 0.3) : AppColors.glassBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            color: state.isToFailure ? Colors.orange : AppColors.textMuted,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tükeniş (Failure)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: state.isToFailure ? Colors.orange : Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Kas gücü bitene kadar devam et.',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: state.isToFailure,
                        activeThumbColor: Colors.orange,
                        activeTrackColor: Colors.orange.withValues(alpha: 0.3),
                        onChanged: (val) => context.read<ExerciseEditCubit>().toggleFailure(val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: PremiumButton(
                    text: 'GÜNCELLEMEYİ KAYDET',
                    onPressed: () => _saveAndClose(state.isToFailure),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
