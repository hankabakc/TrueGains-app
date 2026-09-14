import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/core/widgets/pressable_scale.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:gymapp_v2/features/training/models/exercise.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/exercise_library/exercise_library_cubit.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/exercise_library/exercise_library_state.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/features/training/ui/widgets/exercise_image.dart';

class ExerciseSelectionPage extends StatelessWidget {
  final bool isSelectionMode;
  final List<Exercise>? allExercises;

  const ExerciseSelectionPage({
    super.key,
    this.isSelectionMode = false,
    this.allExercises,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ExerciseLibraryCubit>()
        ..loadExercises(initialExercises: allExercises),
      child: ExerciseSelectionView(isSelectionMode: isSelectionMode),
    );
  }
}

class ExerciseSelectionView extends StatefulWidget {
  final bool isSelectionMode;
  const ExerciseSelectionView({super.key, required this.isSelectionMode});

  @override
  State<ExerciseSelectionView> createState() => _ExerciseSelectionViewState();
}

class _ExerciseSelectionViewState extends State<ExerciseSelectionView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<ExerciseLibraryCubit>().updateSearch(query);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.isSelectionMode ? 'Egzersiz Seç' : 'Kütüphane',
              style: AppTextStyles.pageTitle,
            ),
          ),
          body: state.status == ExerciseLibraryStatus.loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : state.status == ExerciseLibraryStatus.failure
                  ? _buildErrorState(context)
                  : _buildMainContent(context, state),
          bottomNavigationBar:
              widget.isSelectionMode && state.selectedExercises.isNotEmpty
                  ? _buildBottomAction(context, state)
                  : null,
        );
      },
    );
  }

  Widget _buildBottomAction(BuildContext context, ExerciseLibraryState state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withValues(alpha: 0),
            AppColors.background,
          ],
        ),
      ),
      child: SafeArea(
        child: PremiumButton(
          text: '${state.selectedExercises.length} Egzersiz Ekle',
          onPressed: () =>
              Navigator.pop(context, state.selectedExercises.toList()),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Hata oluştu',
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: () =>
                context.read<ExerciseLibraryCubit>().loadExercises(),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, ExerciseLibraryState state) {
    return Column(
      children: [
        _buildSearchAndFilter(context, state),
        _buildResultsHeader(
          state.filteredExercises.length,
          state.selectedExercises.length,
        ),
        Expanded(
          child: state.filteredExercises.isEmpty
              ? _buildEmptyState()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      itemCount: state.filteredExercises.length,
                      itemBuilder: (context, index) => _buildExerciseCard(
                        context,
                        state.filteredExercises[index],
                        state,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter(
    BuildContext context,
    ExerciseLibraryState state,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Arama yap...',
                  hintStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.glassWhite,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.glassBorder),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.glassBorder),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  _buildFilterChip(
                    context,
                    'Tümü',
                    null,
                    state.selectedGroup == null,
                  ),
                  ...MuscleGroup.values.map(
                    (g) => _buildFilterChip(
                      context,
                      g.turkishName,
                      g,
                      state.selectedGroup == g,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    MuscleGroup? group,
    bool isSelected,
  ) {
    final chipColor = group?.color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (v) =>
            context.read<ExerciseLibraryCubit>().selectGroup(group),
        selectedColor: chipColor.withValues(alpha: 0.2),
        backgroundColor: AppColors.glassWhite,
        labelStyle: AppTextStyles.tagText.copyWith(
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(
            color: isSelected ? chipColor.withValues(alpha: 0.5) : AppColors.glassBorder,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildResultsHeader(int count, int selectedCount) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$count sonuç bulundu',
                style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted),
              ),
              if (widget.isSelectionMode && selectedCount > 0)
                Text(
                  '$selectedCount SEÇİLİ',
                  style: AppTextStyles.tagText.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    Exercise exercise,
    ExerciseLibraryState state,
  ) {
    final isSelected = widget.isSelectionMode &&
        state.selectedExercises.any((e) => e.id == exercise.id);
    final groupColor = exercise.muscleGroup.color;

    return PressableScale(
      onTap: () {
        if (widget.isSelectionMode) {
          context.read<ExerciseLibraryCubit>().toggleSelection(exercise);
        } else {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ExerciseDetailPage(exercise: exercise),
            ),
          );
        }
      },
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: AppRadius.md,
        shadow: AppElevation.softGlow(isSelected ? AppColors.primary : AppColors.glassBorder),
        border: isSelected
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
            : Border.all(color: AppColors.glassBorder),
        child: Row(
          children: [
            ExerciseImage(
              imageUrl: exercise.imageUrl,
              size: 52,
              iconColor: groupColor,
              backgroundColor: groupColor.withValues(alpha: 0.15),
              borderRadius: AppRadius.md,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: AppTextStyles.listTitle,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    exercise.muscleGroup.turkishName,
                    style: AppTextStyles.listSubtitle,
                  ),
                ],
              ),
            ),
            if (widget.isSelectionMode)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ExerciseDetailPage(exercise: exercise),
                        ),
                      );
                    },
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                ],
              )
            else
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textMuted,
                size: 14,
              ),
          ],
        ),
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
            color: AppColors.textMuted.withValues(alpha: 0.2),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Egzersiz bulunamadı.',
            style: AppTextStyles.emptyTitle.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class ExerciseDetailPage extends StatelessWidget {
  final Exercise exercise;
  const ExerciseDetailPage({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final color = exercise.muscleGroup.color;
    final screenWidth = MediaQuery.of(context).size.width;
    final double headerWidth = screenWidth > 600 ? 600 : screenWidth;
    const double topSpace = 80.0;
    final double appBarHeight = headerWidth + topSpace;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: appBarHeight,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Üst boşluğu F0F0EE renginde yapar
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: topSpace,
                        child: Container(
                          color: AppColors.surface,
                        ),
                      ),
                      if (exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty)
                        Positioned(
                          top: topSpace,
                          left: 0,
                          right: 0,
                          height: headerWidth,
                          child: ExerciseImage(
                            imageUrl: exercise.imageUrl,
                            borderRadius: 0,
                            iconColor: color,
                            backgroundColor: Colors.transparent,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        )
                      else
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: topSpace),
                            child: Icon(
                              Icons.fitness_center_rounded,
                              color: color.withValues(alpha: 0.8),
                              size: 120,
                            ),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      exercise.name.toUpperCase(),
                      style: AppTextStyles.pageTitle,
                    ),
                    if (exercise.scientificName != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        exercise.scientificName!,
                        style: AppTextStyles.bodyText.copyWith(
                          color: color,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    _buildInfoSection(
                      'HEDEF KAS GRUBU',
                      exercise.muscleGroup.turkishName,
                      Icons.accessibility_new_rounded,
                      color,
                    ),
                    if (exercise.description != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const SectionHeader(
                        label: 'NASIL YAPILIR?',
                        icon: Icons.help_outline_rounded,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      GlassContainer(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        borderRadius: AppRadius.md,
                        shadow: AppElevation.softGlow(color),
                        child: Text(
                          exercise.description!,
                          style: AppTextStyles.bodyText.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppLayout.bottomNavClearance),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.md,
      shadow: AppElevation.softGlow(color),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardCaption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: AppTextStyles.listTitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
