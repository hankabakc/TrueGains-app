import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/add_food/add_custom_food_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/add_food/add_custom_food_state.dart';

class AddCustomFoodPage extends StatefulWidget {
  final String? prefillName;

  const AddCustomFoodPage({
    super.key,
    this.prefillName,
  });

  @override
  State<AddCustomFoodPage> createState() => _AddCustomFoodPageState();
}

class _AddCustomFoodPageState extends State<AddCustomFoodPage> {
  static const List<String> _units = ['g', 'ml', 'adet', 'porsiyon'];
  static const List<String> _categories = [
    'Kahvaltılık',
    'Et, Tavuk & Balık',
    'Sebze',
    'Meyve',
    'Süt Ürünleri',
    'Tahıl & Bakliyat',
    'Atıştırmalık',
    'İçecek',
    'Takviye',
    'Diğer',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _amountController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;

  String _selectedUnit = 'g';
  String? _selectedCategory;

  // Micro nutrients controllers
  late final TextEditingController _sugarController;
  late final TextEditingController _fiberController;
  late final TextEditingController _sodiumController;
  late final TextEditingController _cholesterolController;
  late final TextEditingController _potassiumController;
  late final TextEditingController _satFatController;
  late final TextEditingController _transFatController;
  late final TextEditingController _monoFatController;
  late final TextEditingController _polyFatController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prefillName ?? '');
    _brandController = TextEditingController();
    _amountController = TextEditingController(text: '100');
    _caloriesController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();

    _sugarController = TextEditingController();
    _fiberController = TextEditingController();
    _sodiumController = TextEditingController();
    _cholesterolController = TextEditingController();
    _potassiumController = TextEditingController();
    _satFatController = TextEditingController();
    _transFatController = TextEditingController();
    _monoFatController = TextEditingController();
    _polyFatController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _amountController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();

