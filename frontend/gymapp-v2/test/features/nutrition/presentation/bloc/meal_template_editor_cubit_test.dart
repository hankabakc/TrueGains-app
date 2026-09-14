import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/meal_template_editor/meal_template_editor_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/meal_template_editor/meal_template_editor_state.dart';
import 'package:mocktail/mocktail.dart';

class MockNutritionRepository extends Mock implements NutritionRepository {}

ApiResponse<T> ok<T>(T? data) =>
    ApiResponse<T>(success: true, message: '', data: data, timestamp: '2026-01-01T00:00:00Z');

ApiResponse<T> fail<T>(String message) =>
    ApiResponse<T>(success: false, message: message, data: null, timestamp: '2026-01-01T00:00:00Z');

/// Öğün şablonu düzenleyicisi.
///
/// Kaydetme iki adımlıdır: önce sunucuda boş kayıt açılır, sonra içeriği yazılır.
/// İkinci adım başarısız olursa kullanıcı tekrar dener — ve ilk adım hatırlanmazsa
/// **her denemede yeni bir boş şablon** oluşur. Bu dosyanın asıl konusu budur.
void main() {
  late MockNutritionRepository repository;

  MealIngredientModel ingredient(String name, {double amount = 100}) {
    return MealIngredientModel(
      foodName: name,
      amount: amount,
      defaultAmount: 100,
      protein: 10,
      carbs: 20,
      fat: 5,
      calories: 165,
      isBrandVerified: false,
      ignoreOverride: false,
      isOverridden: false,
      sugar: 1,
      fiber: 2,
      sodium: 3,
      potassium: 4,
      cholesterol: 5,
    );
  }

  setUp(() {
    repository = MockNutritionRepository();
  });

  group('yarıda kalan kaydetme', () {
    test('tekrar denendiğinde ikinci bir boş şablon oluşturulmaz', () async {
      final cubit = MealTemplateEditorCubit(repository);
      cubit.updateName('Kahvaltı');
      cubit.addIngredients([ingredient('Yumurta')]);

      when(() => repository.createTemplate(any()))
          .thenAnswer((_) async => ok(MealTemplateModel(
                id: 55,
                name: 'Kahvaltı',
                applicableMealTypes: const [],
                ingredients: const [],
              )));
      when(() => repository.updateTemplate(any(), any(), any(), any()))
          .thenAnswer((_) async => fail<void>('Bağlantı koptu'));

      await cubit.saveTemplate(null);
      await cubit.saveTemplate(null); // kullanıcı tekrar dener

      // Kayıt bir kez açılmalı; aksi hâlde her denemede listede boş şablon birikir.
      verify(() => repository.createTemplate(any())).called(1);
      verify(() => repository.updateTemplate(55, any(), any(), any())).called(2);
      await cubit.close();
    });

    test('malzemeler hata sonrası taslakta kalır', () async {
      final cubit = MealTemplateEditorCubit(repository);
      cubit.updateName('Kahvaltı');
      cubit.addIngredients([ingredient('Yumurta'), ingredient('Peynir')]);

      when(() => repository.createTemplate(any()))
          .thenAnswer((_) async => fail<MealTemplateModel>('Sunucu hatası'));

      await cubit.saveTemplate(null);

      expect(cubit.state.status, MealTemplateEditorStatus.failure);
      expect(cubit.state.ingredients, hasLength(2));
      await cubit.close();
    });
  });

  group('kaydetme', () {
    test('mevcut şablon düzenlenirken yeni kayıt açılmaz', () async {
      final cubit = MealTemplateEditorCubit(repository);
      cubit.updateName('Öğle');
      when(() => repository.updateTemplate(any(), any(), any(), any()))
          .thenAnswer((_) async => ok<void>(null));

      await cubit.saveTemplate(12);

      verifyNever(() => repository.createTemplate(any()));
      verify(() => repository.updateTemplate(12, 'Öğle', any(), any())).called(1);
      expect(cubit.state.status, MealTemplateEditorStatus.saved);
      await cubit.close();
    });

    test('malzemeler sunucuya birlikte gönderilir', () async {
      final cubit = MealTemplateEditorCubit(repository);
      cubit.updateName('Öğle');
      cubit.addIngredients([ingredient('Pilav'), ingredient('Tavuk')]);

      List<MealIngredientModel>? sent;
      when(() => repository.updateTemplate(any(), any(), any(), any()))
          .thenAnswer((invocation) async {
        sent = invocation.positionalArguments[3] as List<MealIngredientModel>;
        return ok<void>(null);
      });

      await cubit.saveTemplate(12);

      expect(sent!.map((e) => e.foodName), ['Pilav', 'Tavuk']);
      await cubit.close();
    });
  });

  group('isim doğrulaması', () {
    test('boş isimde kullanıcıya hata bildirilir', () async {
      final cubit = MealTemplateEditorCubit(repository);

      await cubit.saveTemplate(null);

      // Ekran uyarıyı yalnızca failure durumunda gösteriyor; durum
      // güncellenmezse düğme sessizce hiçbir şey yapmış olur.
      expect(cubit.state.status, MealTemplateEditorStatus.failure);
      expect(cubit.state.error, 'Lütfen bir öğün ismi girin');
      await cubit.close();
    });

    test('boş isimde sunucuya hiç istek gitmez', () async {
      final cubit = MealTemplateEditorCubit(repository);

      await cubit.saveTemplate(null);

      verifyNever(() => repository.createTemplate(any()));
      verifyNever(() => repository.updateTemplate(any(), any(), any(), any()));
      await cubit.close();
    });
  });

  group('malzeme düzenleme', () {
    test('silinen malzeme listeden çıkar, diğerleri kalır', () async {
      final cubit = MealTemplateEditorCubit(repository);
      cubit.addIngredients([ingredient('Pilav'), ingredient('Tavuk')]);

      cubit.removeIngredientAt(1);

      expect(cubit.state.ingredients.map((e) => e.foodName), ['Pilav']);
      await cubit.close();
    });

    test('aynı besin iki kez eklendiyse düzenlenen satır değişir', () async {
      final cubit = MealTemplateEditorCubit(repository);
      // Aynı besin, aynı miktar: iki satır değer olarak birbirinin aynısı.
      // Malzemeler değere göre aranırsa ikinci satır düzenlendiğinde birinci
      // satır değişir ve kullanıcı dokunduğu satırın güncellenmediğini görür.
      cubit.addIngredients([ingredient('Yumurta'), ingredient('Yumurta')]);

      cubit.updateIngredientAmountAt(1, 250);

      expect(cubit.state.ingredients[0].amount, 100);
      expect(cubit.state.ingredients[1].amount, 250);
      await cubit.close();
    });

    test('aynı besin iki kez eklendiyse silinen satır doğru olandır', () async {
      final cubit = MealTemplateEditorCubit(repository);
      cubit.addIngredients([ingredient('Yumurta', amount: 100), ingredient('Yumurta', amount: 200)]);

      cubit.removeIngredientAt(0);

      expect(cubit.state.ingredients.single.amount, 200);
      await cubit.close();
    });
  });
}
