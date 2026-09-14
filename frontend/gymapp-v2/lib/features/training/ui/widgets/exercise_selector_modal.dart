import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/features/training/models/exercise.dart';
import '../../presentation/bloc/exercise_selector/exercise_selector_cubit.dart';
import '../../presentation/bloc/exercise_selector/exercise_selector_state.dart';

class ExerciseSelectorModal extends StatelessWidget {
  final List<Exercise> allExercises;

  const ExerciseSelectorModal({super.key, required this.allExercises});

  static final List<Map<String, dynamic>> _categories = [
    {'name': 'Tümü', 'group': null},
    {'name': 'Sırt', 'group': MuscleGroup.BACK},
    {'name': 'Göğüs', 'group': MuscleGroup.CHEST},
    {'name': 'Omuz', 'group': MuscleGroup.SHOULDERS},
    {'name': 'Biceps', 'group': MuscleGroup.BICEPS},
    {'name': 'Triceps', 'group': MuscleGroup.TRICEPS},
    {'name': 'Karın', 'group': MuscleGroup.ABS},
    {'name': 'Baldır', 'group': MuscleGroup.QUADRICEPS},
    {'name': 'Arka Bacak', 'group': MuscleGroup.HAMSTRINGS},
    {'name': 'Kalf', 'group': MuscleGroup.CALVES},
    {'name': 'Tüm Vücut', 'group': MuscleGroup.FULL_BODY},
    {'name': 'Kardiyo', 'group': MuscleGroup.CARDIO},
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExerciseSelectorCubit(allExercises),
      child: BlocBuilder<ExerciseSelectorCubit, ExerciseSelectorState>(
        builder: (context, state) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    'Egzersiz Seç',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                // Categories horizontal scroll
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = state.selectedGroup == category['group'];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(
                            category['name'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.black : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            context.read<ExerciseSelectorCubit>().selectGroup(
                              category['group'] as MuscleGroup?,
                            );
                          },
                          backgroundColor: AppColors.surface,
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.glassBorder,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.glassBorder),

                // Exercise List
                Expanded(
                  child: state.filteredExercises.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: state.filteredExercises.length,
                          itemBuilder: (context, index) {
                            final ex = state.filteredExercises[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.glassBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: const Icon(
                                    Icons.fitness_center,
                                    color: AppColors.primary,
                                  ),
                                ),
                                title: Text(
                                  ex.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    _getCategoryName(ex.muscleGroup),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                trailing: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.add,
                                      color: Colors.black,
                                    ),
                                    onPressed: () => Navigator.pop(context, ex),
                                  ),
                                ),
                                onTap: () => Navigator.pop(context, ex),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bu kategoride egzersiz bulunmuyor.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(MuscleGroup group) {
    final match = _categories.firstWhere(
      (c) => c['group'] == group,
      orElse: () => {'name': 'Bilinmiyor'},
    );
    return match['name'] as String;
  }
}
