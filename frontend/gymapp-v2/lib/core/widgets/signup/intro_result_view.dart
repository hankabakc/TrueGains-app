import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/navigation/last_route_store.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/util/motion.dart';
import 'package:gymapp_v2/core/util/tdee_calculator.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';
import 'package:gymapp_v2/features/membership/presentation/bloc/intro/intro_cubit.dart';
import 'package:gymapp_v2/features/membership/presentation/bloc/intro/intro_state.dart';

class IntroResultView extends StatelessWidget {
  final IntroState state;
  final bool isActive;

  const IntroResultView({
    super.key,
    required this.state,
    required this.isActive,
  });

  /// 2799 -> "2 799". Nokta/virgül yerine ince boşluk: rakamlar kahraman,
  /// noktalama onları bölmemeli.
  static String groupDigits(int value) {
    final String raw = value.toString();
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) {
        out.write(' ');
      }
      out.write(raw[i]);
    }
    return out.toString();
  }

  @override
  Widget build(BuildContext context) {
    final double tdee = calculateTdee(
      weightKg: state.finalWeightKg,
      heightCm: state.finalHeightCm,
      age: state.age,
      gender: state.gender ?? Gender.other,
      activity: state.activityLevel ?? ActivityLevel.sedentary,
      goal: state.goal,
    );
    final macros = macrosFromCalories(tdee);
    final double bmi = calculateBmi(
      weightKg: state.finalWeightKg,
      heightCm: state.finalHeightCm,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Text('Planın hazır', style: AppTextStyles.heroTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Verdiğin bilgilere göre hesapladık.',
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
          ),

          const Spacer(),

          // Kahraman: günlük kalori. Kart yok, çerçeve yok — sayının kendisi.
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: isActive ? tdee : 0.0),
            duration: motionDuration(context, const Duration(milliseconds: 900)),
            curve: Curves.easeOutExpo,
            builder: (context, value, _) {
              return Text(
                groupDigits(value.round()),
                style: AppTextStyles.heroNumeral.copyWith(
                  fontSize: 96,
                  color: AppColors.primary,
                  height: 1.0,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('KCAL / GÜN', style: AppTextStyles.sectionLabel),

          const SizedBox(height: AppSpacing.xl),

          _MacroBar(
            proteinCalories: macros.protein * 4,
            carbCalories: macros.carbs * 4,
            fatCalories: macros.fat * 9,
            isActive: isActive,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Protein ${macros.protein.round()} g   ·   '
            'Karbonhidrat ${macros.carbs.round()} g   ·   '
            'Yağ ${macros.fat.round()} g',
            style: AppTextStyles.cardCaption,
          ),

          const SizedBox(height: AppSpacing.xl),

          Divider(height: 1, color: AppColors.glassBorder),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Vücut kitle indeksi', style: AppTextStyles.cardLabel),
                Text(
                  bmi.toStringAsFixed(1),
                  style: AppTextStyles.heroNumeral.copyWith(
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.glassBorder),

          const Spacer(),

          PremiumButton(
            text: 'PLANIMI KAYDET',
            onPressed: () {
              context.read<IntroCubit>().commitAnswers();
              sl<LastRouteStore>().markIntroSeen();
              context.go('/register/form');
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// Üç ayrı bar yerine tek yığılmış şerit: günlük kalorinin nereden geldiğini
/// gösterir. Segment payları gram değil KALORİ payıdır.
class _MacroBar extends StatelessWidget {
  final double proteinCalories;
  final double carbCalories;
  final double fatCalories;
  final bool isActive;

  const _MacroBar({
    required this.proteinCalories,
    required this.carbCalories,
    required this.fatCalories,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: isActive ? 1.0 : 0.0),
      duration: motionDuration(context, const Duration(milliseconds: 700)),
      curve: Curves.easeOutQuint,
      builder: (context, value, animChild) {
        // Transform layout'u etkilemez; Align/widthFactor ile yapılan açılma
        // Column içinde barın hiç çizilmemesine yol açıyordu.
        return Transform(
          alignment: Alignment.centerLeft,
          transform: Matrix4.diagonal3Values(value, 1.0, 1.0),
          child: animChild,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: SizedBox(
          height: 10,
          child: Row(
            // ZORUNLU: ColoredBox'ın çocuğu yok, gevşek constraint altında
            // constraints.smallest'a (yükseklik 0) çöker. stretch dikeyde
            // tight constraint verir.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: proteinCalories.round().clamp(1, 100000),
                child: const ColoredBox(color: AppColors.protein),
              ),
              Expanded(
                flex: carbCalories.round().clamp(1, 100000),
                child: const ColoredBox(color: AppColors.carbs),
              ),
              Expanded(
                flex: fatCalories.round().clamp(1, 100000),
                child: const ColoredBox(color: AppColors.fat),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
