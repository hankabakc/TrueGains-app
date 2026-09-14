import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/food_details/food_details_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/food_details/food_details_state.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';

class FoodDetailsPage extends StatelessWidget {
  final int? foodId;
  final String? barcode;
  final bool isReadOnly;
  final bool isDashboardEdit;
  final bool ignoreOverride;
  final FoodModel? extraFood;
  final double? initialAmount;

  const FoodDetailsPage({
    super.key,
    this.foodId,
    this.barcode,
    this.isReadOnly = false,
    this.isDashboardEdit = false,
    this.ignoreOverride = false,
    this.extraFood,
    this.initialAmount,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<FoodDetailsCubit>()
        ..initialize(
          foodId: foodId,
          barcode: barcode,
          extraFood: extraFood,
          initialAmount: initialAmount,
          ignoreOverride: ignoreOverride,
        ),
      child: BlocConsumer<FoodDetailsCubit, FoodDetailsState>(
        listener: (context, state) {
          if (state.status == FoodDetailsStatus.saved) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Besin değerleri güncellendi.')));
            Navigator.pop(context, state.food?.copyWith(defaultAmount: state.consumedAmount));
          } else if (state.error != null && state.status == FoodDetailsStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: ${state.error}')));
          }
        },
        builder: (context, state) {
          final cubit = context.read<FoodDetailsCubit>();

          if (state.status == FoodDetailsStatus.loading) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }

          final food = state.food;
          if (food == null) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: Text(state.error ?? 'Besin bulunamadı.', style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary))),
            );
          }

          return PopScope(
            canPop: true,
            onPopInvokedWithResult: (bool didPop, dynamic result) {
              // Handle pop if needed
            },
            child: Scaffold(
              backgroundColor: AppColors.background,
              body: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(context, cubit, state),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, cubit, state),
                          const SizedBox(height: AppSpacing.xl),
                          if (!state.isEditing) _buildMainMacros(state),
                          if (!state.isEditing) const SizedBox(height: AppSpacing.xl),
                          _buildDetailedNutrition(context, cubit, state),
                          if (isReadOnly) _buildReadOnlyAlert(),
                          const SizedBox(height: AppLayout.bottomNavClearance),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              floatingActionButton: _buildFAB(context, cubit, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, FoodDetailsCubit cubit, FoodDetailsState state) {
    final food = state.food!;
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.background],
                ),
              ),
            ),
            Icon(Icons.restaurant_menu_rounded, size: 100, color: AppColors.textPrimary.withValues(alpha: 0.05)),
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.glassWhite,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Text('Detaylı Analiz', style: AppTextStyles.tagText.copyWith(color: AppColors.textPrimary, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!isReadOnly && !isDashboardEdit)
          IconButton(
            icon: Icon(state.isEditing ? Icons.close_rounded : Icons.edit_note_rounded, color: state.isEditing ? AppColors.error : AppColors.textSecondary),
            tooltip: state.isEditing ? 'Düzenlemeyi Kapat' : 'Düzenle',
            onPressed: () => cubit.toggleEditing(),
          ),
        if (food.isOverridden && !isReadOnly && !isDashboardEdit)
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.warning),
            tooltip: 'Varsayılana Dön',
            onPressed: () => cubit.deleteOverride(),
          ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, FoodDetailsCubit cubit, FoodDetailsState state) {
    final food = state.food!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(food.name, style: AppTextStyles.heroDisplay.copyWith(color: AppColors.textPrimary, fontSize: 32))),
            if (food.isOverridden)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text('ÖZEL', style: AppTextStyles.tagText.copyWith(color: AppColors.primary, fontSize: 10)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('${food.brand ?? "Genel Üretim"} • ${food.category ?? "Besin Kümesi"}', style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary, fontSize: 16)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Icon(Icons.scale_rounded, color: AppColors.textMuted, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text('Porsiyon: ${food.defaultAmount}${food.defaultUnit}', style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted, fontSize: 14)),
          ],
        ),
        if (food.barcode != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.qr_code_rounded, color: AppColors.textMuted, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text('Barkod: ${food.barcode}', style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted, fontSize: 14)),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.glassWhite,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Text('Tüketilen Miktar:', style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: state.consumedAmount.toInt().toString())..selection = TextSelection.fromPosition(TextPosition(offset: state.consumedAmount.toInt().toString().length)),
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.listTitle.copyWith(color: AppColors.primary, fontSize: 18),
                  decoration: const InputDecoration(border: InputBorder.none, hintText: '0', hintStyle: TextStyle(color: AppColors.textMuted), suffixText: 'g', suffixStyle: TextStyle(color: AppColors.primary)),
                  onChanged: (value) => cubit.updateConsumedAmount(double.tryParse(value) ?? 0.0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainMacros(FoodDetailsState state) {
    final food = state.food!;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _macroCircle('Kalori', state.calculateValue(food.calories).toInt().toString(), 'kcal', AppColors.primary),
          const SizedBox(width: AppSpacing.lg),
          _macroCircle('Protein', state.calculateValue(food.protein).toInt().toString(), 'g', AppColors.protein),
          const SizedBox(width: AppSpacing.lg),
          _macroCircle('Karb', state.calculateValue(food.carbs).toInt().toString(), 'g', AppColors.carbs),
          const SizedBox(width: AppSpacing.lg),
          _macroCircle('Yağ', state.calculateValue(food.fat).toInt().toString(), 'g', AppColors.fat),
        ],
      ),
    );
  }

  Widget _macroCircle(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.cardValue.copyWith(color: color, fontSize: 24)),
        Text(unit, style: AppTextStyles.cardCaption.copyWith(color: color.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: AppTextStyles.cardLabel.copyWith(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _buildDetailedNutrition(BuildContext context, FoodDetailsCubit cubit, FoodDetailsState state) {
    final food = state.food!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mikro Besinler', style: AppTextStyles.emptyTitle.copyWith(color: AppColors.textPrimary, fontSize: 20)),
        const SizedBox(height: AppSpacing.lg),
        if (state.isEditing) ...[
          _detailRow('Protein', state.protein, 'g', (v) => cubit.updateEditingValue('protein', v), isEditing: true),
          _detailRow('Karbonhidrat', state.carbs, 'g', (v) => cubit.updateEditingValue('carbs', v), isEditing: true),
          _detailRow('Yağ', state.fat, 'g', (v) => cubit.updateEditingValue('fat', v), isEditing: true),
          const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.md), child: Divider(color: AppColors.glassBorder)),
        ],
        _detailRow('Şeker', state.isEditing ? state.sugar : state.calculateValue(food.sugar), 'g', (v) => cubit.updateEditingValue('sugar', v), isEditing: state.isEditing),
        _detailRow('Lif', state.isEditing ? state.fiber : state.calculateValue(food.fiber), 'g', (v) => cubit.updateEditingValue('fiber', v), isEditing: state.isEditing),
        _detailRow('Sodyum', state.isEditing ? state.sodium : state.calculateValue(food.sodium), 'mg', (v) => cubit.updateEditingValue('sodium', v), isEditing: state.isEditing),
        _detailRow('Kolesterol', state.isEditing ? state.cholesterol : state.calculateValue(food.cholesterol), 'mg', (v) => cubit.updateEditingValue('cholesterol', v), isEditing: state.isEditing),
        _detailRow('Potasyum', state.isEditing ? state.potassium : state.calculateValue(food.potassium), 'mg', (v) => cubit.updateEditingValue('potassium', v), isEditing: state.isEditing),
        const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.md), child: Divider(color: AppColors.glassBorder)),
        _detailRow('Doymuş Yağ', state.isEditing ? state.satFat : state.calculateValue(food.satFat), 'g', (v) => cubit.updateEditingValue('satFat', v), isEditing: state.isEditing, isSub: true),
        _detailRow('Trans Yağ', state.isEditing ? state.transFat : state.calculateValue(food.transFat), 'g', (v) => cubit.updateEditingValue('transFat', v), isEditing: state.isEditing, isSub: true),
        _detailRow('Tekli Doymamış Yağ', state.isEditing ? state.monoFat : state.calculateValue(food.monoFat), 'g', (v) => cubit.updateEditingValue('monoFat', v), isEditing: state.isEditing, isSub: true),
        _detailRow('Çoklu Doymamış Yağ', state.isEditing ? state.polyFat : state.calculateValue(food.polyFat), 'g', (v) => cubit.updateEditingValue('polyFat', v), isEditing: state.isEditing, isSub: true),
      ],
    );
  }

  Widget _detailRow(String label, double? value, String unit, void Function(double)? onChanged, {bool isSub = false, bool isEditing = false}) {
    final String displayValue = value?.toInt().toString() ?? '0';
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md, left: isSub ? 20 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary, fontSize: 16)),
          if (isEditing && !isReadOnly && onChanged != null)
            SizedBox(
              width: 90,
              height: 40,
              child: TextField(
                controller: TextEditingController(text: displayValue)..selection = TextSelection.fromPosition(TextPosition(offset: displayValue.length)),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.listTitle.copyWith(color: AppColors.primary, fontSize: 14),
                decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12), filled: true, fillColor: AppColors.glassWhite, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide.none)),
                onChanged: (v) => onChanged(double.tryParse(v) ?? 0.0),
              ),
            )
          else
            Text('$displayValue $unit', style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildReadOnlyAlert() {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xl),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.warning.withValues(alpha: 0.2))),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: AppColors.warning, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text('Antrenör programı olduğu için bu değerler üzerinde değişiklik yapılamaz.', style: AppTextStyles.bodyText.copyWith(color: AppColors.warning, fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget? _buildFAB(BuildContext context, FoodDetailsCubit cubit, FoodDetailsState state) {
    if (isReadOnly) return null;

    if (!state.isEditing) {
      if (ignoreOverride) {
        return FloatingActionButton.extended(
          onPressed: () => Navigator.pop(context, state.food?.copyWith(defaultAmount: state.consumedAmount)),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          icon: const Icon(Icons.check_rounded),
          label: Text('TAMAM', style: AppTextStyles.buttonText.copyWith(color: AppColors.background)),
        );
      }
      return null;
    }

    final isSaving = state.status == FoodDetailsStatus.saving;
    return FloatingActionButton.extended(
      onPressed: isSaving ? null : () => cubit.saveOverride(),
      backgroundColor: isSaving ? AppColors.textMuted : AppColors.success,
      foregroundColor: AppColors.textPrimary,
      icon: isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.textPrimary, strokeWidth: 2)) : const Icon(Icons.check_circle_rounded),
      label: Text(isSaving ? 'KAYDEDİLİYOR...' : (ignoreOverride ? 'GÜNCELLE' : 'SİZE ÖZEL KAYDET'), style: AppTextStyles.buttonText.copyWith(color: AppColors.textPrimary)),
    );
  }
}
