import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';
import 'package:gymapp_v2/features/training/repository/training_repository.dart';
import 'create_personal_program_state.dart';

class CreatePersonalProgramCubit extends Cubit<CreatePersonalProgramState> {
  final TrainingRepository _repository;

  CreatePersonalProgramCubit({required TrainingRepository repository})
      : _repository = repository,
        super(const CreatePersonalProgramState()) {
    _initialize();
    loadExercises();
  }

  void init(TrainingBlock? initialBlock, {bool isTemplateMode = false}) {
    if (initialBlock != null) {
      final days = initialBlock.workoutDays;
      final offDays = days.map((d) => d.exercises.isEmpty).toList();
      final magnetEnabled = days.map((d) => d.isMagnetEnabled).toList();
      final expanded = List.generate(days.length, (_) => <String>{});

      emit(state.copyWith(
        draftDays: days,
        isOffDays: offDays,
        isMagnetEnabled: magnetEnabled,
        expandedGroups: expanded,
        isTemplate: initialBlock.isTemplate,
        editingProgramId: initialBlock.id,
        durationWeeks: initialBlock.durationWeeks,
        status: CreatePersonalProgramStatus.initial,
      ));
    } else {
      emit(state.copyWith(isTemplate: isTemplateMode));
    }
  }

  void setDurationWeeks(int weeks) {
    emit(state.copyWith(durationWeeks: weeks.clamp(1, 16)));
  }

  void _initialize() {
    final List<WorkoutDay> initialDays = List.generate(
      7,
      (i) => WorkoutDay(
        id: 0,
        name: _getDayName(i),
        dayOrder: i + 1,
        exercises: [],
      ),
    );

    emit(state.copyWith(
      draftDays: initialDays,
      isOffDays: List.filled(7, false),
      isMagnetEnabled: List.filled(7, true),
      expandedGroups: List.generate(7, (_) => <String>{}),
      selectedDayIndex: 0,
      status: CreatePersonalProgramStatus.initial,
    ));
  }

  String _getDayName(int index) {
    const names = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    return names[index];
  }

  Future<void> loadExercises() async {
    emit(state.copyWith(isLoadingExercises: true));
    try {
      final result = await _repository.getAllExercises();
      emit(state.copyWith(
        allExercises: result.data ?? [],
        isLoadingExercises: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingExercises: false,
        error: e.toString(),
      ));
    }
  }

  void selectDay(int index) {
    emit(state.copyWith(selectedDayIndex: index));
  }

  void toggleOffDay(int index) {
    final newOffDays = List<bool>.from(state.isOffDays);
    newOffDays[index] = !newOffDays[index];
    emit(state.copyWith(isOffDays: newOffDays));
  }

  void toggleMagnet(int index, bool val) {
    final newMagnet = List<bool>.from(state.isMagnetEnabled);
    newMagnet[index] = val;

    if (val) {
      _sortExercisesByGroup(index, updatedMagnet: newMagnet);
    } else {
      emit(state.copyWith(isMagnetEnabled: newMagnet));
    }
  }

  void toggleGroup(int dayIndex, String groupId) {
    final newExpanded = List<Set<String>>.from(
      state.expandedGroups.map((s) => Set<String>.from(s)),
    );
    if (newExpanded[dayIndex].contains(groupId)) {
      newExpanded[dayIndex].remove(groupId);
    } else {
      newExpanded[dayIndex].add(groupId);
    }
    emit(state.copyWith(expandedGroups: newExpanded));
  }

  void updateDayExercises(int dayIndex, List<WorkoutExercise> exercises) {
    final newDays = List<WorkoutDay>.from(state.draftDays);
    newDays[dayIndex] = WorkoutDay(
      id: newDays[dayIndex].id,
      name: newDays[dayIndex].name,
      dayOrder: newDays[dayIndex].dayOrder,
      isMagnetEnabled: state.isMagnetEnabled[dayIndex],
      exercises: exercises,
    );

    if (state.isMagnetEnabled[dayIndex]) {
      _sortExercisesByGroup(dayIndex, updatedDays: newDays);
    } else {
      emit(state.copyWith(draftDays: newDays));
    }
  }

