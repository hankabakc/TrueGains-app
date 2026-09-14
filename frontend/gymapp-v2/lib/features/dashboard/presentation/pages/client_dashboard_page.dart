import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/navigation/app_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/pressable_scale.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:gymapp_v2/core/widgets/stat_ring.dart';
import 'package:gymapp_v2/core/util/app_logger.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_state.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_entry/diet_entry_bloc.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_entry/diet_entry_event.dart';
import 'package:gymapp_v2/features/dashboard/presentation/widgets/nutrition_bento.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/water/water_bloc.dart';
import 'package:gymapp_v2/features/training/bloc/training_bloc.dart';
import 'package:gymapp_v2/features/training/bloc/training_event.dart';
import 'package:gymapp_v2/features/training/bloc/training_state.dart';
import 'package:gymapp_v2/features/training/bloc/weekly_progress_cubit.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/measurement/ui/pages/add_measurement_page.dart';
import 'package:gymapp_v2/core/widgets/mini_sparkline_painter.dart';
import 'package:gymapp_v2/features/training/ui/widgets/activate_program_prompt.dart';

class ClientDashboardPage extends StatelessWidget {
  const ClientDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => const ClientDashboardView();
}

class ClientDashboardView extends StatefulWidget {
  const ClientDashboardView({super.key});

  @override
  State<ClientDashboardView> createState() => _ClientDashboardViewState();
}

class _ClientDashboardViewState extends State<ClientDashboardView> with WidgetsBindingObserver, RouteAware {
  // Kural 2: Dropdown referans hatasını önlemek için objenin kendisi yerine id/order tutulur.
  int? _selectedWorkoutDayOrder;
  int? _acknowledgedCycleIndex;
  int? _checkedProgramId;
  late final DietEntryBloc _dietEntryBloc;

