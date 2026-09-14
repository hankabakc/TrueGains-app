import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/features/training/models/exercise.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/exercise_library/exercise_library_cubit.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/exercise_library/exercise_library_state.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/widgets/empty_state.dart';
import 'package:gymapp_v2/features/training/ui/pages/exercise_selection_page.dart';
import 'package:gymapp_v2/features/training/ui/widgets/exercise_image.dart'; // ExerciseDetailPage for reuse

class ExerciseLibraryPage extends StatelessWidget {
  final bool isSelectionMode;
  final List<Exercise>? initialExercises;

  const ExerciseLibraryPage({
    super.key,
    this.isSelectionMode = false,
    this.initialExercises,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ExerciseLibraryCubit>()..loadExercises(initialExercises: initialExercises),
      child: ExerciseLibraryView(isSelectionMode: isSelectionMode),
    );
  }
}

class ExerciseLibraryView extends StatefulWidget {
  final bool isSelectionMode;
  const ExerciseLibraryView({super.key, required this.isSelectionMode});

  @override
  State<ExerciseLibraryView> createState() => _ExerciseLibraryViewState();
}

class _ExerciseLibraryViewState extends State<ExerciseLibraryView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExerciseLibraryCubit, ExerciseLibraryState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.isSelectionMode ? 'Egzersiz Seç' : 'Kütüphane',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ),
          body: state.status == ExerciseLibraryStatus.loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _buildMainContent(context, state),
          bottomNavigationBar: widget.isSelectionMode && state.selectedExercises.isNotEmpty
              ? _buildBottomAction(context, state)
              : null,
        );
      },
    );
  }

  Widget _buildBottomAction(BuildContext context, ExerciseLibraryState state) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context, state.selectedExercises.toList()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
          child: Text(
            '${state.selectedExercises.length} Egzersiz Ekle',
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, ExerciseLibraryState state) {
    return Column(
      children: [
        _buildSearchAndFilter(context, state),
        Expanded(
          child: state.filteredExercises.isEmpty
              ? const EmptyState(
                  icon: Icons.fitness_center_rounded,
                  title: 'Egzersiz bulunamadı.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: state.filteredExercises.length,
                  itemBuilder: (context, index) => _buildExerciseCard(context, state.filteredExercises[index], state),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter(BuildContext context, ExerciseLibraryState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => context.read<ExerciseLibraryCubit>().updateSearch(v),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Egzersiz ara...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryChip(context, 'Tümü', null, state.selectedGroup == null),
              ...MuscleGroup.values.map(
                (g) => _buildCategoryChip(context, g.turkishName, g, state.selectedGroup == g),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCategoryChip(BuildContext context, String label, MuscleGroup? group, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (v) => context.read<ExerciseLibraryCubit>().selectGroup(group),
        selectedColor: group?.color ?? AppColors.primary,
        checkmarkColor: AppColors.textPrimary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
        ),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm), side: BorderSide.none),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, Exercise exercise, ExerciseLibraryState state) {
    final isSelected = state.selectedExercises.any((e) => e.id == exercise.id);
    final groupColor = exercise.muscleGroup.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
      ),
      child: ListTile(
        onTap: () {
          if (widget.isSelectionMode) {
            context.read<ExerciseLibraryCubit>().toggleSelection(exercise);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => ExerciseDetailPage(exercise: exercise)),
            );
          }
        },
        leading: ExerciseImage(
          imageUrl: exercise.imageUrl,
          size: 40,
          iconColor: groupColor,
          backgroundColor: groupColor.withValues(alpha: 0.1),
          borderRadius: 10,
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          exercise.muscleGroup.turkishName,
          style: TextStyle(color: groupColor, fontSize: 11),
        ),
        trailing: widget.isSelectionMode
            ? Icon(
                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              )
            : const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
      ),
    );
  }
}
