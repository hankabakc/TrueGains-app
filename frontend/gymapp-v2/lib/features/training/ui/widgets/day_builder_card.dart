import 'package:flutter/material.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';

class DayBuilderCard extends StatelessWidget {
  final int dayIndex; // Display index (e.g. 1)
  final int dayOrder; // State index (e.g. 0)
  final WorkoutDay workoutDay;
  final bool isOffDay;
  final bool isMagnetEnabled;
  final Set<String> expandedGroups;
  final bool isReadOnly;

  final VoidCallback onAddExercises;
  final void Function(bool) onOffDayToggle;
  final void Function(int, WorkoutExercise) onEditExercise;
  final void Function(int, int) onReorder;
  final void Function(int, int)? onReorderMuscleGroup;
  final VoidCallback onToggleMagnet;
  final void Function(String) onToggleGroup;

  const DayBuilderCard({
    super.key,
    required this.dayIndex,
    required this.dayOrder,
    required this.workoutDay,
    required this.isOffDay,
    required this.isMagnetEnabled,
    required this.expandedGroups,
    required this.onAddExercises,
    required this.onOffDayToggle,
    required this.onEditExercise,
    required this.onReorder,
    this.onReorderMuscleGroup,
    required this.onToggleMagnet,
    required this.onToggleGroup,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: 24,
        child: Column(
          children: [
            // GÜN BAŞLIĞI VE AYARLAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isOffDay ? Colors.transparent : AppColors.primary.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Mıknatıs / Sayı Alanı
                  InkWell(
                    onTap: isReadOnly ? null : onToggleMagnet,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isOffDay
                            ? Colors.white.withValues(alpha: 0.05)
                            : (isMagnetEnabled
                                ? AppColors.primary
                                : AppColors.textMuted.withValues(alpha: 0.2)),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.edgesensor_high_rounded,
                          color: isOffDay
                              ? Colors.white24
                              : (isMagnetEnabled ? Colors.white : AppColors.textMuted),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$dayIndex. Gün',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        'Dinlenme',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isOffDay ? AppColors.primary : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: isOffDay,
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                        onChanged: isReadOnly ? null : onOffDayToggle,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // EGZERSİZ LİSTESİ
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (workoutDay.exercises.isEmpty)
                      _buildEmptyState()
                    else
                      _buildExerciseGroups(),
                    const SizedBox(height: 16),
                    _buildAddButton(),
                  ],
                ),
              ),
              crossFadeState: isOffDay ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: 48,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz egzersiz eklemedin.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseGroups() {
    final exercises = workoutDay.exercises;
    if (!isMagnetEnabled) {
      return _buildReorderableExerciseList(exercises);
    }

    final Map<String, List<WorkoutExercise>> groups = {};
    for (var ex in exercises) {
      final groupName = ex.muscleGroup?.turkishName ?? 'Diğer';
      groups.putIfAbsent(groupName, () => <WorkoutExercise>[]).add(ex);
    }

    final List<String> sortedKeys = [];
    for (var ex in exercises) {
      final groupName = ex.muscleGroup?.turkishName ?? 'Diğer';
      if (!sortedKeys.contains(groupName)) {
        sortedKeys.add(groupName);
      }
    }

    if (isReadOnly) {
      return Column(
        children: sortedKeys.map((String groupName) {
          final groupExercises = groups[groupName]!;
          final isExpanded = expandedGroups.contains(groupName);
          final groupColor = groupExercises.first.muscleGroup?.color ?? AppColors.primary;
          return _buildGroupCard(groupName, groupExercises, isExpanded, groupColor, exercises, null);
        }).toList(),
      );
    }

    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      proxyDecorator: _proxyDecorator,
      onReorder: (oldIdx, newIdx) {
        if (onReorderMuscleGroup != null) {
          onReorderMuscleGroup!(oldIdx, newIdx);
        }
      },
      children: sortedKeys.asMap().entries.map((entry) {
        final groupIdx = entry.key;
        final groupName = entry.value;
        final groupExercises = groups[groupName]!;
        final isExpanded = expandedGroups.contains(groupName);
        final groupColor = groupExercises.first.muscleGroup?.color ?? AppColors.primary;
        return _buildGroupCard(groupName, groupExercises, isExpanded, groupColor, exercises, groupIdx);
      }).toList(),
    );
  }

  Widget _buildGroupCard(
    String groupName,
    List<WorkoutExercise> groupExercises,
    bool isExpanded,
    Color groupColor,
    List<WorkoutExercise> exercises,
    int? groupIdx,
  ) {
    return Container(
      key: ValueKey('group_$groupName'),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: groupColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: groupColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => onToggleGroup(groupName),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (groupIdx != null && !isReadOnly)
                    ReorderableDragStartListener(
                      index: groupIdx,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color: groupColor.withValues(alpha: 0.5),
                          size: 20,
                        ),
                      ),
                    ),
                  Container(
                    width: 8,
                    height: 24,
                    decoration: BoxDecoration(
                      color: groupColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    groupName.toUpperCase(),
                    style: TextStyle(
                      color: groupColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: groupColor.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: isReadOnly
                  ? Column(
                      children: groupExercises.asMap().entries.map((entry) {
                        final idx = exercises.indexOf(entry.value);
                        return _buildExerciseTile(entry.value, index: idx + 1);
                      }).toList(),
                    )
                  : ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      proxyDecorator: _proxyDecorator,
                      onReorder: (oldGroupIdx, newGroupIdx) {
                        final oldMainIdx = exercises.indexOf(groupExercises[oldGroupIdx]);
                        int newMainIdx;

                        if (newGroupIdx < groupExercises.length) {
                          newMainIdx = exercises.indexOf(groupExercises[newGroupIdx]);
                        } else {
                          // Grubun sonuna taşıma durumunda, grubun son elemanından bir sonraki index
                          newMainIdx = exercises.indexOf(groupExercises.last) + 1;
                        }

                        onReorder(oldMainIdx, newMainIdx);
                      },
                      children: groupExercises.asMap().entries.map((entry) {
                        final gIdx = entry.key;
                        final ex = entry.value;
                        final mainIdx = exercises.indexOf(ex);
                        return _buildExerciseTile(
                          ex,
                          key: ValueKey('ex_group_${ex.id}_$mainIdx'),
                          index: mainIdx + 1,
                          groupIdx: gIdx,
                        );
                      }).toList(),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildReorderableExerciseList(List<WorkoutExercise> exercises) {
    if (isReadOnly) {
      return Column(
        children: exercises.asMap().entries.map((entry) {
          final idx = entry.key;
          final ex = entry.value;
          return _buildExerciseTile(
            ex,
            key: ValueKey('ex_${ex.id}_$idx'),
            index: idx + 1,
          );
        }).toList(),
      );
    }
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      proxyDecorator: _proxyDecorator,
      onReorder: onReorder,
      children: exercises.asMap().entries.map((entry) {
        final idx = entry.key;
        final ex = entry.value;
        return _buildExerciseTile(
          ex,
          key: ValueKey('ex_${ex.id}_$idx'),
          index: idx + 1,
        );
      }).toList(),
    );
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return Material(
          elevation: 0,
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.8,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildExerciseTile(WorkoutExercise ex, {Key? key, int? index, int? groupIdx}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: 16,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: isReadOnly ? null : () => onEditExercise(index! - 1, ex),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                if (index != null && !isMagnetEnabled && !isReadOnly)
                  ReorderableDragStartListener(
                    index: index - 1,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        color: AppColors.primary.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ),
                  )
                else if (index != null && isMagnetEnabled && !isReadOnly && groupIdx != null)
                  ReorderableDragStartListener(
                    index: groupIdx,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        color: AppColors.primary.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ),
                  )
                else if (index != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      '#$index',
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.exerciseName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ex.targetSets} Set • ${ex.targetReps} Tekrar ${ex.isToFailure ? '🔥' : ''}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isReadOnly)
                  Icon(
                    isMagnetEnabled ? Icons.keyboard_arrow_right_rounded : Icons.reorder_rounded,
                    color: Colors.white12,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    if (isReadOnly) return const SizedBox.shrink();
    return OutlinedButton.icon(
      onPressed: onAddExercises,
      icon: const Icon(Icons.add_circle_outline_rounded),
      label: const Text('Yeni Egzersiz Ekle'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }
}
