import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/navigation/last_route_store.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/util/motion.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/auth/data/models/goal.dart';
import 'package:gymapp_v2/features/auth/data/models/gender.dart';
import 'package:gymapp_v2/features/auth/data/models/activity_level.dart';
import 'package:gymapp_v2/features/auth/data/models/experience_level.dart';
import 'package:gymapp_v2/features/auth/presentation/signup_steps.dart';
import 'package:gymapp_v2/features/membership/presentation/bloc/intro/intro_cubit.dart';
import 'package:gymapp_v2/features/membership/presentation/bloc/intro/intro_state.dart';
import 'package:gymapp_v2/core/widgets/signup/intro_option_card.dart';
import 'package:gymapp_v2/core/widgets/signup/intro_progress_bar.dart';
import 'package:gymapp_v2/core/widgets/signup/intro_question_scaffold.dart';
import 'package:gymapp_v2/core/widgets/signup/intro_result_view.dart';
import 'package:gymapp_v2/core/widgets/signup/intro_ruler.dart';

/// Sayfa geçişi 260 ms, içerik girişi 340 ms. Giriş kaydırmadan uzun olduğu için
/// sahne yerleşirken hâlâ hareket hâlindedir — set temposu (hızlı konsantrik,
/// kontrollü eksantrik).
const Duration _kPageScroll = Duration(milliseconds: 260);

/// Bir seçim yapıldıktan sonra kartın seçili hâlinin görülmesi için beklenen süre.
const Duration _kAutoAdvanceDelay = Duration(milliseconds: 220);

/// Sıra, ilgili enum'ın `values` sırasıyla birebir eşleşir.
const List<IconData> _goalIcons = [
  Icons.trending_down_rounded, // kiloVer
  Icons.fitness_center_rounded, // kasKazan
  Icons.shield_rounded, // koru
  Icons.bolt_rounded, // performans
  Icons.favorite_rounded, // saglikliYasa
];

const List<IconData> _activityIcons = [
  Icons.weekend_rounded, // sedentary
  Icons.directions_walk_rounded, // lightlyActive
  Icons.directions_run_rounded, // moderatelyActive
  Icons.local_fire_department_rounded, // veryActive
  Icons.whatshot_rounded, // extraActive
];

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<IntroCubit>(
      create: (context) => sl<IntroCubit>(),
      child: const IntroView(),
    );
  }
}

class IntroView extends StatefulWidget {
  const IntroView({super.key});

  @override
  State<IntroView> createState() => _IntroViewState();
}

