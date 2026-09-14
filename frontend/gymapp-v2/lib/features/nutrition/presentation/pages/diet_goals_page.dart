import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/core/util/age_calculator.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_goals/diet_goals_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_goals/diet_goals_state.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/smart_goal/smart_goal_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/smart_goal/smart_goal_state.dart';
import 'package:gymapp_v2/features/profile/data/models/client_profile_response_model.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';
import 'package:gymapp_v2/features/auth/data/models/goal.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';

class DietGoalsPage extends StatelessWidget {
  final DietProgramModel program;
  const DietGoalsPage({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<DietGoalsCubit>()..initialize(program),
      child: BlocConsumer<DietGoalsCubit, DietGoalsState>(
        listener: (context, state) {
          if (state.status == DietGoalsStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Diyet hedefleri başarıyla güncellendi!')));
            context.pop(true);
          } else if (state.error != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          final cubit = context.read<DietGoalsCubit>();

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
              title: Text(
                '${program.name} Hedefleri',
                style: AppTextStyles.heroTitle.copyWith(fontSize: 20),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(),
                  GlassContainer(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        _buildGoalInputRow(
                            context,
                            'Günlük Kalori',
                            state.calories,
                            'kcal',
                            Icons.local_fire_department_rounded,
                            (v) => cubit.updateNutrient('calories', v),
                            readOnly: state.isGramMode),
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                            child: Divider(color: AppColors.glassBorder)),
                        _buildGoalInputRow(
                            context,
                            'Protein',
                            state.protein,
                            state.isGramMode ? 'g' : '%',
                            Icons.egg_rounded,
                            (v) => cubit.updateNutrient('protein', v)),
                        _buildGoalInputRow(
                            context,
                            'Karbonhidrat',
                            state.carbs,
                            state.isGramMode ? 'g' : '%',
                            Icons.bakery_dining_rounded,
                            (v) => cubit.updateNutrient('carbs', v)),
                        _buildGoalInputRow(
                            context,
                            'Yağ',
                            state.fat,
                            state.isGramMode ? 'g' : '%',
                            Icons.water_drop_rounded,
                            (v) => cubit.updateNutrient('fat', v)),
                        _buildModeAndSmartButtons(context, cubit, state),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          child: SectionHeader(label: 'MİKRO BESİN HEDEFLERİ'),
                        ),
                        _buildGoalInputRow(
                            context,
                            'Şeker',
                            state.sugar,
                            'g',
                            Icons.bubble_chart_rounded,
                            (v) => cubit.updateNutrient('sugar', v)),
                        _buildGoalInputRow(
                            context,
                            'Lif',
                            state.fiber,
                            'g',
                            Icons.grass_rounded,
                            (v) => cubit.updateNutrient('fiber', v)),
                        _buildGoalInputRow(
                            context,
                            'Sodyum',
                            state.sodium,
                            'mg',
                            Icons.science_rounded,
                            (v) => cubit.updateNutrient('sodium', v)),
                        _buildGoalInputRow(
                            context,
                            'Potasyum',
                            state.potassium,
                            'mg',
                            Icons.opacity_rounded,
                            (v) => cubit.updateNutrient('potassium', v)),
                        _buildGoalInputRow(
                            context,
                            'Kolesterol',
                            state.cholesterol,
                            'mg',
                            Icons.heart_broken_rounded,
                            (v) => cubit.updateNutrient('cholesterol', v)),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSaveButton(cubit, state),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppLayout.bottomNavClearance),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderInfo() {
    final bool hasGoals = program.targetCalories > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: GlassContainer(
        color: hasGoals
            ? AppColors.glassWhite
            : AppColors.primary.withValues(alpha: 0.1),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
                hasGoals
                    ? Icons.auto_awesome_rounded
                    : Icons.info_outline_rounded,
                color: hasGoals ? AppColors.warning : AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      hasGoals
                          ? 'HEDEFLERİNİZİ GÖZDEN GEÇİRİN'
                          : 'LÜTFEN ÖNCE DİYET HEDEFİNİZİ BELİRLEYİN',
                      style: AppTextStyles.listTitle.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          fontSize: 14)),
                  if (hasGoals)
                    Text(
                        'Değerler aktif programınızdan otomatik aktarıldı.',
                        style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalInputRow(BuildContext context, String label, double value,
      String unit, IconData icon, void Function(double) onChanged,
      {bool readOnly = false}) {
    return _GoalInputField(
      label: label,
      value: value,
      unit: unit,
      icon: icon,
      onChanged: onChanged,
      readOnly: readOnly,
    );
  }

  Widget _buildModeAndSmartButtons(
      BuildContext context, DietGoalsCubit cubit, DietGoalsState state) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () => cubit.toggleMode(),
              style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm)),
              icon: Icon(state.isGramMode ? Icons.scale_rounded : Icons.percent_rounded,
                  color: AppColors.primary, size: 20),
              label: Text(state.isGramMode ? 'GRAM MODU' : 'YÜZDE MODU',
                  style: AppTextStyles.buttonText.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      letterSpacing: 0.5)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextButton.icon(
              onPressed: () => _showSmartGoalCalculator(context, cubit),
              style: TextButton.styleFrom(
                  backgroundColor: AppColors.glassWhite,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm)),
              icon: const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.warning, size: 20),
              label: Text('AKILLI HEDEF',
                  style: AppTextStyles.buttonText.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(DietGoalsCubit cubit, DietGoalsState state) {
    final bool isSaving = state.status == DietGoalsStatus.saving;
    return PremiumButton(
      text: 'HEDEFLERİ KAYDET',
      isLoading: isSaving,
      onPressed: () => cubit.save(program.id),
    );
  }

  Future<void> _showSmartGoalCalculator(
      BuildContext context, DietGoalsCubit dietGoalsCubit) async {
    double? fetchedWeight;
    double? fetchedHeight;
    int? fetchedAge;
    Gender? fetchedGender;
    ActivityLevel? fetchedActivity;
    String? fetchedGoal;

    // Koç bir sporcunun programına bakıyorsa o sporcunun verisi çekilmeli (kendi değil).
    // Program sahibi (ownerId) giriş yapan kullanıcıdan farklıysa koç endpoint'i kullanılır.
    final authState = context.read<AuthBloc>().state;
    final int? currentUserId =
        authState is AuthAuthenticated ? authState.auth.id : null;
    final int? ownerId = program.ownerId;
    final bool viewingOtherClient =
        ownerId != null && currentUserId != null && ownerId != currentUserId;
    final String profileEndpoint =
        viewingOtherClient ? '/profile/client/$ownerId' : '/profile/client/me';

    try {
      final response = await DioClient()
          .dio
          .get<Map<String, dynamic>>(profileEndpoint);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data?['data'] as Map<String, dynamic>?;
        if (data != null) {
          final profile = ClientProfileResponseModel.fromJson(data);
          fetchedWeight = profile.weightKg;
          fetchedHeight = profile.heightCm?.toDouble();
          fetchedGender = profile.gender;
          fetchedActivity = profile.activityLevel;

          if (profile.goal == Goal.kiloVer) {
            fetchedGoal = 'KILO VER';
          } else if (profile.goal == Goal.kasKazan) {
            fetchedGoal = 'KILO AL';
          } else if (profile.goal == Goal.koru) {
            fetchedGoal = 'KORU';
          }

          fetchedAge = calculateAge(profile.dateOfBirth) ?? fetchedAge;
        }
      }
    } catch (e) {
      // Profile data not available
    }

    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => BlocProvider(
        create: (ctx) => SmartGoalCubit(
          initialWeight: fetchedWeight ?? 70,
          initialHeight: fetchedHeight ?? 170,
          initialAge: fetchedAge ?? 25,
          initialGender: fetchedGender ?? Gender.male,
          initialActivity: fetchedActivity ?? ActivityLevel.moderatelyActive,
          initialGoal: fetchedGoal ?? 'KORU',
          fetchedWeight: fetchedWeight,
          fetchedHeight: fetchedHeight,
          fetchedAge: fetchedAge,
          fetchedGender: fetchedGender,
          fetchedActivity: fetchedActivity,
          fetchedGoal: fetchedGoal,
        ),
        child: _SmartGoalModal(
            onApply: (tdee) => dietGoalsCubit.applySmartGoal(tdee)),
      ),
    );
  }
}

class _SmartGoalModal extends StatefulWidget {
  final void Function(double) onApply;