  void addExercises(int dayIndex, List<WorkoutExercise> exercises) {
    final newDays = List<WorkoutDay>.from(state.draftDays);
    final currentExs = List<WorkoutExercise>.from(newDays[dayIndex].exercises);

    // Egzersizlere doğru orderIndex atama (mevcut liste boyutu baz alınarak)
    final startIdx = currentExs.length;
    final mappedExercises = exercises.asMap().entries.map((entry) {
      final idx = entry.key;
      final ex = entry.value;
      return WorkoutExercise(
        id: ex.id,
        exerciseId: ex.exerciseId,
        exerciseName: ex.exerciseName,
        muscleGroup: ex.muscleGroup,
        targetSets: ex.targetSets ?? 3,
        targetReps: ex.targetReps ?? '10',
        orderIndex: startIdx + idx,
        logs: ex.logs,
      );
    }).toList();

    currentExs.addAll(mappedExercises);

    newDays[dayIndex] = WorkoutDay(
      id: newDays[dayIndex].id,
      name: newDays[dayIndex].name,
      dayOrder: newDays[dayIndex].dayOrder,
      isMagnetEnabled: state.isMagnetEnabled[dayIndex],
      exercises: currentExs,
    );

    if (state.isMagnetEnabled[dayIndex]) {
      _sortExercisesByGroup(dayIndex, updatedDays: newDays);
    } else {
      emit(state.copyWith(draftDays: newDays));
    }
  }

  void updateExercise(int dayIndex, int exerciseIndex, WorkoutExercise updatedEx) {
    final newDays = List<WorkoutDay>.from(state.draftDays);
    final currentExs = List<WorkoutExercise>.from(newDays[dayIndex].exercises);
    currentExs[exerciseIndex] = updatedEx;

    newDays[dayIndex] = WorkoutDay(
      id: newDays[dayIndex].id,
      name: newDays[dayIndex].name,
      dayOrder: newDays[dayIndex].dayOrder,
      isMagnetEnabled: state.isMagnetEnabled[dayIndex],
      exercises: currentExs,
    );

    if (state.isMagnetEnabled[dayIndex]) {
      _sortExercisesByGroup(dayIndex, updatedDays: newDays);
    } else {
      emit(state.copyWith(draftDays: newDays));
    }
  }

  void deleteExercise(int dayIndex, int exerciseIndex) {
    final newDays = List<WorkoutDay>.from(state.draftDays);
    final currentExs = List<WorkoutExercise>.from(newDays[dayIndex].exercises);
    currentExs.removeAt(exerciseIndex);

    newDays[dayIndex] = WorkoutDay(
      id: newDays[dayIndex].id,
      name: newDays[dayIndex].name,
      dayOrder: newDays[dayIndex].dayOrder,
      isMagnetEnabled: state.isMagnetEnabled[dayIndex],
      exercises: currentExs,
    );

    emit(state.copyWith(draftDays: newDays));
  }