    _sugarController.dispose();
    _fiberController.dispose();
    _sodiumController.dispose();
    _cholesterolController.dispose();
    _potassiumController.dispose();
    _satFatController.dispose();
    _transFatController.dispose();
    _monoFatController.dispose();
    _polyFatController.dispose();
    super.dispose();
  }

  double? _parseNum(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  double? _parseDouble(TextEditingController controller) {
    return _parseNum(controller.text);
  }

  void _submitForm() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen besin adını giriniz.')),
      );
      return;
    }

    final amount = _parseNum(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir porsiyon miktarı giriniz.')),
      );
      return;
    }

    final calories = _parseNum(_caloriesController.text);
    final protein = _parseNum(_proteinController.text);
    final carbs = _parseNum(_carbsController.text);
    final fat = _parseNum(_fatController.text);

    if (calories == null || calories < 0 ||
        protein == null || protein < 0 ||
        carbs == null || carbs < 0 ||
        fat == null || fat < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kalori, protein, karbonhidrat ve yağ değerlerini eksiksiz giriniz.')),
      );
      return;
    }

    final brand = _brandController.text.trim();

    final food = FoodModel(
      name: name,
      brand: brand.isNotEmpty ? brand : null,
      category: _selectedCategory,
      defaultUnit: _selectedUnit,
      defaultAmount: amount,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      sugar: _parseDouble(_sugarController),
      fiber: _parseDouble(_fiberController),
      sodium: _parseDouble(_sodiumController),
      cholesterol: _parseDouble(_cholesterolController),
      potassium: _parseDouble(_potassiumController),
      satFat: _parseDouble(_satFatController),
      transFat: _parseDouble(_transFatController),
      monoFat: _parseDouble(_monoFatController),
      polyFat: _parseDouble(_polyFatController),
    );

    context.read<AddCustomFoodCubit>().submit(food);
  }

  @override
  Widget build(BuildContext context) {
    final amountText = _amountController.text.trim();
    final displayAmount = amountText.isEmpty ? '1' : amountText;

    return BlocListener<AddCustomFoodCubit, AddCustomFoodState>(
      listener: (context, state) {
        if (state.status == AddFoodStatus.success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Özel besin başarıyla eklendi.')),
          );
          context.pop(state.createdFood);
        } else if (state.status == AddFoodStatus.failure) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error ?? 'Besin eklenirken hata oluştu.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Manuel Besin Ekle',
            style: AppTextStyles.listTitle,
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Temel Bilgiler', style: AppTextStyles.listTitle),
                    const SizedBox(height: AppSpacing.sm),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Besin Adı *',
                      hint: 'Örn: Ev Yapımı Köfte',
                      inputFormatters: [LengthLimitingTextInputFormatter(150)],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _brandController,
                            label: 'Marka',
                            hint: 'Opsiyonel',
                            inputFormatters: [LengthLimitingTextInputFormatter(100)],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _buildNullableDropdownField(
                            label: 'Kategori',
                            value: _selectedCategory,
                            items: _categories,
                            hint: 'Seçiniz (opsiyonel)',
                            onChanged: (val) => setState(() => _selectedCategory = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _amountController,
                            label: 'Porsiyon Miktarı *',
                            hint: '100',
                            isNumber: true,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Birim *',
                            value: _selectedUnit,
                            items: _units,
                            onChanged: (val) => setState(() => _selectedUnit = val ?? 'g'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GlassContainer(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Makro Besin Değerleri ($displayAmount $_selectedUnit için)', style: AppTextStyles.listTitle),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _caloriesController,
                            label: 'Kalori (kcal) *',
                            hint: '0',
                            isNumber: true,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _buildTextField(
                            controller: _proteinController,
                            label: 'Protein (g) *',
                            hint: '0',
                            isNumber: true,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _carbsController,
                            label: 'Karbonhidrat (g) *',
                            hint: '0',
                            isNumber: true,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _buildTextField(
                            controller: _fatController,
                            label: 'Yağ (g) *',
                            hint: '0',
                            isNumber: true,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  title: Text(
                    'Detaylı Besin Değerleri (opsiyonel)',
                    style: AppTextStyles.bodyText.copyWith(color: AppColors.primary),
                  ),
                  children: [
                    GlassContainer(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _sugarController,
                                  label: 'Şeker (g)',
                                  hint: '0',
                                  isNumber: true,
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _buildTextField(
                                  controller: _fiberController,
                                  label: 'Lif (g)',
                                  hint: '0',
                                  isNumber: true,
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _sodiumController,
                                  label: 'Sodyum (mg)',
                                  hint: '0',
                                  isNumber: true,
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _buildTextField(
                                  controller: _potassiumController,
                                  label: 'Potasyum (mg)',
                                  hint: '0',
                                  isNumber: true,
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _cholesterolController,
                                  label: 'Kolesterol (mg)',
                                  hint: '0',
                                  isNumber: true,
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _buildTextField(
                                  controller: _satFatController,
                                  label: 'Doymuş Yağ (g)',
                                  hint: '0',
                                  isNumber: true,
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _transFatController,
                                  label: 'Trans Yağ (g)',
                                  hint: '0',
                                  isNumber: true,
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _buildTextField(
                                  controller: _monoFatController,
                                  label: 'Tekli Doymamış (g)',
                                  hint: '0',
                                  isNumber: true,
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildTextField(
                            controller: _polyFatController,
                            label: 'Çoklu Doymamış Yağ (g)',
                            hint: '0',
                            isNumber: true,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              BlocBuilder<AddCustomFoodCubit, AddCustomFoodState>(
                builder: (context, state) {
                  return PremiumButton(
                    text: 'BESİNİ KAYDET',
                    isLoading: state.status == AddFoodStatus.submitting,
                    onPressed: _submitForm,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isNumber = false,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.cardCaption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5)),
            filled: true,
            fillColor: AppColors.glassWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.cardCaption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items
              .map((u) => DropdownMenuItem(
                    value: u,
                    child: Text(u, style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary)),
                  ))
              .toList(),
          onChanged: onChanged,
          dropdownColor: AppColors.card,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
          style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.glassWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNullableDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    final dropdownItems = <DropdownMenuItem<String?>>[
      DropdownMenuItem<String?>(
        value: null,
        child: Text(hint, style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary)),
      ),
      ...items.map((c) => DropdownMenuItem<String?>(
            value: c,
            child: Text(c, style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary)),
          )),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.cardCaption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String?>(
          initialValue: value,
          items: dropdownItems,
          onChanged: onChanged,
          dropdownColor: AppColors.card,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
          style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.glassWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
