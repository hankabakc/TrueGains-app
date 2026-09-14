import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/empty_state.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:gymapp_v2/features/nutrition/data/models/meal_template_model.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/meal_template_editor/meal_template_editor_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/meal_template_editor/meal_template_editor_state.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';

class MealTemplateEditorPage extends StatefulWidget {
  final int? templateId;
  final MealTemplateModel? template;

  const MealTemplateEditorPage({super.key, this.templateId, this.template});

  @override
  State<MealTemplateEditorPage> createState() => _MealTemplateEditorPageState();
}

class _MealTemplateEditorPageState extends State<MealTemplateEditorPage> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<MealTemplateEditorCubit>()..initialize(widget.template, widget.templateId),
      child: BlocConsumer<MealTemplateEditorCubit, MealTemplateEditorState>(
        listener: (context, state) {
          if (state.status == MealTemplateEditorStatus.saved) {
            context.pop(true);
          } else if (state.status == MealTemplateEditorStatus.success && _nameController.text.isEmpty) {
            _nameController.text = state.name;
          } else if (state.error != null && state.status == MealTemplateEditorStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          final cubit = context.read<MealTemplateEditorCubit>();

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
              title: Text(
                widget.templateId == null && widget.template == null ? 'Yeni Öğün Oluştur' : 'Öğünü Düzenle',
                style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: AppColors.textPrimary),
              ),
            ),
            body: state.status == MealTemplateEditorStatus.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : Column(
                    children: [
                      _buildStepIndicator(state.currentPage),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (page) => cubit.setPage(page),
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            _buildPage1(context, cubit, state),
                            _buildPage2(context, cubit, state),
                          ],
                        ),
                      ),
                    ],
                  ),
            bottomNavigationBar: _buildBottomNav(context, cubit, state),
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator(int currentPage) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _indicatorStep(0, 'İçerik', currentPage),
          Container(
            width: AppSpacing.xl,
            height: 2,
            margin: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            color: currentPage >= 1 ? AppColors.primary : AppColors.glassBorder,
          ),
          _indicatorStep(1, 'Özet', currentPage),
        ],
      ),
    );
  }

  Widget _indicatorStep(int page, String label, int currentPage) {
    bool isCurrent = currentPage == page;
    bool isDone = currentPage > page;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrent || isDone ? AppColors.primary : AppColors.glassBorder,
            boxShadow: isCurrent ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 10)] : null,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.cardCaption.copyWith(
            color: isCurrent ? AppColors.textPrimary : AppColors.textMuted,
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildPage1(BuildContext context, MealTemplateEditorCubit cubit, MealTemplateEditorState state) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(label: 'ÖĞÜN ETİKETLERİ'),
          SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              return Theme(
                data: Theme.of(context).copyWith(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: PopupMenuButton<MealType>(
                  offset: const Offset(0, 60),
                  color: AppColors.card,
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                    maxWidth: constraints.maxWidth,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    side: const BorderSide(color: AppColors.glassBorder),
                  ),
                  onSelected: (type) => cubit.toggleMealType(type),
                  itemBuilder: (context) => [
                    MealType.kahvalti,
                    MealType.ogleYemegi,
                    MealType.aksamYemegi,
                    MealType.other,
                  ].map((type) {
                    bool isSelected = state.selectedMealTypes.contains(type);
                    return PopupMenuItem<MealType>(
                      value: type,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                              color: isSelected ? AppColors.primary : AppColors.textMuted,
                              size: 18,
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              _getTrMealTypeName(type),
                              style: AppTextStyles.bodyText.copyWith(
                                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  child: GlassContainer(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(Icons.label_important_outline_rounded,
                          color: state.selectedMealTypes.isNotEmpty ? AppColors.primary : AppColors.textMuted),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            state.selectedMealTypes.isEmpty
                              ? 'Öğün Etiketi Seçin'
                              : state.selectedMealTypes.map((t) => _getTrMealTypeName(t)).join(', '),
                            style: AppTextStyles.bodyText.copyWith(
                              color: state.selectedMealTypes.isNotEmpty ? AppColors.textPrimary : AppColors.textMuted,
                              fontWeight: state.selectedMealTypes.isNotEmpty ? FontWeight.bold : FontWeight.normal
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          ),
          SizedBox(height: AppSpacing.xl),
          const SectionHeader(label: 'BESİNLER'),
          SizedBox(height: AppSpacing.sm),
          if (state.ingredients.isEmpty)
            const EmptyState(
              icon: Icons.restaurant_menu_rounded,
              title: 'Henüz besin eklenmedi',
            )
          else
            ...state.ingredients.asMap().entries.map(
              (entry) => _buildIngredientTile(context, cubit, entry.key, entry.value),
            ),
          SizedBox(height: AppSpacing.lg),
          PremiumButton(
            text: 'BESİN EKLE',
            onPressed: () async {
              final result = await context.push('/nutrition/search', extra: {'isTemplateMode': true});
              if (result is List<MealIngredientModel>) {
                cubit.addIngredients(result);
              }
            },
            icon: Icons.add_rounded,
          ),
          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildIngredientTile(
      BuildContext context, MealTemplateEditorCubit cubit, int index, MealIngredientModel ing) {
    final bool isRecipe = ing.recipeId != null;

    return GlassContainer(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(ing.foodName, style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary)),
            ),
            if (isRecipe)
              Container(
                margin: EdgeInsets.only(left: AppSpacing.xs),
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm / 3),
                ),
                child: Text('TARİF', style: AppTextStyles.tagText.copyWith(color: AppColors.primary, fontSize: 8)),
              ),
          ],
        ),
        subtitle: Text(
          isRecipe ? '${ing.calories.toInt()} kcal' : '${ing.amount.toInt()}g  •  ${(ing.calories * (ing.amount / (ing.defaultAmount > 0 ? ing.defaultAmount : 100))).toInt()} kcal',
          style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted)
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRecipe)
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                onPressed: () => _editIngredientAmount(context, cubit, index, ing),
              ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error, size: 20),
              onPressed: () => cubit.removeIngredientAt(index),
            ),
          ],
        ),
      ),
    );
  }

  String _getTrMealTypeName(MealType type) {
    switch (type) {
      case MealType.kahvalti: return 'Kahvaltı';
      case MealType.ogleYemegi: return 'Öğle Yemeği';
      case MealType.aksamYemegi: return 'Akşam Yemeği';
      case MealType.other: return 'Diğer';
    }
  }

  Future<void> _editIngredientAmount(BuildContext context, MealTemplateEditorCubit cubit, int index,
      MealIngredientModel ing) async {
    final controller = TextEditingController(text: ing.amount.toInt().toString());
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Gramaj Ayarla', style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: AppTextStyles.listTitle.copyWith(color: AppColors.primary, fontSize: 24),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            suffixText: 'g',
            suffixStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
            border: InputBorder.none,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('İPTAL', style: AppTextStyles.buttonText.copyWith(color: AppColors.textMuted))),
          TextButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
            child: Text('TAMAM', style: AppTextStyles.buttonText.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (result != null) {
      cubit.updateIngredientAmountAt(index, result);
    }
  }

  Widget _buildPage2(BuildContext context, MealTemplateEditorCubit cubit, MealTemplateEditorState state) {
    double totalCal = 0, totalPro = 0, totalCarb = 0, totalFat = 0;
    double totalSugar = 0, totalFiber = 0, totalSodium = 0, totalPotassium = 0, totalCholesterol = 0;

    for (var ing in state.ingredients) {
      final bool isRecipe = ing.recipeId != null;
      double factor = isRecipe ? 1.0 : ing.amount / (ing.defaultAmount > 0 ? ing.defaultAmount : 100);

      totalCal += ing.calories * factor;
      totalPro += ing.protein * factor;
      totalCarb += ing.carbs * factor;
      totalFat += ing.fat * factor;
      totalSugar += ing.sugar * factor;
      totalFiber += ing.fiber * factor;
      totalSodium += ing.sodium * factor;
      totalPotassium += ing.potassium * factor;
      totalCholesterol += ing.cholesterol * factor;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(label: 'ÖĞÜN ADI'),
          SizedBox(height: AppSpacing.sm),
          GlassContainer(
            child: TextField(
              controller: _nameController,
              onChanged: (v) => cubit.updateName(v),
              style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Örn: Fit Kahvaltı',
                hintStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
                contentPadding: EdgeInsets.all(AppSpacing.lg),
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          const SectionHeader(label: 'BESİN DEĞERLERİ ÖZETİ'),
          SizedBox(height: AppSpacing.sm),
          GlassContainer(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _buildSummaryRow('Toplam Kalori', totalCal, 'kcal', AppColors.primary),
                Divider(color: AppColors.glassBorder, height: AppSpacing.xl),
                _buildSummaryRow('Protein', totalPro, 'g', AppColors.protein),
                SizedBox(height: AppSpacing.md),
                _buildSummaryRow('Karbonhidrat', totalCarb, 'g', AppColors.carbs),
                SizedBox(height: AppSpacing.md),
                _buildSummaryRow('Yağ', totalFat, 'g', AppColors.fat),
                Divider(color: AppColors.glassBorder, height: AppSpacing.xl),
                _buildSummaryRow('Şeker', totalSugar, 'g', AppColors.textSecondary),
                SizedBox(height: AppSpacing.md),
                _buildSummaryRow('Lif', totalFiber, 'g', AppColors.textSecondary),
                SizedBox(height: AppSpacing.md),
                _buildSummaryRow('Sodyum', totalSodium, 'mg', AppColors.textSecondary),
                SizedBox(height: AppSpacing.md),
                _buildSummaryRow('Potasyum', totalPotassium, 'mg', AppColors.textSecondary),
                SizedBox(height: AppSpacing.md),
                _buildSummaryRow('Kolesterol', totalCholesterol, 'mg', AppColors.textSecondary),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          const SectionHeader(label: 'BİLGİ'),
          SizedBox(height: AppSpacing.sm),
          Text('Bu öğün şablonu kaydedildiğinde "Öğünler" sekmesinden tek tıkla eklenebilir hale gelecektir.',
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, height: 1.5)),
          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, String unit, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary))),
        Text('${value.toStringAsFixed(1)} $unit', style: AppTextStyles.listTitle.copyWith(color: color, fontSize: 18)),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context, MealTemplateEditorCubit cubit, MealTemplateEditorState state) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, MediaQuery.of(context).padding.bottom + AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        children: [
          if (state.currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.glassBorder),
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                child: Text('GERİ', style: AppTextStyles.buttonText.copyWith(color: AppColors.textPrimary)),
              ),
            ),
          if (state.currentPage > 0) SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: PremiumButton(
              text: state.currentPage < 1 ? 'İLERİ' : (widget.templateId == null && widget.template == null ? 'OLUŞTUR' : 'GÜNCELLE'),
              onPressed: () {
                if (state.currentPage < 1) {
                  _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                } else {
                  cubit.saveTemplate(widget.templateId ?? widget.template?.id);
                }
              },
              isLoading: state.status == MealTemplateEditorStatus.saving,
            ),
          ),
        ],
      ),
    );
  }
}
