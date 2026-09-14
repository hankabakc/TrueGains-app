import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'meal_template_editor_state.dart';

class MealTemplateEditorCubit extends Cubit<MealTemplateEditorState> {
  final NutritionRepository _repository;

  MealTemplateEditorCubit(this._repository) : super(const MealTemplateEditorState());

  void initialize(MealTemplateModel? template, int? templateId) async {
    if (template != null) {
      emit(state.copyWith(
        status: MealTemplateEditorStatus.success,
        name: template.name,
        selectedMealTypes: List.from(template.applicableMealTypes),
        ingredients: List.from(template.ingredients),
      ));
    } else if (templateId != null) {
      emit(state.copyWith(status: MealTemplateEditorStatus.loading));
      final resp = await _repository.getTemplateDetail(templateId);
      if (resp.success && resp.data != null) {
        emit(state.copyWith(
          status: MealTemplateEditorStatus.success,
          name: resp.data!.name,
          selectedMealTypes: List.from(resp.data!.applicableMealTypes),
          ingredients: List.from(resp.data!.ingredients),
        ));
      } else {
        emit(state.copyWith(status: MealTemplateEditorStatus.failure, error: resp.message));
      }
    }
  }

  void updateName(String name) {
    emit(state.copyWith(name: name));
  }

  void toggleMealType(MealType type) {
    final List<MealType> newList = List.from(state.selectedMealTypes);
    if (newList.contains(type)) {
      newList.remove(type);
    } else {
      newList.add(type);
    }
    emit(state.copyWith(selectedMealTypes: newList));
  }

  void addIngredients(List<MealIngredientModel> items) {
    final List<MealIngredientModel> newList = List.from(state.ingredients);
    newList.addAll(items);
    emit(state.copyWith(ingredients: newList));
  }

  /// Malzemeler konumlarıyla silinir/düzenlenir.
  ///
  /// Değere göre arama (`remove`/`indexOf`) hatalıydı: eşitlik `foodName`'i
  /// içermediği için aynı besin aynı miktarla iki kez eklendiğinde iki satır
  /// birbirinin aynısı sayılıyor ve kullanıcı ikinci satırı düzenlediğinde
  /// birinci satır değişiyordu.
  void removeIngredientAt(int index) {
    if (index < 0 || index >= state.ingredients.length) return;
    final List<MealIngredientModel> newList = List.from(state.ingredients);
    newList.removeAt(index);
    emit(state.copyWith(ingredients: newList));
  }

  void updateIngredientAmountAt(int index, double amount) {
    if (index < 0 || index >= state.ingredients.length) return;
    final List<MealIngredientModel> newList = List.from(state.ingredients);
    newList[index] = newList[index].copyWith(amount: amount);
    emit(state.copyWith(ingredients: newList));
  }

  void setPage(int page) {
    emit(state.copyWith(currentPage: page));
  }

  Future<void> saveTemplate(int? templateId) async {
    if (state.name.isEmpty) {
      // Ekran uyarıyı yalnızca failure durumunda gösteriyor; durum
      // güncellenmezse kaydet düğmesi sessizce hiçbir şey yapmış olmuyordu.
      emit(state.copyWith(
        status: MealTemplateEditorStatus.failure,
        error: 'Lütfen bir öğün ismi girin',
      ));
      return;
    }

    emit(state.copyWith(status: MealTemplateEditorStatus.saving));

    try {
      // Önceki denemede kayıt açılmış olabilir: aynı kaydı güncelle, yenisini açma.
      int? effectiveId = templateId ?? state.createdTemplateId;
      if (effectiveId == null) {
        final createResp = await _repository.createTemplate(state.name);
        if (createResp.success && createResp.data != null) {
          effectiveId = createResp.data!.id;
          emit(state.copyWith(createdTemplateId: effectiveId));
        } else {
          emit(state.copyWith(status: MealTemplateEditorStatus.failure, error: createResp.message));
          return;
        }
      }

      final updateResp = await _repository.updateTemplate(
        effectiveId,
        state.name,
        state.selectedMealTypes,
        state.ingredients,
      );

      if (updateResp.success) {
        emit(state.copyWith(status: MealTemplateEditorStatus.saved));
      } else {
        emit(state.copyWith(status: MealTemplateEditorStatus.failure, error: updateResp.message));
      }
    } catch (e) {
      emit(state.copyWith(status: MealTemplateEditorStatus.failure, error: friendlyError(e)));
    }
  }
}
