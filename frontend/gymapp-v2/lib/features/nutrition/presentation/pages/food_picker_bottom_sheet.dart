import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/food_picker/food_picker_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/food_picker/food_picker_state.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';

class FoodPickerBottomSheet extends StatefulWidget {
  final int mealId;
  const FoodPickerBottomSheet({super.key, required this.mealId});

  @override
  State<FoodPickerBottomSheet> createState() => _FoodPickerBottomSheetState();
}

class _FoodPickerBottomSheetState extends State<FoodPickerBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<FoodPickerCubit>()..loadInitialData(),
      child: BlocConsumer<FoodPickerCubit, FoodPickerState>(
        listener: (context, state) {
          if (state.status == FoodPickerStatus.added) {
            context.pop(true);
          } else if (state.error != null && state.status == FoodPickerStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!), backgroundColor: AppColors.error));
          }
        },
        builder: (context, state) {
          final cubit = context.read<FoodPickerCubit>();

          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            child: Column(
              children: [
                _buildHandle(),
                _buildTabBar(),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSearchTab(context, cubit, state),
                      _buildRecentTab(cubit, state),
                      _buildTemplatesTab(cubit, state),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(2)),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textMuted,
      indicatorColor: AppColors.primary,
      indicatorWeight: 3,
      dividerColor: Colors.transparent,
      labelStyle: AppTextStyles.buttonText.copyWith(fontSize: 13),
      tabs: const [
        Tab(text: 'ARAMA'),
        Tab(text: 'SON YENENLER'),
        Tab(text: 'ŞABLONLAR'),
      ],
    );
  }

  Widget _buildSearchTab(BuildContext context, FoodPickerCubit cubit, FoodPickerState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            style: AppTextStyles.bodyText,
            decoration: InputDecoration(
              hintText: 'Besin ara...',
              hintStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textMuted),
                onPressed: () {
                  _searchController.clear();
                  cubit.search('');
                },
              ),
              filled: true,
              fillColor: AppColors.glassWhite,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.glassBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.glassBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.primary)),
            ),
            onChanged: (query) => cubit.search(query),
          ),
        ),
        Expanded(
          child: state.status == FoodPickerStatus.searching
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : state.searchResults.isEmpty
                  ? _buildEmptyState(_searchController.text.isEmpty ? 'Aramak istediğiniz besini yazın' : 'Besin bulunamadı', Icons.search_off_rounded)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: state.searchResults.length,
                      itemBuilder: (context, index) => _buildFoodTile(context, cubit, state.searchResults[index]),
                    ),
        ),
      ],
    );
  }

  Widget _buildRecentTab(FoodPickerCubit cubit, FoodPickerState state) {
    if (state.status == FoodPickerStatus.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (state.recentFoods.isEmpty) {
      return _buildEmptyState('Henüz bir kayıt yok', Icons.history_rounded);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: state.recentFoods.length,
      itemBuilder: (context, index) => _buildFoodTile(context, cubit, state.recentFoods[index]),
    );
  }

  Widget _buildTemplatesTab(FoodPickerCubit cubit, FoodPickerState state) {
    if (state.status == FoodPickerStatus.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (state.templates.isEmpty) {
      return _buildEmptyState('Kayıtlı şablon bulunmuyor', Icons.list_alt_rounded);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: state.templates.length,
      itemBuilder: (context, index) {
        final template = state.templates[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: ListTile(
            title: Text(template.name, style: AppTextStyles.listTitle),
            subtitle: Text('${template.ingredients.length} Besin', style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
          ),
        );
      },
    );
  }

  Widget _buildFoodTile(BuildContext context, FoodPickerCubit cubit, FoodModel food) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primary.withAlpha(25), borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 20),
        ),
        title: Row(
          children: [
            Expanded(child: Text(food.name, style: AppTextStyles.listTitle, maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (food.isOverridden)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
                child: Text('ÖZEL', style: AppTextStyles.tagText.copyWith(color: AppColors.primary, fontSize: 9)),
              ),
            if (food.isBrandVerified) const Padding(padding: EdgeInsets.only(left: 4.0), child: Icon(Icons.verified_rounded, color: Colors.blue, size: 14)),
          ],
        ),
        subtitle: Text('${food.brand ?? "Genel"} • ${food.calories.toInt()} kcal', style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted)),
        trailing: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
        onTap: () => _showAmountPicker(context, cubit, food),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  void _showAmountPicker(BuildContext context, FoodPickerCubit cubit, FoodModel food) {
    cubit.selectFood(food);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BlocProvider.value(
        value: cubit,
        child: _AmountPickerView(mealId: widget.mealId),
      ),
    );
  }
}

class _AmountPickerView extends StatelessWidget {
  final int mealId;
  const _AmountPickerView({required this.mealId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FoodPickerCubit, FoodPickerState>(
      builder: (context, state) {
        final food = state.selectedFood!;
        final cubit = context.read<FoodPickerCubit>();

        final calories = (food.calories * state.amount / food.defaultAmount).toStringAsFixed(1);
        final protein = (food.protein * state.amount / food.defaultAmount).toStringAsFixed(1);
        final carbs = (food.carbs * state.amount / food.defaultAmount).toStringAsFixed(1);
        final fat = (food.fat * state.amount / food.defaultAmount).toStringAsFixed(1);

        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 32,
            bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 32,
          ),
          decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(food.name, style: AppTextStyles.heroTitle),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.bodyText,
                      decoration: InputDecoration(
                        labelText: 'Miktar (${food.defaultUnit})',
                        labelStyle: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.glassWhite,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
                      ),
                      controller: TextEditingController(text: state.amount.toInt().toString())..selection = TextSelection.fromPosition(TextPosition(offset: state.amount.toInt().toString().length)),
                      onChanged: (val) => cubit.updateAmount(double.tryParse(val) ?? 0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.primary.withAlpha(25), borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Column(
                      children: [
                        Text(calories, style: AppTextStyles.cardValue.copyWith(color: AppColors.primary, fontSize: 20)),
                        Text('kcal', style: AppTextStyles.cardCaption.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniMacro('P', protein, AppColors.protein),
                  _miniMacro('C', carbs, AppColors.carbs),
                  _miniMacro('F', fat, AppColors.fat),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: state.status == FoodPickerStatus.adding ? null : () => cubit.addIngredient(mealId),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)), elevation: 0),
                child: state.status == FoodPickerStatus.adding
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : Text('Öğüne Ekle', style: AppTextStyles.buttonText.copyWith(color: Colors.black)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _miniMacro(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 4),
        Text('$value g', style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
