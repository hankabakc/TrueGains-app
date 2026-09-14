import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/config/app_config.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'diet_entry_event.dart';
import 'diet_entry_state.dart';


class DietEntryBloc extends Bloc<DietEntryEvent, DietEntryState> {
  final NutritionRepository _repository;

  DietEntryBloc(this._repository) : super(DietEntryState(selectedDate: DateTime.now())) {
    on<InitializeDietEntry>(_onInitialize);
    on<LoadDailyLog>(_onLoadDailyLog);
    on<ChangeDate>(_onChangeDate);
    on<ToggleIngredient>(_onToggleIngredient);
    on<ToggleAllMeal>(_onToggleAllMeal);
    on<DeleteExtraItem>(_onDeleteExtraItem);
    on<DietEntryUpdatedExternally>(_onDietEntryUpdatedExternally);
    on<UnsubscribeDietUpdates>(_onUnsubscribeUpdates);
  }

  Future<void> _onInitialize(InitializeDietEntry event, Emitter<DietEntryState> emit) async {
    final today = DateTime.now();
    final dateBeforeFetch = state.selectedDate;
    final progResp = await _repository.getMainProgram();
    // K5-12: istek sürerken kullanıcı günlükte başka bir güne geçtiyse onun seçimi
    // kazanır; geçmediyse panelin ihtiyacı olan "bugün" yazılır.
    final targetDate = state.selectedDate == dateBeforeFetch ? today : state.selectedDate;
    // Başarısızlıkta progResp.data null gelir; copyWith null'da eski programı korur.
    emit(state.copyWith(selectedDate: targetDate, mainProgram: progResp.data));
    add(LoadDailyLog(targetDate));
  }

  Future<void> subscribeToUpdates(int clientId) async {
    await _repository.subscribeToDietUpdates(
      clientId: clientId,
      wsUrl: AppConfig.wsUrl,
      onUpdateReceived: () {
        add(DietEntryUpdatedExternally());
      },
    );
  }



  Future<void> _onDietEntryUpdatedExternally(DietEntryUpdatedExternally event, Emitter<DietEntryState> emit) async {
    final progResp = await _repository.getMainProgram();
    if (progResp.success) {
      emit(state.copyWith(mainProgram: progResp.data));
    }
    // Secili gun logunu yeniden yukleyelim
    final res = await _repository.getDailyDietLog(state.selectedDate);
    if (res.success && res.data != null) {
      final log = res.data!;
      final newSelections = <int, Set<int>>{};
      for (final meal in log.plannedMeals) {
        newSelections[meal.mealId] = (meal.consumedIngredientIds ?? []).toSet();
      }
      emit(state.copyWith(
        status: DietEntryStatus.success,
        log: log,
        localSelections: newSelections,
      ));
    }
  }

  void _onUnsubscribeUpdates(UnsubscribeDietUpdates event, Emitter<DietEntryState> emit) {
    _repository.unsubscribeFromDietUpdates();
  }


  Future<void> _onLoadDailyLog(LoadDailyLog event, Emitter<DietEntryState> emit) async {
    if (state.log == null) {
      emit(state.copyWith(status: DietEntryStatus.loading));
    }
    final res = await _repository.getDailyDietLog(event.date);
    // K5-12: yanıt dönene kadar başka bir güne geçildiyse bu veri artık ekrandaki güne
    // ait değil. Yazılırsa tarih bir günü, öğün listesi başka günü gösterir.
    if (event.date != state.selectedDate) return;
    if (res.success && res.data != null) {
      final log = res.data!;
      final newSelections = <int, Set<int>>{};
      for (final meal in log.plannedMeals) {
        newSelections[meal.mealId] = (meal.consumedIngredientIds ?? []).toSet();
      }
      emit(state.copyWith(
        status: DietEntryStatus.success,
        log: log,
        localSelections: newSelections,
      ));
    } else {
      emit(state.copyWith(
        status: DietEntryStatus.failure,
        error: res.message,
      ));
    }
  }

  void _onChangeDate(ChangeDate event, Emitter<DietEntryState> emit) {
    emit(state.copyWith(
      selectedDate: event.newDate,
      log: null,
      localSelections: {},
    ));
    add(LoadDailyLog(event.newDate));
  }

  Future<void> _onToggleIngredient(ToggleIngredient event, Emitter<DietEntryState> emit) async {
    final currentSelections = Map<int, Set<int>>.from(state.localSelections);
    final previous = Set<int>.from(currentSelections[event.mealId] ?? {});
    final next = Set<int>.from(previous);

    if (next.contains(event.ingredientId)) {
      next.remove(event.ingredientId);
    } else {
      next.add(event.ingredientId);
    }

    currentSelections[event.mealId] = next;
    emit(state.copyWith(localSelections: currentSelections));

    final res = next.isEmpty
        ? await _repository.togglePlannedMeal(
            date: state.selectedDate,
            mealId: event.mealId,
            consumed: false,
          )
        : await _repository.togglePlannedMeal(
            date: state.selectedDate,
            mealId: event.mealId,
            consumed: true,
            ingredientIds: next.toList(),
          );

    if (!res.success) {
      currentSelections[event.mealId] = previous;
      emit(state.copyWith(localSelections: currentSelections, error: res.message));
    } else {
      // Başarılı işlem sonrası makroların ve öğünlerin güncellenmesi için re-fetch yap
      add(LoadDailyLog(state.selectedDate));
    }
  }

  Future<void> _onToggleAllMeal(ToggleAllMeal event, Emitter<DietEntryState> emit) async {
    final currentSelections = Map<int, Set<int>>.from(state.localSelections);
    final allIds = event.meal.plannedIngredients
        .where((ing) => ing.id != null)
        .map((ing) => ing.id!)
        .toSet();

    final current = currentSelections[event.meal.mealId] ?? {};
    final previous = Set<int>.from(current);
    final bool selectAll = current.length < allIds.length;
    final next = selectAll ? allIds : <int>{};

    currentSelections[event.meal.mealId] = next;
    emit(state.copyWith(localSelections: currentSelections));

    final res = !selectAll
        ? await _repository.togglePlannedMeal(
            date: state.selectedDate,
            mealId: event.meal.mealId,
            consumed: false,
          )
        : await _repository.togglePlannedMeal(
            date: state.selectedDate,
            mealId: event.meal.mealId,
            consumed: true,
          );

    if (!res.success) {
      currentSelections[event.meal.mealId] = previous;
      emit(state.copyWith(localSelections: currentSelections, error: res.message));
    } else {
      // Başarılı işlem sonrası makroların ve öğünlerin güncellenmesi için re-fetch yap
      add(LoadDailyLog(state.selectedDate));
    }
  }

  Future<void> _onDeleteExtraItem(DeleteExtraItem event, Emitter<DietEntryState> emit) async {
    final res = await _repository.deleteMealItem(event.itemId);
    if (res.success) {
      add(LoadDailyLog(state.selectedDate));
    } else {
      emit(state.copyWith(error: res.message));
    }
  }

  @override
  Future<void> close() {
    _repository.unsubscribeFromDietUpdates();
    return super.close();
  }
}