  /// [newIndex], öğe [oldIndex]'ten çıkarıldıktan sonraki yerdir (`onReorderItem` anlamı).
  void reorderDays(int oldIndex, int newIndex) {
    final newDays = List<WorkoutDay>.from(state.draftDays);
    final newOffDays = List<bool>.from(state.isOffDays);
    final newMagnet = List<bool>.from(state.isMagnetEnabled);
    final newExpanded = List<Set<String>>.from(
      state.expandedGroups.map((s) => Set<String>.from(s)),
    );

    final dayItem = newDays.removeAt(oldIndex);
    newDays.insert(newIndex, dayItem);

    final offDayItem = newOffDays.removeAt(oldIndex);
    newOffDays.insert(newIndex, offDayItem);

    final magnetItem = newMagnet.removeAt(oldIndex);
    newMagnet.insert(newIndex, magnetItem);

    final expandedItem = newExpanded.removeAt(oldIndex);
    newExpanded.insert(newIndex, expandedItem);

    final updatedDays = newDays.asMap().entries.map((entry) {
      final idx = entry.key;
      final d = entry.value;
      return WorkoutDay(
        id: d.id,
        name: d.name,
        dayOrder: idx + 1,
        isMagnetEnabled: d.isMagnetEnabled,
        exercises: d.exercises,
      );
    }).toList();

    int newSelectedDayIndex = state.selectedDayIndex;
    if (state.selectedDayIndex == oldIndex) {
      newSelectedDayIndex = newIndex;
    } else if (oldIndex < state.selectedDayIndex && newIndex >= state.selectedDayIndex) {
      newSelectedDayIndex -= 1;
    } else if (oldIndex > state.selectedDayIndex && newIndex <= state.selectedDayIndex) {
      newSelectedDayIndex += 1;
    }

    emit(state.copyWith(
      draftDays: updatedDays,
      isOffDays: newOffDays,
      isMagnetEnabled: newMagnet,
      expandedGroups: newExpanded,
      selectedDayIndex: newSelectedDayIndex,
    ));
  }

  /// [newIndex], öğe [oldIndex]'ten çıkarıldıktan sonraki yerdir (`onReorderItem` anlamı).
  void reorderMuscleGroups(int dayIndex, int oldIndex, int newIndex) {
    final newDays = List<WorkoutDay>.from(state.draftDays);
    final currentExs = List<WorkoutExercise>.from(newDays[dayIndex].exercises);

    if (currentExs.isEmpty) return;

    // 1. Mevcut görünüm sırasındaki benzersiz grup isimlerini al
    final List<String> groups = [];
    for (var ex in currentExs) {
      final groupName = ex.muscleGroup?.turkishName ?? 'Diğer';
      if (!groups.contains(groupName)) {
        groups.add(groupName);
      }
    }

    // 2. Grup listesini reorder et
    final draggedGroup = groups.removeAt(oldIndex);
    groups.insert(newIndex, draggedGroup);

    // 3. Egzersiz listesini YENİ grup sırasına göre baştan oluştur
    // (Aynı gruptaki egzersizlerin kendi iç sıralamasını bozmamak için where kullanıyoruz)
    final List<WorkoutExercise> reorderedExs = [];
    for (final groupName in groups) {
      reorderedExs.addAll(
        currentExs.where((ex) => (ex.muscleGroup?.turkishName ?? 'Diğer') == groupName),
      );
    }

    // 4. Tüm listenin orderIndex değerlerini yeni sıralamaya göre güncelle
    final updatedExs = reorderedExs.asMap().entries.map((entry) {
      final idx = entry.key;
      final ex = entry.value;
      return WorkoutExercise(
        id: ex.id,
        exerciseId: ex.exerciseId,
        exerciseName: ex.exerciseName,
        targetSets: ex.targetSets,
        targetReps: ex.targetReps,
        targetWeight: ex.targetWeight,
        restTimeSeconds: ex.restTimeSeconds,
        supersetGroupId: ex.supersetGroupId,
        orderIndex: idx, // Yeni global sıra
        coachNotes: ex.coachNotes,
        isToFailure: ex.isToFailure,
        logs: ex.logs,
        muscleGroup: ex.muscleGroup,
      );
    }).toList();

    newDays[dayIndex] = WorkoutDay(
      id: newDays[dayIndex].id,
      name: newDays[dayIndex].name,
      dayOrder: newDays[dayIndex].dayOrder,
      isMagnetEnabled: state.isMagnetEnabled[dayIndex],
      exercises: updatedExs,
    );

    emit(state.copyWith(draftDays: newDays));
  }

