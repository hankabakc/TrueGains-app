import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';

/// `MealIngredientModel` eşitliği.
///
/// Equatable eşitliği yalnızca `==` çağıran kodu değil, **BLoC state karşılaştırmasını**
/// da yönetir: state'in içindeki liste eski listeyle eşit sayılırsa `emit` atlanır ve
/// ekran güncellenmez. Eşitlik alan eksik bırakıldığında ortaya çıkan hata "yanlış sonuç"
/// değil, **hiç güncellenmeyen ekran** olur; bu yüzden değer alanları da eşitliğe dahil.
void main() {
  MealIngredientModel ingredient({
    String foodName = 'Yulaf',
    double calories = 100,
    double protein = 10,
    double amount = 50,
    bool isOverridden = false,
  }) {
    return MealIngredientModel(
      id: 1,
      foodId: 7,
      foodName: foodName,
      amount: amount,
      defaultAmount: 100,
      protein: protein,
      carbs: 20,
      fat: 5,
      calories: calories,
      isBrandVerified: false,
      ignoreOverride: false,
      isOverridden: isOverridden,
      sugar: 1,
      fiber: 2,
      sodium: 3,
      potassium: 4,
      cholesterol: 5,
    );
  }

  test('aynı değerler eşit sayılır', () {
    expect(ingredient(), equals(ingredient()));
  });

  test('besin adı farklıysa eşit değildir', () {
    expect(ingredient(foodName: 'Yulaf'), isNot(equals(ingredient(foodName: 'Pirinç'))));
  });

  test('kalori farklıysa eşit değildir', () {
    // Ezme (override) uygulandığında miktar aynı kalıp makrolar değişebiliyor; bu durum
    // eşitlikte görünmezse ekran eski değerleri göstermeye devam eder.
    expect(ingredient(calories: 100), isNot(equals(ingredient(calories: 250))));
  });

  test('protein farklıysa eşit değildir', () {
    expect(ingredient(protein: 10), isNot(equals(ingredient(protein: 30))));
  });

  test('miktar ve ezme bayrağı zaten eşitliğe dahildi', () {
    expect(ingredient(amount: 50), isNot(equals(ingredient(amount: 80))));
    expect(ingredient(isOverridden: false), isNot(equals(ingredient(isOverridden: true))));
  });
}