  Future<void> _checkCycleAck(int programId) async {
    if (_checkedProgramId == programId) return;
    final storage = sl<FlutterSecureStorage>();
    final val = await storage.read(key: 'training_cycle_ack_$programId');
    if (mounted) {
      setState(() {
        _checkedProgramId = programId;
        _acknowledgedCycleIndex = val != null ? int.tryParse(val) : null;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void initState() {
    super.initState();
    _dietEntryBloc = context.read<DietEntryBloc>();
    WidgetsBinding.instance.addObserver(this);
    // Kural 1: Sayfa açılışında verileri otomatik yükle.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TrainingBloc>().add(const LoadMyPrograms());
        context.read<WeeklyProgressCubit>().loadMyProgress();
        
        _dietEntryBloc.add(const InitializeDietEntry());
        
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          _dietEntryBloc.subscribeToUpdates(authState.auth.id);
        }

        context.read<WaterBloc>().add(const LoadWaterSummary());
      }
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _dietEntryBloc.add(const UnsubscribeDietUpdates());
    super.dispose();
  }

  @override
  void didPopNext() {
    if (!mounted) return;
    context.read<TrainingBloc>().add(const LoadMyPrograms());
    context.read<WeeklyProgressCubit>().loadMyProgress();
    _dietEntryBloc.add(const InitializeDietEntry());
    context.read<WaterBloc>().add(const LoadWaterSummary());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<TrainingBloc>().add(const LoadMyPrograms());
      context.read<WeeklyProgressCubit>().loadMyProgress();
      _dietEntryBloc.add(const InitializeDietEntry());
      context.read<WaterBloc>().add(const LoadWaterSummary());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<TrainingBloc, TrainingState>(
        listenWhen: (prev, curr) =>
            (prev.status != curr.status && curr.status == TrainingStatus.success) ||
            prev.activePrograms != curr.activePrograms,
        listener: (context, state) {
          sl<AppLogger>().info(
            '[DASHBOARD_REACTIVE] TrainingBloc success durumu yakalandı veya program listesi değişti, progress yenileniyor...',
          );
          context.read<WeeklyProgressCubit>().loadMyProgress();
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, profileState) {
          String userName = 'Sporcu';
          if (profileState is ProfileLoaded) {
            userName = profileState.profile.fullName.split(' ').first;
          } else if (profileState is CoachProfileLoaded) {
            userName = profileState.profile.fullName.split(' ').first;
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TrainingBloc>().add(const LoadMyPrograms());
              context.read<WeeklyProgressCubit>().loadMyProgress();
              context.read<DietEntryBloc>().add(const InitializeDietEntry());
              context.read<WaterBloc>().add(const LoadWaterSummary());
            },
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(userName),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppSpacing.xs),
                      _buildOrphanedWarningSection(context),
                      _buildCycleResetBanner(context),
                      _buildHeroSection(context),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSectionHeader('GÜNLÜK ÖZET'),
                      const SizedBox(height: AppSpacing.md),
                      _buildBentoGrid(context),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

  Widget _buildAppBar(String userName) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        centerTitle: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HOŞ GELDİN',
                    style: AppTextStyles.cardLabel.copyWith(color: AppColors.primary, fontSize: 10),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'GÜNAYDIN, $userName 👋',
                    style: AppTextStyles.greeting.copyWith(fontSize: 20, letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.glassWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.textPrimary,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SectionHeader(
      label: title,
      icon: Icons.today_rounded,
    );
  }

  // --- Kural 3: Hero Section (Dinamik İdman Senaryosu v16) ---
  Widget _buildHeroSection(BuildContext context) {
    return BlocBuilder<TrainingBloc, TrainingState>(
      builder: (context, state) {
        sl<AppLogger>().info('🎨 [Dashboard-UI] BlocBuilder tetiklendi! Program Sayısı: ${state.activePrograms.length}');
        
        // Adım 2.1: Aktif programı filtreleyerek bul (v8)
        final TrainingBlock? activeProgram = state.activePrograms.isEmpty
            ? null
            : state.activePrograms.cast<TrainingBlock?>().firstWhere(
                (p) => p != null && p.isActive == true,
                orElse: () => null,
              );

        if (activeProgram != null) {
           String tree = '[DASHBOARD-TREE] Program ID: ${activeProgram.id}. Günler: ';
           for (var day in activeProgram.workoutDays) {
             tree += '${day.name} (${day.exercises.length} Ex), ';
           }
           sl<AppLogger>().info(tree);
        }

        if (activeProgram == null) {
          if (state.activePrograms.isEmpty) {
            return _buildNoProgramHero(context);
          } else {
            return const GlassContainer(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: ActivateProgramPrompt(),
            );
          }
        }

        final todayIndex = DateTime.now().weekday - 1; // 0-6 (Pazartesi-Pazar)
        
        // Bugünün idmanını bul
        WorkoutDay? todayWorkout;
        try {
          todayWorkout = activeProgram.workoutDays.firstWhere(
            (d) => d.dayOrder == todayIndex + 1,
          );
        } catch (_) {
          todayWorkout = null;
        }

        // Senaryo A: Bugün İdman Var mı?
        final bool hasWorkoutToday = todayWorkout != null && todayWorkout.exercises.isNotEmpty;

        if (hasWorkoutToday) {
          return _buildWorkoutTodayHero(context, activeProgram, todayWorkout);
        } else {
          return _buildRestDayHero(context, activeProgram);
        }
      },
    );
  }

  // Senaryo A: Bugün İdman Var
  Widget _buildWorkoutTodayHero(BuildContext context, TrainingBlock program, WorkoutDay day) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      overlayGradient: AppColors.heroGradient,
      shadow: AppElevation.accentGlow(AppColors.primary),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.bolt_rounded,
              color: AppColors.primary.withValues(alpha: 0.1),
              size: 72,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTag('GÜNÜN ODAK NOKTASI'),
                  const Spacer(),
                  const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'BUGÜNKÜ İDMAN: ${day.name.toUpperCase()}',
                style: AppTextStyles.heroTitle.copyWith(fontSize: 32, letterSpacing: -1.0),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Bugün ${day.exercises.length} egzersiz seni bekliyor. Hazır mısın?',
                style: AppTextStyles.bodyText,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => context.push('/workout-overview', extra: {
                  'program': program,
                  'day': day,
                }),
                style: _heroButtonStyle(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('İDMANI İNCELE VE BAŞLA',
                        style: AppTextStyles.buttonText.copyWith(color: Colors.black)),
                    const SizedBox(width: 12),
                    const Icon(Icons.play_arrow_rounded),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Senaryo B: Bugün Dinlenme Günü
  Widget _buildRestDayHero(BuildContext context, TrainingBlock program) {
    // Sadece egzersizi olan günleri filtrele
    final validDays = program.workoutDays.where((d) => d.exercises.isNotEmpty).toList();
    
    // Eğer henüz bir gün seçilmemişse veya seçili gün geçerli günlerin içinde bulunmuyorsa varsayılan günü seç
    if (validDays.isNotEmpty) {
      if (_selectedWorkoutDayOrder == null || !validDays.any((d) => d.dayOrder == _selectedWorkoutDayOrder)) {
        _selectedWorkoutDayOrder = validDays.first.dayOrder;
      }
    } else {
      _selectedWorkoutDayOrder = null;
    }

    // Seçili günü bul
    WorkoutDay? selectedDayObj;
    try {
      selectedDayObj = validDays.firstWhere((d) => d.dayOrder == _selectedWorkoutDayOrder);
    } catch (_) {
      selectedDayObj = validDays.isNotEmpty ? validDays.first : null;
    }

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      overlayGradient: AppColors.heroGradient,
      shadow: AppElevation.accentGlow(AppColors.primary),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.bedtime_rounded,
              color: AppColors.primary.withValues(alpha: 0.1),
              size: 72,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTag('DİNLENME GÜNÜ', color: AppColors.primary),
                  const Spacer(),
                  const Icon(Icons.bedtime_rounded, color: AppColors.primary, size: 20),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Bugün Dinlenme Günün',
                style: AppTextStyles.heroTitle.copyWith(fontSize: 32, letterSpacing: -1.0),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Boş durmak istemiyor musun? Başka bir idman seç:',
                style: AppTextStyles.bodyText,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildWorkoutDropdown(validDays),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: selectedDayObj != null ? () {
                  context.push('/workout-overview', extra: {
                    'program': program,
                    'day': selectedDayObj,
                  });
                } : null,
                style: _heroButtonStyle(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('GÜNÜ İNCELE VE BAŞLA', style: AppTextStyles.buttonText.copyWith(color: Colors.black)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, {Color color = AppColors.primary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: AppTextStyles.tagText.copyWith(color: color),
      ),
    );
  }

  ButtonStyle _heroButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.black,
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      elevation: 8,
      shadowColor: AppColors.primary.withValues(alpha: 0.4),
    );
  }

  Widget _buildWorkoutDropdown(List<WorkoutDay> days) {
    final int? activeValue = days.any((day) => day.dayOrder == _selectedWorkoutDayOrder)
        ? _selectedWorkoutDayOrder
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: activeValue,
          isExpanded: true,
          dropdownColor: AppColors.background,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
          style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          items: days.map((day) {
            return DropdownMenuItem<int>(
              value: day.dayOrder,
              child: Text(day.name),
            );
          }).toList(),
          onChanged: (order) {
            setState(() {
              _selectedWorkoutDayOrder = order;
            });
          },
        ),
      ),
    );
  }

  Widget _buildNoProgramHero(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      overlayGradient: AppColors.heroGradient,
      shadow: AppElevation.accentGlow(AppColors.primary),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.fitness_center_rounded,
              color: AppColors.primary.withValues(alpha: 0.1),
              size: 72,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aktif Program Yok',
                style: AppTextStyles.heroTitle.copyWith(fontSize: 32, letterSpacing: -1.0),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Gelişimin için bir program oluştur veya koçunun atamasını bekle.',
                style: AppTextStyles.bodyText,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => context.push('/exercises'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                child: Text('EGZERSİZLER',
                    style: AppTextStyles.buttonText.copyWith(color: Colors.black)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- ADIM 3: Bento Box Grid (Günlük Özet) ---
  Widget _buildBentoGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: const NutritionBento(),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 180,
                child: Column(
                  children: [
                    Expanded(child: _buildWaterBento(context)),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(child: _buildAnalysisBento(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _buildTrainingProgressBento(context),
      ],
    );
  }

  Widget _buildTrainingProgressBento(BuildContext context) {
    final color = AppColors.primary;

    return BlocBuilder<TrainingBloc, TrainingState>(
      builder: (context, trainingState) {
        final hasActive = trainingState.activePrograms.any((p) => p.isActive);

        if (!hasActive) {
          return PressableScale(
            onTap: () async {
              await context.push('/training');
              if (context.mounted) {
                context.read<TrainingBloc>().add(const LoadMyPrograms());
                context.read<WeeklyProgressCubit>().loadMyProgress();
              }
            },
            child: GlassContainer(
              elevated: true,
              border: Border.all(color: color.withValues(alpha: 0.15)),
              shadow: AppElevation.softGlow(color),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GELİŞİM',
                        style: AppTextStyles.cardLabel.copyWith(color: color),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Aktif programın bulunmuyor.',
                        style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
                ],
              ),
            ),
          );
        }

        return PressableScale(
          onTap: () async {
            await context.push('/training');
            if (context.mounted) {
              context.read<TrainingBloc>().add(const LoadMyPrograms());
              context.read<WeeklyProgressCubit>().loadMyProgress();
            }
          },
          child: GlassContainer(
            elevated: true,
            border: Border.all(color: color.withValues(alpha: 0.15)),
            shadow: AppElevation.softGlow(color),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GELİŞİM',
                      style: AppTextStyles.cardLabel.copyWith(color: color),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    BlocBuilder<WeeklyProgressCubit, WeeklyProgressState>(
                      builder: (context, state) {
                        String completed = '-';
                        String target = '-';
                        String label = 'Haftalık İdmanlarım';
                        if (state is WeeklyProgressLoaded) {
                          completed = '${state.progress.completedDays}';
                          target = '${state.progress.targetDays}';
                          label = 'Haftalık Başarı: %${state.progress.successPercentage.toInt()}';
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$completed/$target',
                                  style: AppTextStyles.cardValue,
                                ),
                                const SizedBox(width: 4),
                                Text('gün', style: AppTextStyles.cardCaption),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: AppTextStyles.cardCaption.copyWith(color: color, fontWeight: FontWeight.bold),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                BlocBuilder<WeeklyProgressCubit, WeeklyProgressState>(
                  builder: (context, state) {
                    double progress = 0.0;
                    if (state is WeeklyProgressLoaded) {
                      progress = state.progress.successPercentage / 100.0;
                    }
                    return StatRing(
                      progress: progress,
                      color: color,
                      size: 70,
                      center: Text(
                        '%${(progress * 100).toInt()}',
                        style: AppTextStyles.cardCaption.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaterBento(BuildContext context) {
    final color = AppColors.primary;
    return PressableScale(
      onTap: () => context.push('/water-tracking'),
      child: GlassContainer(
        elevated: true,
        border: Border.all(color: color.withValues(alpha: 0.15)),
        shadow: AppElevation.softGlow(color),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'SU TAKİBİ',
                  style: AppTextStyles.cardLabel.copyWith(color: color),
                ),
                const Spacer(),
                Icon(Icons.arrow_outward_rounded, color: color.withValues(alpha: 0.5), size: 12),
              ],
            ),
            Row(
              children: [
                BlocBuilder<WaterBloc, WaterState>(
                  builder: (context, state) {
                    String val = '0.0L';
                    if (state is WaterLoaded) {
                      val = '${(state.summary.totalIntakeMl / 1000).toStringAsFixed(1)}L';
                    }
                    return Text(
                      val,
                      style: AppTextStyles.cardValue.copyWith(fontSize: 20),
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.read<WaterBloc>().add(const AddWaterIntake(250));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('250ml su eklendi 💧'),
                              duration: Duration(milliseconds: 800),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: color.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            '+250',
                            style: AppTextStyles.cardCaption.copyWith(color: AppColors.textPrimary, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      GestureDetector(
                        onTap: () {
                          context.read<WaterBloc>().add(const AddWaterIntake(500));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('500ml su eklendi 💧'),
                              duration: Duration(milliseconds: 800),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: color.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            '+500',
                            style: AppTextStyles.cardCaption.copyWith(color: AppColors.textPrimary, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisBento(BuildContext context) {
    final color = AppColors.primary;
    return PressableScale(
      onTap: () => context.push('/progress-charts'),
      child: GlassContainer(
        elevated: true,
        border: Border.all(color: color.withValues(alpha: 0.15)),
        shadow: AppElevation.softGlow(color),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'ANALİZ',
                          style: AppTextStyles.cardLabel.copyWith(color: color),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.push<bool>(
                            context,
                            MaterialPageRoute<bool>(
                              builder: (_) => const AddMeasurementPage(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xxs),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add_rounded, color: color, size: 16),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Grafik',
                    style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              width: 50,
              height: 30,
              child: CustomPaint(
                painter: MiniSparklinePainter(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrphanedWarningSection(BuildContext context) {
    return BlocBuilder<TrainingBloc, TrainingState>(
      builder: (context, state) {
        final orphanedPrograms = state.activePrograms.where((p) => p.isOrphaned).toList();
        if (orphanedPrograms.isEmpty) return const SizedBox.shrink();

        final program = orphanedPrograms.first;

        return GlassContainer(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.md),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'PROGRAM DURUMU UYARISI',
                    style: AppTextStyles.bodyText.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Antrenörünüz "${program.name}" programını sildi veya sizinle bağını kopardı. Bu antrenman programını kendi kişisel programınız olarak saklamak istiyor musunuz?',
                style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<TrainingBloc>().add(ApproveOrphanedProgram(id: program.id, keep: true));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                      ),
                      child: Text('Sakla (Kişisel Yap)', style: AppTextStyles.buttonText.copyWith(color: Colors.black, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.read<TrainingBloc>().add(ApproveOrphanedProgram(id: program.id, keep: false));
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                      ),
                      child: Text('Sil', style: AppTextStyles.buttonText.copyWith(color: AppColors.error, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCycleResetBanner(BuildContext context) {
    return BlocBuilder<TrainingBloc, TrainingState>(
      builder: (context, state) {
        final TrainingBlock? activeProgram = state.activePrograms.isEmpty
            ? null
            : state.activePrograms.cast<TrainingBlock?>().firstWhere(
                (p) => p != null && p.isActive == true,
                orElse: () => null,
              );

        if (activeProgram == null) return const SizedBox.shrink();

        final elapsedDays = DateTime.now().difference(activeProgram.startDate).inDays;
        final int gunFarki = elapsedDays < 0 ? 0 : elapsedDays;
        final int toplamHafta = (gunFarki / 7).floor() + 1;
        final int durationWeeks = activeProgram.durationWeeks;
        final int donguIndeksi = (toplamHafta - 1) ~/ durationWeeks;

        if (donguIndeksi < 1) return const SizedBox.shrink();

        // Async kontrolü tetikle
        _checkCycleAck(activeProgram.id);

        if (_acknowledgedCycleIndex != null && _acknowledgedCycleIndex! >= donguIndeksi) {
          return const SizedBox.shrink();
        }

        return GlassContainer(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.md),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.loop_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'YENİ DÖNGÜ BAŞLADI',
                    style: AppTextStyles.bodyText.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Programınız yeni döngüye başladı (Tur ${donguIndeksi + 1}). 1. haftadan tekrar başlıyorsunuz!',
                style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () async {
                  await sl<FlutterSecureStorage>().write(
                    key: 'training_cycle_ack_${activeProgram.id}',
                    value: donguIndeksi.toString(),
                  );
                  if (mounted) {
                    setState(() {
                      _acknowledgedCycleIndex = donguIndeksi;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
                child: Text(
                  'Anladım',
                  style: AppTextStyles.buttonText.copyWith(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