  /// [newIndex], öğe [oldIndex]'ten çıkarıldıktan sonraki yerdir (`onReorderItem` anlamı).
  void reorderExercises(int dayIndex, int oldIndex, int newIndex) {
    final newDays = List<WorkoutDay>.from(state.draftDays);
    final currentExs = List<WorkoutExercise>.from(newDays[dayIndex].exercises);

    final item = currentExs.removeAt(oldIndex);
    currentExs.insert(newIndex, item);

    // Tüm listenin orderIndex değerlerini yeni sıralamaya göre güncelle
    final updatedExs = currentExs.asMap().entries.map((entry) {
      final idx = entry.key;
      final ex = entry.value;
      return WorkoutExercise(
        id: ex.id,
        exerciseId: ex.exerciseId,
        exerciseName: ex.exerciseName,
        targetSets: ex.targetSets,
        targetReps: ex.targetReps,
        targetWeight: ex.targetWeight,
        restTimeSeconds: ex.restTimeSeconds,
        supersetGroupId: ex.supersetGroupId,
        orderIndex: idx, // Yeni sıra
        coachNotes: ex.coachNotes,
        isToFailure: ex.isToFailure,
        logs: ex.logs,
        muscleGroup: ex.muscleGroup,
      );
    }).toList();

    newDays[dayIndex] = WorkoutDay(
      id: newDays[dayIndex].id,
      name: newDays[dayIndex].name,
      dayOrder: newDays[dayIndex].dayOrder,
      isMagnetEnabled: state.isMagnetEnabled[dayIndex],
      exercises: updatedExs,
    );

    emit(state.copyWith(draftDays: newDays));
  }

  /// Mıknatıs açıkken kas grubu içindeki sürükle-bırak. Grup içi sırayı günün egzersiz
  /// listesindeki sıraya çevirip [reorderExercises]'e verir. [newGroupIndex], öğe
  /// çıkarıldıktan sonraki grup içi yerdir (`onReorderItem` anlamı).
  void reorderExerciseInGroup(int dayIndex, String groupName, int oldGroupIndex, int newGroupIndex) {
    if (oldGroupIndex == newGroupIndex) return;

    final exercises = state.draftDays[dayIndex].exercises;
    final group = exercises.where((ex) => (ex.muscleGroup?.turkishName ?? 'Diğer') == groupName).toList();
    final oldIndex = exercises.indexOf(group[oldGroupIndex]);

    final others = List<WorkoutExercise>.from(group)..removeAt(oldGroupIndex);
    final remaining = List<WorkoutExercise>.from(exercises)..removeAt(oldIndex);
    final newIndex = newGroupIndex < others.length
        ? remaining.indexOf(others[newGroupIndex])
        : remaining.indexOf(others.last) + 1;

    reorderExercises(dayIndex, oldIndex, newIndex);
  }

