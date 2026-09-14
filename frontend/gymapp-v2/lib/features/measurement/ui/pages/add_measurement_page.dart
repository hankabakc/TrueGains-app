import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/add_measurement/add_measurement_cubit.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/add_measurement/add_measurement_state.dart';
import 'package:gymapp_v2/core/constants/app_strings.dart';

class AddMeasurementPage extends StatelessWidget {
  final AddMeasurementCubit? cubit;
  const AddMeasurementPage({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => (cubit ?? sl<AddMeasurementCubit>())..loadTodayData(),
      child: const AddMeasurementForm(),
    );
  }
}

class AddMeasurementForm extends StatefulWidget {
  const AddMeasurementForm({super.key});

  @override
  State<AddMeasurementForm> createState() => _AddMeasurementFormState();
}

class _AddMeasurementFormState extends State<AddMeasurementForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _glowController;

  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _fatController = TextEditingController();
  final _muscleMassController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _shouldersController = TextEditingController();
  final _leftArmController = TextEditingController();
  final _rightArmController = TextEditingController();
  final _leftLegController = TextEditingController();
  final _rightLegController = TextEditingController();
  final _hipsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _fatController.dispose();
    _muscleMassController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _shouldersController.dispose();
    _leftArmController.dispose();
    _rightArmController.dispose();
    _leftLegController.dispose();
    _rightLegController.dispose();
    _hipsController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'weight': _parseDouble(_weightController.text),
      'height': _parseDouble(_heightController.text),
      'bodyFatPct': _parseDouble(_fatController.text),
      'muscleMass': _parseDouble(_muscleMassController.text),
      'chest': _parseDouble(_chestController.text),
      'waist': _parseDouble(_waistController.text),
      'shoulders': _parseDouble(_shouldersController.text),
      'leftArm': _parseDouble(_leftArmController.text),
      'rightArm': _parseDouble(_rightArmController.text),
      'leftLeg': _parseDouble(_leftLegController.text),
      'rightLeg': _parseDouble(_rightLegController.text),
      'hips': _parseDouble(_hipsController.text),
    };

    final allEmpty = data.values.every((v) => v == null);
    if (allEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.fillAtLeastOneField),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<AddMeasurementCubit>().saveMeasurement(data);
  }

  double? _parseDouble(String t) =>
      t.trim().isEmpty ? null : double.tryParse(t.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddMeasurementCubit, AddMeasurementState>(
      listener: (context, state) {
        if (state.isSuccess) {
          Navigator.pop(context, true);
        }
        if (state.initialData != null) {
          _weightController.text = (state.initialData!['weight'] as String?) ?? '';
          _heightController.text = (state.initialData!['height'] as String?) ?? '';
          _fatController.text = (state.initialData!['bodyFatPct'] as String?) ?? '';
          _muscleMassController.text = (state.initialData!['muscleMass'] as String?) ?? '';
          _chestController.text = (state.initialData!['chest'] as String?) ?? '';
          _waistController.text = (state.initialData!['waist'] as String?) ?? '';
          _shouldersController.text = (state.initialData!['shoulders'] as String?) ?? '';
          _leftArmController.text = (state.initialData!['leftArm'] as String?) ?? '';
          _rightArmController.text = (state.initialData!['rightArm'] as String?) ?? '';
          _leftLegController.text = (state.initialData!['leftLeg'] as String?) ?? '';
          _rightLegController.text = (state.initialData!['rightLeg'] as String?) ?? '';
          _hipsController.text = (state.initialData!['hips'] as String?) ?? '';
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            _buildBackgroundGlow(),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                        child: BlocBuilder<AddMeasurementCubit, AddMeasurementState>(
                          builder: (context, state) {
                            return Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSection(AppStrings.basicMeasurements, Icons.monitor_weight_rounded, [
                                    _buildMetricRow(AppStrings.labelWeight, _weightController, 'kg', AppStrings.labelHeight, _heightController, 'cm'),
                                    const SizedBox(height: AppSpacing.md),
                                    _buildMetricRow(AppStrings.labelFatPct, _fatController, '%', AppStrings.labelMuscleMass, _muscleMassController, 'kg'),
                                  ]),
                                  const SizedBox(height: AppSpacing.xl),
                                  _buildSection(AppStrings.torsoAndShoulders, Icons.accessibility_new_rounded, [
                                    _buildMetricRow(AppStrings.labelShoulder, _shouldersController, 'cm', AppStrings.labelChest, _chestController, 'cm'),
                                    const SizedBox(height: AppSpacing.md),
                                    _buildMetricRow(AppStrings.labelWaist, _waistController, 'cm', AppStrings.labelHips, _hipsController, 'cm'),
                                  ]),
                                  const SizedBox(height: AppSpacing.xl),
                                  _buildSection(AppStrings.arms.toUpperCase(), Icons.fitness_center_rounded, [
                                    _buildMetricRow(AppStrings.labelLeftArm, _leftArmController, 'cm', AppStrings.labelRightArm, _rightArmController, 'cm'),
                                  ]),
                                  const SizedBox(height: AppSpacing.xl),
                                  _buildSection(AppStrings.legs.toUpperCase(), Icons.directions_run_rounded, [
                                    _buildMetricRow(AppStrings.labelLeftLeg, _leftLegController, 'cm', AppStrings.labelRightLeg, _rightLegController, 'cm'),
                                  ]),
                                  const SizedBox(height: AppSpacing.xxl),
                                  PremiumButton(
                                    text: AppStrings.saveChanges,
                                    icon: Icons.check_circle_outline_rounded,
                                    isLoading: state.isSaving,
                                    onPressed: _onSave,
                                  ),
                                  const SizedBox(height: AppLayout.bottomNavClearance),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 20),
        title: Text(
          AppStrings.newMeasurement,
          style: AppTextStyles.pageTitle,
        ),
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    return Positioned(
      top: -100,
      right: -100,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (_, __) => Container(
          width: 400,
          height: 400,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.05 + _glowController.value * 0.03),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          label: title,
          icon: icon,
        ),
        const SizedBox(height: AppSpacing.md),
        ...children,
      ],
    );
  }

  Widget _buildMetricRow(
    String l1,
    TextEditingController c1,
    String u1,
    String l2,
    TextEditingController c2,
    String u2,
  ) {
    return Row(
      children: [
        Expanded(child: _buildField(l1, c1, u1)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _buildField(l2, c2, u2)),
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String suffix,
  ) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.glassBorder),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          DecimalTextInputFormatter(),
        ],
        style: AppTextStyles.listTitle.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 13),
          suffixText: suffix,
          suffixStyle: AppTextStyles.tagText.copyWith(color: AppColors.textMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }
}

/// Sadece tek bir nokta veya virgül kullanımına izin veren, mükerrer basımları engelleyen formatlayıcı.
class DecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Sadece rakam, tek bir nokta veya virgül (mükerrer karakter engeli)
    final regExp = RegExp(r'^\d*[.,]?\d*$');
    if (regExp.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}