class _IntroViewState extends State<IntroView> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage(IntroCubit cubit) {
    cubit.nextPage();
    _pageController.nextPage(
      duration: motionDuration(context, _kPageScroll),
      curve: Curves.easeInOutCubic,
    );
  }

  void _selectAndAutoNext(IntroCubit cubit, VoidCallback selectAction) {
    selectAction();
    Future<void>.delayed(_kAutoAdvanceDelay, () {
      if (!mounted) return;
      _nextPage(cubit);
    });
  }

  /// Antrenör dalının son sorusu. Cevapları RegistrationFlowCubit'e yazmadan
  /// çıkılırsa backend boy/kilo eksik diye kaydı reddeder.
  void _finishCoachIntro(IntroCubit cubit) {
    cubit.commitAnswers();
    sl<LastRouteStore>().markIntroSeen();
    context.go('/register/form');
  }

  /// Q4/Q5/Q6 ortak gövdesi: kahraman sayı + birim + cetvel.
  Widget _valueBody({
    required String value,
    required String unit,
    required int min,
    required int max,
    required int current,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.heroNumeral.copyWith(
            fontSize: 88,
            color: AppColors.primary,
            height: 1.0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(unit, style: AppTextStyles.sectionLabel),
        const SizedBox(height: AppSpacing.xl),
        IntroRuler(
          min: min,
          max: max,
          value: current,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IntroCubit, IntroState>(
      builder: (context, state) {
        final cubit = context.read<IntroCubit>();
        final bool isCoach = state.role == UserRole.COACH;
        // Bar tüm kayıt akışını sayar (intro + form + profil adımları), sadece
        // intro'yu değil. Rol seçilene kadar sporcu yolu varsayılır.
        final UserRole role = state.role ?? UserRole.CLIENT;
        final int totalSteps = signupTotalSteps(role);
        final int page = state.pageIndex;

        // Ödül sayfası bir soru değil; bar son sorunun dolumunda kalır.
        final int barStep = page.clamp(0, signupIntroSteps(role) - 1);
        final String label = (!isCoach && page == 8)
            ? 'PLANIN HAZIR'
            : signupStepLabel(barStep, totalSteps);

        final int currentYear = DateTime.now().year;

        final List<Widget> pages = [
          // 0 — Rol
          IntroQuestionScaffold(
            isActive: page == 0,
            title: 'Neden buradasın?',
            subtitle: 'Sana doğru deneyimi hazırlayalım.',
            child: Column(
              children: [
                IntroOptionCard(
                  label: 'Kendim için çalışıyorum',
                  description: 'Antrenman ve beslenmemi takip etmek istiyorum.',
                  icon: Icons.self_improvement_rounded,
                  isSelected: state.role == UserRole.CLIENT,
                  index: 0,
                  isActive: page == 0,
                  onTap: () => _selectAndAutoNext(
                    cubit,
                    () => cubit.selectRole(UserRole.CLIENT),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                IntroOptionCard(
                  label: 'Antrenörüm',
                  description: 'Danışanlarıma program vermek istiyorum.',
                  icon: Icons.groups_rounded,
                  isSelected: state.role == UserRole.COACH,
                  index: 1,
                  isActive: page == 0,
                  onTap: () => _selectAndAutoNext(
                    cubit,
                    () => cubit.selectRole(UserRole.COACH),
                  ),
                ),
              ],
            ),
          ),

          if (isCoach) ...[
            // Antrenöre hedef/kalori sorulmaz ama boy ve kilo backend'de
            // zorunlu (CoachRegistrationValidator). Sporcuyla aynı cetvel.
            IntroQuestionScaffold(
              isActive: page == 1,
              title: 'Boyun kaç?',
              subtitle: 'Profilinde görünecek.',
              footer: PremiumButton(
                text: 'DEVAM',
                variant: PremiumButtonVariant.secondary,
                onPressed: () => _nextPage(cubit),
              ),
              child: _valueBody(
                value: '${state.heightCm}',
                unit: 'CM',
                min: 100,
                max: 250,
                current: state.heightCm,
                onChanged: cubit.setHeight,
              ),
            ),
            IntroQuestionScaffold(
              isActive: page == 2,
              title: 'Kilon kaç?',
              subtitle: 'Profilinde görünecek.',
              footer: PremiumButton(
                text: 'DEVAM',
                onPressed: () => _finishCoachIntro(cubit),
              ),
              child: _valueBody(
                value: '${state.weightKg}',
                unit: 'KG',
                min: 30,
                max: 250,
                current: state.weightKg,
                onChanged: cubit.setWeight,
              ),
            ),
          ],

          if (!isCoach) ...[
            // 1 — Hedef
            IntroQuestionScaffold(
              isActive: page == 1,
              title: 'Hedefin ne?',
              subtitle: 'Planını bu hedefe göre kuracağız.',
              child: Column(
                children: [
                  for (int i = 0; i < Goal.values.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.md),
                    IntroOptionCard(
                      label: Goal.values[i].toUIString(),
                      icon: _goalIcons[i],
                      isSelected: state.goal == Goal.values[i],
                      index: i,
                      isActive: page == 1,
                      onTap: () => _selectAndAutoNext(
                        cubit,
                        () => cubit.selectGoal(Goal.values[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 2 — Cinsiyet
            IntroQuestionScaffold(
              isActive: page == 2,
              title: 'Cinsiyetin?',
              subtitle: 'Kalori hesabı için gerekli.',
              child: Column(
                children: [
                  IntroOptionCard(
                    label: Gender.male.toUIString(),
                    icon: Icons.male_rounded,
                    isSelected: state.gender == Gender.male,
                    index: 0,
                    isActive: page == 2,
                    onTap: () => _selectAndAutoNext(
                      cubit,
                      () => cubit.selectGender(Gender.male),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  IntroOptionCard(
                    label: Gender.female.toUIString(),
                    icon: Icons.female_rounded,
                    isSelected: state.gender == Gender.female,
                    index: 1,
                    isActive: page == 2,
                    onTap: () => _selectAndAutoNext(
                      cubit,
                      () => cubit.selectGender(Gender.female),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  IntroOptionCard(
                    label: Gender.other.toUIString(),
                    icon: Icons.transgender_rounded,
                    isSelected: state.gender == Gender.other,
                    index: 2,
                    isActive: page == 2,
                    onTap: () => _selectAndAutoNext(
                      cubit,
                      () => cubit.selectGender(Gender.other),
                    ),
                  ),
                ],
              ),
            ),

            // 3 — Doğum yılı
            IntroQuestionScaffold(
              isActive: page == 3,
              title: 'Doğum yılın?',
              subtitle: 'Yaşına uygun bir program kuralım.',
              footer: PremiumButton(
                text: 'DEVAM',
                variant: PremiumButtonVariant.secondary,
                onPressed: () => _nextPage(cubit),
              ),
              child: _valueBody(
                value: '${state.birthYear}',
                unit: 'DOĞUM YILI',
                min: 1950,
                max: currentYear - 13,
                current: state.birthYear,
                onChanged: cubit.setBirthYear,
              ),
            ),

            // 4 — Boy
            IntroQuestionScaffold(
              isActive: page == 4,
              title: 'Boyun kaç?',
              subtitle: 'Vücut kitle indeksin için gerekli.',
              footer: PremiumButton(
                text: 'DEVAM',
                variant: PremiumButtonVariant.secondary,
                onPressed: () => _nextPage(cubit),
              ),
              child: _valueBody(
                value: '${state.heightCm}',
                unit: 'CM',
                min: 100,
                max: 250,
                current: state.heightCm,
                onChanged: cubit.setHeight,
              ),
            ),

            // 5 — Kilo
            IntroQuestionScaffold(
              isActive: page == 5,
              title: 'Kilon kaç?',
              subtitle: 'Başlangıç noktanı belirleyelim.',
              footer: PremiumButton(
                text: 'DEVAM',
                variant: PremiumButtonVariant.secondary,
                onPressed: () => _nextPage(cubit),
              ),
              child: _valueBody(
                value: '${state.weightKg}',
                unit: 'KG',
                min: 30,
                max: 250,
                current: state.weightKg,
                onChanged: cubit.setWeight,
              ),
            ),

            // 6 — Aktivite
            IntroQuestionScaffold(
              isActive: page == 6,
              title: 'Ne kadar aktifsin?',
              subtitle: 'Günlük enerji ihtiyacını buna göre hesaplayacağız.',
              child: Column(
                children: [
                  for (int i = 0; i < ActivityLevel.values.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.md),
                    IntroOptionCard(
                      label: ActivityLevel.values[i].toUIString(),
                      icon: _activityIcons[i],
                      isSelected: state.activityLevel == ActivityLevel.values[i],
                      index: i,
                      isActive: page == 6,
                      onTap: () => _selectAndAutoNext(
                        cubit,
                        () => cubit.selectActivity(ActivityLevel.values[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 7 — Deneyim
            IntroQuestionScaffold(
              isActive: page == 7,
              title: 'Deneyimin ne kadar?',
              subtitle: 'Zorluk seviyesini buna göre ayarlayacağız.',
              child: Column(
                children: [
                  IntroOptionCard(
                    label: ExperienceLevel.baslangic.toUIString(),
                    icon: Icons.eco_rounded,
                    isSelected: state.experienceLevel == ExperienceLevel.baslangic,
                    index: 0,
                    isActive: page == 7,
                    onTap: () => _selectAndAutoNext(
                      cubit,
                      () => cubit.selectExperience(ExperienceLevel.baslangic),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  IntroOptionCard(
                    label: ExperienceLevel.orta.toUIString(),
                    icon: Icons.trending_up_rounded,
                    isSelected: state.experienceLevel == ExperienceLevel.orta,
                    index: 1,
                    isActive: page == 7,
                    onTap: () => _selectAndAutoNext(
                      cubit,
                      () => cubit.selectExperience(ExperienceLevel.orta),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  IntroOptionCard(
                    label: ExperienceLevel.ileri.toUIString(),
                    icon: Icons.military_tech_rounded,
                    isSelected: state.experienceLevel == ExperienceLevel.ileri,
                    index: 2,
                    isActive: page == 7,
                    onTap: () => _selectAndAutoNext(
                      cubit,
                      () => cubit.selectExperience(ExperienceLevel.ileri),
                    ),
                  ),
                ],
              ),
            ),

            // 8 — Ödül
            IntroResultView(state: state, isActive: page == 8),
          ],
        ];

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (didPop) return;
            final bool moved = cubit.previousPage();
            if (moved) {
              _pageController.previousPage(
                duration: motionDuration(context, _kPageScroll),
                curve: Curves.easeInOutCubic,
              );
              return;
            }
            if (context.canPop()) {
              context.pop();
            } else {
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  IntroProgressBar(
                    currentStep: barStep,
                    totalSteps: totalSteps,
                    label: label,
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: pages,
                    ),
                  ),
                  // Uygulamayı silip yeniden kuran kullanıcının hesabı vardır ama
                  // cihazda "intro görüldü" kaydı yoktur; bu yüzden açılışta soru
                  // akışına düşer. Bu bağlantı olmadan giriş ekranına ulaşmasının
                  // hiçbir yolu yok — anketi baştan doldurmak zorunda kalır.
                  //
                  // Yalnızca ilk adımda gösteriliyor: karar burada verilir, sonraki
                  // sorularda çıkması akışı bölen bir gürültü olurdu.
                  if (page == 0) const _AlreadyHaveAccount(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// "Zaten hesabın var mı? Giriş yap" bağlantısı.
///
/// Uygulamayı silip yeniden kuran kullanıcının sunucuda hesabı vardır ama cihazda
/// "intro görüldü" kaydı yoktur; yönlendirici bu yüzden onu soru akışına düşürür. Bu
/// bağlantı olmadan giriş ekranına ulaşmasının yolu yok.
class _AlreadyHaveAccount extends StatelessWidget {
  const _AlreadyHaveAccount();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Zaten hesabın var mı?',
            style: AppTextStyles.cardCaption.copyWith(color: AppColors.textSecondary),
          ),
          TextButton(
            onPressed: () {
              // Intro "görüldü" işaretleniyor: kullanıcı zaten hesabı olduğunu
              // söyledi. İşaretlenmezse çıkış yapıp uygulamayı tekrar açtığında
              // yönlendirici onu yine soru akışına düşürür.
              sl<LastRouteStore>().markIntroSeen();
              context.go('/login');
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(0, 44), // dokunma hedefi
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            child: Text(
              'Giriş yap',
              style: AppTextStyles.cardCaption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