  const _SmartGoalModal({required this.onApply});

  @override
  State<_SmartGoalModal> createState() => _SmartGoalModalState();
}

class _SmartGoalModalState extends State<_SmartGoalModal> {
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _ageController;

  static String _fmt(num v) {
    final d = v.toDouble();
    return d == d.roundToDouble() ? d.toInt().toString() : d.toString();
  }

  @override
  void initState() {
    super.initState();
    final s = context.read<SmartGoalCubit>().state;
    _weightController = TextEditingController(text: _fmt(s.weight));
    _heightController = TextEditingController(text: _fmt(s.height));
    _ageController = TextEditingController(text: s.age.toString());
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SmartGoalCubit, SmartGoalState>(
      // Controller metnini SADECE "Profilden Al" değiştiğinde senkronize et.
      // Kullanıcı elle yazarken (weight/height/age değişiminde) sıfırlama; aksi halde
      // alanı silip yeni değer yazmak imkânsız olur (eski hata buydu).
      listenWhen: (prev, curr) => prev.useProfile != curr.useProfile,
      listener: (context, state) {
        _weightController.text = _fmt(state.weight);
        _heightController.text = _fmt(state.height);
        _ageController.text = state.age.toString();
      },
      builder: (context, state) {
        final cubit = context.read<SmartGoalCubit>();

        return Container(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.glassBorder,
                          borderRadius: BorderRadius.circular(AppRadius.pill)))),
              const SizedBox(height: AppSpacing.lg),
              Text('AKILLI HEDEF BULUCU',
                  style: AppTextStyles.heroTitle.copyWith(
                      fontSize: 22,
                      color: AppColors.primary)),
              const SizedBox(height: AppSpacing.xs),
              Text('Fiziksel özelliklerinize göre ideal kaloriyi hesaplayalım.',
                  style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Profilden Al',
                      style: AppTextStyles.listTitle.copyWith(
                          color: AppColors.textPrimary, fontSize: 14)),
                  Switch(
                      value: state.useProfile,
                      onChanged: (val) => cubit.toggleUseProfile(val),
                      activeThumbColor: AppColors.primary),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                      child: _buildModalInput(
                          'Kilo (kg)',
                          _weightController,
                          (v) {
                            final p = double.tryParse(v);
                            if (p != null) cubit.updateWeight(p);
                          },
                          readOnly: state.useProfile)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                      child: _buildModalInput(
                          'Boy (cm)',
                          _heightController,
                          (v) {
                            final p = double.tryParse(v);
                            if (p != null) cubit.updateHeight(p);
                          },
                          readOnly: state.useProfile)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                      child: _buildModalInput(
                          'Yaş',
                          _ageController,
                          (v) {
                            final p = int.tryParse(v);
                            if (p != null) cubit.updateAge(p);
                          },
                          readOnly: state.useProfile)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                      child: _buildModalDropdown<Gender>(
                          'Cinsiyet',
                          Gender.values,
                          state.gender,
                          (g) => g.toUIString(),
                          state.useProfile ? null : (v) => cubit.updateGender(v!))),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildModalDropdown<ActivityLevel>(
                  'Aktivite Seviyesi',
                  ActivityLevel.values,
                  state.activity,
                  (a) => a.toUIString(),
                  state.useProfile ? null : (v) => cubit.updateActivity(v!)),
              const SizedBox(height: AppSpacing.md),
              _buildModalDropdown<String>(
                  'Beslenme Hedefi',
                  ['KILO VER', 'KORU', 'KILO AL'],
                  state.goal,
                  (s) => s,
                  state.useProfile ? null : (v) => cubit.updateGoal(v!)),
              const SizedBox(height: AppSpacing.xl),
              PremiumButton(
                text: 'HESAPLA VE UYGULA',
                onPressed: () {
                  widget.onApply(cubit.calculateTdee());
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalInput(String label, TextEditingController controller,
      void Function(String) onChanged, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.cardCaption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyles.bodyText.copyWith(
              color: readOnly ? AppColors.textMuted : AppColors.textPrimary, fontSize: 16),
          onChanged: onChanged,
          readOnly: readOnly,
          decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.glassWhite,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide.none)),
        ),
      ],
    );
  }

  Widget _buildModalDropdown<T>(String label, List<T> items, T value,
      String Function(T) itemToString, void Function(T?)? onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.cardCaption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
              color: AppColors.glassWhite,
              borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.background,
              disabledHint: Text(itemToString(value),
                  style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted)),
              items: items
                  .map((e) => DropdownMenuItem<T>(
                      value: e,
                      child: Text(itemToString(e),
                          style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// Hedef giriş alanı: controller'ı kendi yaşam döngüsünde tutar (her build'de yeniden
/// oluşturmaz) ve değeri YUVARLAYARAK gösterir. Böylece 39.94% gibi bir değer "39" değil
/// "40" görünür ve kaydet/yükle döngüsünde "30/40/30 → 30/39/29" bozulması yaşanmaz.
class _GoalInputField extends StatefulWidget {
  final String label;
  final double value;
  final String unit;
  final IconData icon;
  final void Function(double) onChanged;
  final bool readOnly;

  const _GoalInputField({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  State<_GoalInputField> createState() => _GoalInputFieldState();
}

class _GoalInputFieldState extends State<_GoalInputField> {
  late final TextEditingController _controller;

  static String _fmt(double v) => v == 0 ? '' : v.round().toString();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _fmt(widget.value));
  }

  @override
  void didUpdateWidget(_GoalInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Dış değer (mod değişimi, akıllı hedef vb.) değiştiyse alanı senkronize et; ancak
    // kullanıcı yazarken (parse edilen değer zaten aynıysa) metni SIFIRLAMA.
    final double currentParsed = double.tryParse(_controller.text) ?? 0;
    if (currentParsed.round() != widget.value.round()) {
      final String text = _fmt(widget.value);
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(widget.icon, color: AppColors.primary.withValues(alpha: 0.7), size: 26),
          const SizedBox(width: AppSpacing.sm),
          Text(widget.label,
              style: AppTextStyles.listTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          SizedBox(
            width: 110,
            child: TextField(
              controller: _controller,
              readOnly: widget.readOnly,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ],
              textAlign: TextAlign.right,
              onChanged: (v) => widget.onChanged(double.tryParse(v) ?? 0),
              style: AppTextStyles.cardValue.copyWith(
                  color: widget.readOnly ? AppColors.textMuted : AppColors.textPrimary,
                  fontSize: 20),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
                suffixText: ' ${widget.unit}',
                suffixStyle: AppTextStyles.bodyText.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
                filled: true,
                fillColor: AppColors.glassWhite,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

