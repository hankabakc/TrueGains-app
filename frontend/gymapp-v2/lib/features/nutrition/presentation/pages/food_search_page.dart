import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/constants/app_strings.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:gymapp_v2/core/widgets/empty_state.dart';
import 'package:gymapp_v2/core/widgets/list_skeleton.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_history_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/ocr_scan_response_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/recipe_model.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/food_search/food_search_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/food_search/food_search_state.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';

class FoodSearchPage extends StatefulWidget {
  final int? mealId;
  final MealType? mealType;
  final bool isTemplateMode;

  const FoodSearchPage({
    super.key,
    this.mealId,
    this.mealType,
    this.isTemplateMode = false,
  });

  @override
  State<FoodSearchPage> createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends State<FoodSearchPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.isTemplateMode ? 4 : 5, vsync: this);
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
      create: (context) => sl<FoodSearchCubit>()..loadInitialData(),
      child: BlocConsumer<FoodSearchCubit, FoodSearchState>(
        listener: (context, state) {
          if (state.status == FoodSearchStatus.saved) {
            if (widget.isTemplateMode) {
              context.pop(state.basket);
            } else {
              context.pop(true);
            }
          } else if (state.error != null && state.status == FoodSearchStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          final cubit = context.read<FoodSearchCubit>();

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Besin Ekle',
                style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: AppColors.textPrimary),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                  tooltip: AppStrings.scanFood,
                  onPressed: () async {
                    final result = await context.push('/nutrition/scan', extra: {'returnToBasket': true});
                    if (!mounted) return;
                    if (result != null && result is OcrScanResponseModel && result.foodData != null) {
                      cubit.addScannedFood(result.foodData!);
                    }
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSearchTab(cubit, state),
                          _buildRecentTab(cubit, state),
                          if (!widget.isTemplateMode) _buildOverriddenTab(cubit, state),
                          _buildTemplatesTab(context, cubit, state),
                          _buildRecipesTab(context, cubit, state),
                        ],
                      ),
                    ),
                    SizedBox(height: state.basket.isEmpty ? AppSpacing.lg : 100 + MediaQuery.of(context).padding.bottom),
                  ],
                ),
                if (state.basket.isNotEmpty) _buildBasketOverlay(cubit, state),
                if (state.status == FoodSearchStatus.loading && state.basket.isEmpty)
                  const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.center,
      indicatorColor: AppColors.primary,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textMuted,
      dividerColor: Colors.transparent,
      labelStyle: AppTextStyles.buttonText.copyWith(fontSize: 13),
      tabs: [
        const Tab(text: 'ARA'),
        const Tab(text: 'GEÇMİŞ'),
        if (!widget.isTemplateMode) const Tab(text: 'DÜZENLENENLER'),
        const Tab(text: 'ŞABLONLAR'),
        const Tab(text: 'TARİFLER'),
      ],
    );
  }

  Widget _buildSearchTab(FoodSearchCubit cubit, FoodSearchState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Yemek, marka veya içerik...',
              hintStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                onPressed: () => cubit.search(_searchController.text),
              ),
              fillColor: AppColors.glassWhite,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.glassBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.glassBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
            onSubmitted: (v) => cubit.search(v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: GlassContainer(
            child: ListTile(
              leading: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
              title: Text('Manuel Besin Ekle', style: AppTextStyles.listTitle),
              subtitle: Text(
                'Bulamadığın besini kendin oluştur',
                style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted),
              ),
              onTap: () async {
                final result = await context.push('/nutrition/add-food', extra: _searchController.text.trim());
                if (!mounted) return;
                if (result is FoodModel) {
                  cubit.addScannedFood(result);
                  cubit.loadInitialData();
                }
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: _buildSearchResultsList(cubit, state),
        ),
      ],
    );
  }

  Widget _buildSearchResultsList(FoodSearchCubit cubit, FoodSearchState state) {
    if (state.status == FoodSearchStatus.searching) {
      return const ListSkeleton();
    }
    if (state.searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return _buildEmptyState('Sonuç bulunamadı.', Icons.search_off_rounded);
    }
    if (state.searchResults.isEmpty) {
      return _buildEmptyState('Örn: Izgara Tavuk, Pirinç...', Icons.restaurant_menu_rounded);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: state.searchResults.length,
      itemBuilder: (context, index) => _buildFoodTile(context, cubit, state, state.searchResults[index]),
    );
  }

  Widget _buildRecentTab(FoodSearchCubit cubit, FoodSearchState state) {
    if (state.recentGroupedFoods.isEmpty) {
      return _buildEmptyState('Henüz geçmişiniz yok.', Icons.history_rounded);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: state.recentGroupedFoods.length,
      itemBuilder: (context, index) {
        final group = state.recentGroupedFoods[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: SectionHeader(
                label: MealHistoryModel.getDisplayName(group.mealType),
                accent: AppColors.primary,
              ),
            ),
            ...group.foods.map((food) => _buildFoodTile(context, cubit, state, food)),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }

  Widget _buildOverriddenTab(FoodSearchCubit cubit, FoodSearchState state) {
    if (state.customFoods.isEmpty && state.overriddenFoods.isEmpty) {
      return _buildEmptyState('Düzenlenmiş besin bulunamadı.', Icons.edit_note_rounded);
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (state.customFoods.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: SectionHeader(
              label: 'Manuel Eklediklerim',
              accent: AppColors.primary,
            ),
          ),
          ...state.customFoods.map((food) => _buildFoodTile(context, cubit, state, food, isManual: true)),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state.overriddenFoods.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: SectionHeader(
              label: 'Düzenlediklerim',
              accent: AppColors.primary,
            ),
          ),
          ...state.overriddenFoods.map((food) => _buildFoodTile(context, cubit, state, food)),
        ],
      ],
    );
  }

  Widget _buildTemplatesTab(BuildContext context, FoodSearchCubit cubit, FoodSearchState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: PremiumButton(
            text: 'ÖĞÜN OLUŞTUR',
            onPressed: () async {
              await context.pushNamed('meal-template-editor');
              if (context.mounted) {
                cubit.loadInitialData();
              }
            },
            icon: Icons.add_circle_outline_rounded,
          ),
        ),
        Expanded(
          child: state.templates.isEmpty
            ? _buildEmptyState('Kayıtlı öğün bulunmuyor.', Icons.copy_all_rounded)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: state.templates.length,
                itemBuilder: (context, index) {
                  final template = state.templates[index];
                  final isSelected = cubit.isTemplateInBasket(template);
                  return GlassContainer(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      title: Text(template.name, style: AppTextStyles.listTitle),
                      subtitle: Text('${template.ingredients.length} ürün', style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(isSelected ? Icons.remove_circle_rounded : Icons.add_circle_rounded, color: isSelected ? AppColors.error : AppColors.primary),
                            onPressed: () => cubit.toggleTemplateSelection(template),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted),
                            onPressed: () => _showDeleteTemplateConfirmation(context, cubit, template),
                          ),
                        ],
                      ),
                      onTap: () async {
                        await context.pushNamed('meal-template-editor', extra: template);
                        if (context.mounted) {
                          cubit.loadInitialData();
                        }
                      },
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildRecipesTab(BuildContext context, FoodSearchCubit cubit, FoodSearchState state) {
    if (state.recipes.isEmpty) {
      return _buildEmptyState('Herhangi bir tarif bulunamadı.', Icons.menu_book_rounded);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: state.recipes.length,
      itemBuilder: (context, index) => _buildRecipeTile(context, cubit, state.recipes[index]),
    );
  }

  Widget _buildRecipeTile(BuildContext context, FoodSearchCubit cubit, RecipeModel recipe) {
    final imageSize = MediaQuery.of(context).size.width * 0.15;
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: recipe.imageUrl != null
              ? Image.network(
                  recipe.imageUrl!,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: imageSize,
                    height: imageSize,
                    color: AppColors.glassWhite,
                    child: Icon(Icons.restaurant, color: AppColors.textMuted, size: imageSize / 2),
                  ),
                )
              : Container(width: imageSize, height: imageSize, color: AppColors.glassWhite, child: const Icon(Icons.restaurant, color: AppColors.textMuted)),
        ),
        title: Text(recipe.name, style: AppTextStyles.listTitle),
        subtitle: Text('${recipe.category ?? "Genel"} • ${recipe.totalCalories.toInt()} kcal', style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        onTap: () async {
          final result = await context.pushNamed('recipe-details', pathParameters: {'id': recipe.id.toString()}, extra: {'isReadOnly': false});
          if (!context.mounted) return;
          if (result != null && result is List<MealIngredientModel>) {
            cubit.addIngredientsToBasket(result);
          }
        },
      ),
    );
  }

  Widget _buildFoodTile(BuildContext context, FoodSearchCubit cubit, FoodSearchState state, FoodModel food, {bool isManual = false}) {
    final isSelected = state.basket.any((s) => s.foodId == food.id && s.ignoreOverride == !food.isOverridden);
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Row(
          children: [
            Expanded(child: Text(food.name, style: AppTextStyles.listTitle)),
            if (isManual)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(4)),
                child: Text('MANUEL', style: AppTextStyles.tagText.copyWith(color: AppColors.textSecondary, fontSize: 8)),
              )
            else if (food.isOverridden)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                child: Text('SİZE ÖZEL', style: AppTextStyles.tagText.copyWith(color: AppColors.primary, fontSize: 8)),
              ),
          ],
        ),
        subtitle: Text('${food.brand ?? "Genel"}  •  ${food.calories.toInt()} kcal', style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted, fontSize: 13)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 22),
              onPressed: () async {
                final ignoreOverride = !food.isOverridden;
                final result = await context.push('/nutrition/food-details/${food.id}?ignoreOverride=$ignoreOverride');
                
                if (!context.mounted) return;
                
                // Her durumda listeleri yenile (Düzenleme veya 'Varsayılana Dön' yapılmış olabilir)
                cubit.loadInitialData();

                if (result is FoodModel) {
                  cubit.toggleFoodSelection(result);
                }
              },
            ),
            IconButton(
              icon: Icon(isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, color: AppColors.primary),
              onPressed: () => cubit.toggleFoodSelection(food),
            ),
          ],
        ),
        onTap: () => cubit.toggleFoodSelection(food),
      ),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return EmptyState(icon: icon, title: msg);
  }

  Widget _buildBasketOverlay(FoodSearchCubit cubit, FoodSearchState state) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final overlayCollapsedHeight = (MediaQuery.of(context).size.height * 0.11) + (bottomPadding > 0 ? bottomPadding / 2 : 0);
    final overlayExpandedHeight = MediaQuery.of(context).size.height * 0.55 + bottomPadding;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: 0, left: 0, right: 0,
      height: state.isBasketExpanded ? overlayExpandedHeight : overlayCollapsedHeight,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20)]
        ),
        child: ClipRect(
          child: Stack(
            children: [
              if (state.isBasketExpanded)
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(top: overlayCollapsedHeight - (bottomPadding > 0 ? bottomPadding / 2 : 0)),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildBasketItem(cubit, state, index),
                              childCount: state.basket.length,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg + bottomPadding),
                            child: PremiumButton(
                              text: widget.isTemplateMode ? 'ŞABLONA EKLE' : 'ÖĞÜNE EKLE',
                              isLoading: state.status == FoodSearchStatus.saving,
                              onPressed: () => cubit.saveAll(mealId: widget.mealId, mealType: widget.mealType, isTemplateMode: widget.isTemplateMode),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 0, left: 0, right: 0, height: overlayCollapsedHeight - (bottomPadding > 0 ? bottomPadding / 2 : 0),
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    cubit.toggleBasketExpanded();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.lg)),
                          child: Text('${state.basket.length}', style: AppTextStyles.buttonText.copyWith(color: AppColors.background)),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Seçilen Besinler', style: AppTextStyles.listTitle.copyWith(fontSize: 18, color: AppColors.textPrimary)),
                        const Spacer(),
                        Icon(state.isBasketExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded, color: AppColors.textPrimary, size: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasketItem(FoodSearchCubit cubit, FoodSearchState state, int index) {
    final item = state.basket[index];
    final isRecipe = item.recipeId != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.foodName, style: AppTextStyles.listTitle.copyWith(fontSize: 15), overflow: TextOverflow.ellipsis),
                Text('${(item.calories * item.amount / item.defaultAmount).toInt()} kcal', style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            child: isRecipe
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(AppRadius.sm)),
                    alignment: Alignment.center,
                    child: Text('1 pors.', style: AppTextStyles.listTitle.copyWith(color: AppColors.primary, fontSize: 15)),
                  )
                : TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.listTitle.copyWith(color: AppColors.primary, fontSize: 15),
                    decoration: InputDecoration(filled: true, fillColor: AppColors.glassWhite, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide.none), isDense: true),
                    controller: TextEditingController(text: item.amount.toInt().toString())..selection = TextSelection.fromPosition(TextPosition(offset: item.amount.toInt().toString().length)),
                    onChanged: (v) => cubit.updateIngredientAmount(index, double.tryParse(v) ?? 0),
                  ),
          ),
          IconButton(icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error, size: 20), onPressed: () => cubit.removeFromBasket(index)),
        ],
      ),
    );
  }

  Future<void> _showDeleteTemplateConfirmation(BuildContext context, FoodSearchCubit cubit, MealTemplateModel template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Şablonu Sil', style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary)),
        content: Text('${template.name} adlı şablonu silmek istediğinizden emin misiniz?', style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İPTAL', style: AppTextStyles.buttonText.copyWith(fontSize: 14, color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('SİL', style: AppTextStyles.buttonText.copyWith(fontSize: 14, color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.deleteTemplate(template.id);
    }
  }
}
