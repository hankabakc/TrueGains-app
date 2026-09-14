import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/diet_program_model.dart';
import '../../data/models/meal_template_model.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import '../bloc/save_recipe_modal/save_recipe_modal_cubit.dart';
import '../bloc/save_recipe_modal/save_recipe_modal_state.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';

class SaveRecipeModal extends StatelessWidget {
  final DietProgramModel program;
  final int recipeId;
  final String recipeName;
  final void Function(int mealId) onSave;

  const SaveRecipeModal({
    super.key,
    required this.program,
    required this.recipeId,
    required this.recipeName,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SaveRecipeModalCubit>(),
      child: BlocBuilder<SaveRecipeModalCubit, SaveRecipeModalState>(
        builder: (context, state) {
          final cubit = context.read<SaveRecipeModalCubit>();
          final selectedDay = program.dietDays[state.selectedDayIndex];

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tarifi Programa Kaydet', style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary, fontSize: 18)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(recipeName, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: program.dietDays.length,
                    itemBuilder: (context, index) {
                      final isSelected = state.selectedDayIndex == index;
                      return GestureDetector(
                        onTap: () => cubit.setDay(index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(color: isSelected ? AppColors.primary : AppColors.card, borderRadius: BorderRadius.circular(15)),
                          child: Center(child: Text(program.dietDays[index].name, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: selectedDay.meals.length,
                    itemBuilder: (context, index) {
                      final meal = selectedDay.meals[index];
                      return _buildMealItem(context, meal, state.selectedDayIndex);
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealItem(BuildContext context, MealModel meal, int selectedDayIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_getMealIcon(meal.mealType), color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(meal.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton(
                onPressed: () => _confirmAndSave(context, meal, selectedDayIndex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Buraya Ekle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (meal.ingredients.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...meal.ingredients.take(2).map((ing) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 4, color: Colors.white54),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${ing.foodName} (${ing.amount.toStringAsFixed(0)}g)', style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                )),
            if (meal.ingredients.length > 2) Text('+${meal.ingredients.length - 2} içerik daha...', style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ] else
            const Padding(padding: EdgeInsets.only(top: 10), child: Text('Bu öğün henüz boş', style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic))),
        ],
      ),
    );
  }

  IconData _getMealIcon(MealType type) {
    switch (type) {
      case MealType.kahvalti: return Icons.wb_sunny_outlined;
      case MealType.ogleYemegi: return Icons.wb_cloudy_outlined;
      case MealType.aksamYemegi: return Icons.nightlight_round_outlined;
      default: return Icons.restaurant_menu_outlined;
    }
  }

  void _confirmAndSave(BuildContext context, MealModel meal, int selectedDayIndex) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Emin misiniz?', style: TextStyle(color: Colors.white)),
        content: Text('$recipeName tarifini ${program.dietDays[selectedDayIndex].name} - ${meal.name} öğününe eklemek istediğinize emin misiniz?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Close bottom sheet
              onSave(meal.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Evet, Ekle', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
