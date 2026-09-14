import 'package:equatable/equatable.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_entry_model.dart';

abstract class DietEntryEvent extends Equatable {
  const DietEntryEvent();
  @override
  List<Object?> get props => [];
}

class LoadDailyLog extends DietEntryEvent {
  final DateTime date;
  const LoadDailyLog(this.date);
  @override
  List<Object?> get props => [date];
}

class ChangeDate extends DietEntryEvent {
  final DateTime newDate;
  const ChangeDate(this.newDate);
  @override
  List<Object?> get props => [newDate];
}

class ToggleIngredient extends DietEntryEvent {
  final int mealId;
  final int ingredientId;
  const ToggleIngredient(this.mealId, this.ingredientId);
  @override
  List<Object?> get props => [mealId, ingredientId];
}

class ToggleAllMeal extends DietEntryEvent {
  final PlannedMealModel meal;
  const ToggleAllMeal(this.meal);
  @override
  List<Object?> get props => [meal];
}

class DeleteExtraItem extends DietEntryEvent {
  final int itemId;
  const DeleteExtraItem(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class InitializeDietEntry extends DietEntryEvent {
  const InitializeDietEntry();
}

class DietEntryUpdatedExternally extends DietEntryEvent {
  const DietEntryUpdatedExternally();
}

class UnsubscribeDietUpdates extends DietEntryEvent {
  const UnsubscribeDietUpdates();
}