  void _sortExercisesByGroup(int index, {List<WorkoutDay>? updatedDays, List<bool>? updatedMagnet}) {
    final currentDays = updatedDays ?? List<WorkoutDay>.from(state.draftDays);
    final List<WorkoutExercise> currentExs = List<WorkoutExercise>.from(currentDays[index].exercises);

    if (currentExs.isEmpty) {
      // Sıralanacak egzersiz yok; ancak mıknatıs anahtarı yine de değişmeli.
      // Aksi hâlde boş bir günde anahtar açılıp durum hiç yayınlanmadığı için
      // ekranda kendiliğinden geri kapanıyordu.
      if (updatedMagnet != null) {
        emit(state.copyWith(draftDays: currentDays, isMagnetEnabled: updatedMagnet));
      }
      return;
    }

    // Mevcut (belki de manuel olarak değiştirilmiş) grup sırasını belirle
    final List<String> groupOrder = [];
    for (var ex in currentExs) {
      final groupName = ex.muscleGroup?.turkishName ?? 'Diğer';
      if (!groupOrder.contains(groupName)) {
        groupOrder.add(groupName);
      }
    }

    // Egzersizleri mevcut grup sırasına göre grupla (ancak grup içindeki sıraları bozma)
    // Bunun için kararlı (stable) bir sort kullanıyoruz.
    currentExs.sort((a, b) {
      final groupA = a.muscleGroup?.turkishName ?? 'Diğer';
      final groupB = b.muscleGroup?.turkishName ?? 'Diğer';

      int cmp = groupOrder.indexOf(groupA).compareTo(groupOrder.indexOf(groupB));
      if (cmp != 0) return cmp;

      // Aynı gruptalarsa, orijinal orderIndex'lerini koru (manuel sıralama için kritik)
      return a.orderIndex.compareTo(b.orderIndex);
    });

    // Sıralama sonrası orderIndex değerlerini YENİDEN ata (kalıcılık için)
    final updatedExs = currentExs.asMap().entries.map((entry) {
      final idx = entry.key;
      final ex = entry.value;
      return WorkoutExercise(
        id: ex.id,
        exerciseId: ex.exerciseId,
        exerciseName: ex.exerciseName,
        targetSets: ex.targetSets,
        targetReps: ex.targetReps,
        targetWeight: ex.targetWeight,
        restTimeSeconds: ex.restTimeSeconds,
        supersetGroupId: ex.supersetGroupId,
        orderIndex: idx, // Yeni sıra
        coachNotes: ex.coachNotes,
        isToFailure: ex.isToFailure,
        logs: ex.logs,
        muscleGroup: ex.muscleGroup,
      );
    }).toList();

    currentDays[index] = WorkoutDay(
      id: currentDays[index].id,
      name: currentDays[index].name,
      dayOrder: currentDays[index].dayOrder,
      isMagnetEnabled: true,
      exercises: updatedExs,
    );

    emit(state.copyWith(
      draftDays: currentDays,
      isMagnetEnabled: updatedMagnet ?? (List<bool>.from(state.isMagnetEnabled)..[index] = true),
    ));
  }

  Future<void> saveProgram(String name) async {
    emit(state.copyWith(status: CreatePersonalProgramStatus.loading));
    try {
      final int effectiveId = state.editingProgramId ?? 0;
      
      final List<WorkoutDay> finalDays = [];
      for (int i = 0; i < state.draftDays.length; i++) {
        if (state.isOffDays[i]) {
          finalDays.add(WorkoutDay(
            id: state.draftDays[i].id,
            name: state.draftDays[i].name,
            dayOrder: state.draftDays[i].dayOrder,
            exercises: [],
          ));
        } else {
          finalDays.add(state.draftDays[i]);
        }
      }

      final program = TrainingBlock(
        id: effectiveId,
        name: name,
        description: state.isTemplate ? 'Antrenör Şablonu' : 'Kişisel Program',
        coachName: state.isTemplate ? 'Antrenör Şablonu' : 'Kişisel Program',
        clientId: 0,
        clientName: '',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: 7 * state.durationWeeks)),
        isActive: false,
        isPersonal: !state.isTemplate,
        isTemplate: state.isTemplate,
        workoutDays: finalDays,
        durationWeeks: state.durationWeeks,
      );

      if (effectiveId != 0) {
        if (state.isTemplate) {
          final res = await _repository.updateCoachTemplate(effectiveId, program);
          if (!res.success) throw Exception(res.message);
        } else {
          final res = await _repository.updatePersonalProgram(effectiveId, program);
          if (!res.success) throw Exception(res.message);
        }
      } else {
        if (state.isTemplate) {
          final res = await _repository.createCoachTemplate(program);
          if (!res.success) throw Exception(res.message);
        } else {
          final res = await _repository.createPersonalProgram(program);
          if (!res.success) throw Exception(res.message);
        }
      }
      emit(state.copyWith(status: CreatePersonalProgramStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: CreatePersonalProgramStatus.failure,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }
}
