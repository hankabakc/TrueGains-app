import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/widgets/network_avatar.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/features/measurement/models/client_measurements_summary.dart';
import 'package:gymapp_v2/features/measurement/repository/measurement_repository.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/assigned_programs/assigned_programs_cubit.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/assigned_programs/assigned_programs_state.dart';
import 'package:gymapp_v2/features/training/models/assigned_program_models.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/coach_diet_templates/coach_diet_templates_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/coach_diet_templates/coach_diet_templates_state.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/coach_water_tracking/coach_water_tracking_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/coach_water_tracking/coach_water_tracking_state.dart';
import 'package:gymapp_v2/features/nutrition/data/models/client_water_tracking_model.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/coach_student_progress_bloc.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/coach_student_progress_state.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/client_profile_view/client_profile_view_cubit.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/client_profile_view/client_profile_view_state.dart';

class Client360DashboardPage extends StatefulWidget {
  final int studentId;
  final String studentName;
  final ClientMeasurementsSummary? measurementSummary;

  const Client360DashboardPage({
    super.key,
    required this.studentId,
    required this.studentName,
    this.measurementSummary,
  });

  @override
  State<Client360DashboardPage> createState() => _Client360DashboardPageState();
}

class _Client360DashboardPageState extends State<Client360DashboardPage> {
  // Navigasyonda gelen anlık görüntüyle başlar, ardından sunucudan TAZE veriyle güncellenir.
  // Böylece sporcu yeni bir ölçüm paylaştığında 360 panelinde anında görünür.
  ClientMeasurementsSummary? _measurementSummary;

  @override
  void initState() {
    super.initState();
    _measurementSummary = widget.measurementSummary;
    _refreshSharedMeasurements();
  }

  Future<void> _refreshSharedMeasurements() async {
    final fresh = await sl<MeasurementRepository>().getSharedMeasurementsForClient(widget.studentId);
    if (!mounted || fresh == null) return;
    setState(() => _measurementSummary = fresh);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AssignedProgramsCubit>(
          create: (context) => sl<AssignedProgramsCubit>()..loadAssignedPrograms(),
        ),
        BlocProvider<CoachDietTemplatesCubit>(
          create: (context) => sl<CoachDietTemplatesCubit>()..loadTemplatesWithAssignments(),
        ),
        BlocProvider<CoachWaterTrackingCubit>(
          create: (context) => sl<CoachWaterTrackingCubit>()..loadStudentWaterIntakes(),
        ),
        BlocProvider<CoachStudentProgressBloc>(
          create: (context) => sl<CoachStudentProgressBloc>(),
        ),
        BlocProvider<ClientProfileViewCubit>(
          create: (context) => sl<ClientProfileViewCubit>()..load(widget.studentId),
        ),
      ],
      child: BlocListener<CoachStudentProgressBloc, CoachStudentProgressState>(
        listener: (context, state) {
          if (state is CoachStudentProgressOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
            );
          } else if (state is CoachStudentProgressError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/main');
              }
            },
          ),
          title: Text(
            'Danışan 360° Paneli',
            style: AppTextStyles.heroTitle.copyWith(fontSize: 20),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle('Hedef & Seviye'),
              const SizedBox(height: AppSpacing.sm),
              _buildGoalLevelCard(),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle('Beslenme & Diyet'),
              const SizedBox(height: AppSpacing.sm),
              _buildDietSummaryCard(),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle('Su Takibi'),
              const SizedBox(height: AppSpacing.sm),
              _buildWaterSummaryCard(),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle('Antrenman Programları'),
              const SizedBox(height: AppSpacing.sm),
              _buildTrainingSummaryCard(),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle('Vücut Ölçümleri'),
              const SizedBox(height: AppSpacing.sm),
              _buildMeasurementSummaryCard(),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle('Finans & Yönetim'),
              const SizedBox(height: AppSpacing.sm),
              _buildFinanceAndDocsCard(context),
              const SizedBox(height: AppSpacing.xl), // Bottom padding
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.sectionLabel.copyWith(
        fontSize: 13,
        letterSpacing: 1.2,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildProfileHeader() {
    return BlocBuilder<ClientProfileViewCubit, ClientProfileViewState>(
      builder: (context, state) {
        final profile = state.profile;
        final hasProfile = state.status == ClientProfileViewStatus.loaded && profile != null;
        return InkWell(
          onTap: hasProfile
              ? () {
                  context.push(
                    '/profile/detail',
                    extra: {
                      'profileData': profile,
                      'readOnly': true,
                    },
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: GlassContainer(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                NetworkAvatar(
                  imageUrl: hasProfile ? profile.profilePhotoUrl : null,
                  fallbackText: widget.studentName,
                  size: 60,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.studentName,
                        style: AppTextStyles.greeting.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Aktif Danışan',
                        style: AppTextStyles.listSubtitle,
                      ),
                    ],
                  ),
                ),
                if (hasProfile)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDietSummaryCard() {
    return BlocBuilder<CoachDietTemplatesCubit, CoachDietTemplatesState>(
      builder: (context, dietState) {
        final studentDietPrograms = <DietProgramModel>[];
        final assignmentsMap = <int, int>{}; // programId -> assignedProgramId

        for (var t in dietState.templates) {
          final assignments = dietState.templateAssignments[t.id] ?? [];
          final clientAssignment = assignments.where(
            (a) => a.studentId == widget.studentId,
          );
          if (clientAssignment.isNotEmpty) {
            studentDietPrograms.add(t);
            assignmentsMap[t.id] = clientAssignment.first.assignedProgramId;
          }
        }

        final isLoading = dietState.status == CoachDietTemplatesStatus.loading;

        if (isLoading && studentDietPrograms.isEmpty) {
          return const GlassContainer(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        return Column(
          children: [
            ElevatedButton.icon(
              onPressed:
                  () => context.push(
                    '/nutrition/analytics',
                    extra: {'targetUserId': widget.studentId},
                  ),
              icon: const Icon(
                Icons.bar_chart_rounded,
                size: 20,
                color: AppColors.success,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary.withValues(alpha: 0.05),
                foregroundColor: AppColors.textPrimary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              label: const Text('Beslenme Analizlerini Gör'),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (studentDietPrograms.isEmpty)
              _buildSectionEmptyState(
                'Atanmış diyet programı bulunmuyor.',
                Icons.restaurant_rounded,
              )
            else
              Column(
                children:
                    studentDietPrograms.map((t) {
                      final assignedProgramId = assignmentsMap[t.id]!;
                      return _buildDietProgramCard(t, assignedProgramId);
                    }).toList(),
              ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: () => context.push('/coach-diet-templates'),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                foregroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              label: const Text('Yeni Diyet Şablonu Ata'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDietProgramCard(DietProgramModel t, int assignedProgramId) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.name,
                  style: AppTextStyles.listTitle,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Hedef: ${t.targetCalories.toInt()} kcal | P: ${t.targetProtein.toInt()}g - K: ${t.targetCarbs.toInt()}g - Y: ${t.targetFat.toInt()}g',
                  style: AppTextStyles.cardCaption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          ElevatedButton(
            onPressed: () {
              context.push('/nutrition/dashboard/$assignedProgramId');
            },
            style: ElevatedButton.styleFrom(
              minimumSize:
                  Size.zero, // Overrides the global double.infinity theme
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            child: Text(
              'Düzenle',
              style: AppTextStyles.buttonText.copyWith(fontSize: 12, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterSummaryCard() {
    return BlocBuilder<CoachWaterTrackingCubit, CoachWaterTrackingState>(
      builder: (context, state) {
        if (state is CoachWaterTrackingLoading) {
          return const GlassContainer(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (state is CoachWaterTrackingError) {
          return GlassContainer(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: Text(
                state.message,
                style: AppTextStyles.bodyText.copyWith(color: AppColors.error),
              ),
            ),
          );
        }

        if (state is CoachWaterTrackingLoaded) {
          final waterIntakes = state.studentWaterIntakes;
          final hasIntake = waterIntakes.any(
            (w) => w.clientId == widget.studentId,
          );

          if (!hasIntake) {
            return _buildSectionEmptyState(
              'Bugün için girilmiş su verisi bulunmuyor.',
              Icons.water_drop_rounded,
            );
          }

          final ClientWaterTrackingModel clientWater = waterIntakes.firstWhere(
            (w) => w.clientId == widget.studentId,
          );
          final progressPercent = clientWater.ratio;

          return GlassContainer(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.water_drop_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${clientWater.consumedWaterMl} ml / ${clientWater.targetWaterMl} ml',
                            style: AppTextStyles.emptyTitle,
                          ),
                          SizedBox(height: AppSpacing.xxs / 2),
                          Text(
                            'Günlük Su Tüketim Hedefi',
                            style: AppTextStyles.listSubtitle.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '%${(progressPercent * 100).toInt()}',
                      style: AppTextStyles.emptyTitle.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    minHeight: 8,
                    backgroundColor: AppColors.textPrimary.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return _buildSectionEmptyState(
          'Su verileri yüklenemedi.',
          Icons.water_drop_rounded,
        );
      },
    );
  }

  Widget _buildTrainingSummaryCard() {
    return BlocBuilder<AssignedProgramsCubit, AssignedProgramsState>(
      builder: (context, trainingState) {
        final studentTrainingPrograms = <ProgramWithAssignments>[];
        for (var p in trainingState.programs) {
          if (p.assignedStudents.any((s) => s.studentId == widget.studentId)) {
            studentTrainingPrograms.add(p);
          }
        }

        final isLoading =
            trainingState.status == AssignedProgramsStatus.loading;

        if (isLoading && studentTrainingPrograms.isEmpty) {
          return const GlassContainer(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        return Column(
          children: [
            ElevatedButton.icon(
              onPressed: () => context.push(
                '/workout-history',
                extra: widget.studentId,
              ),
              icon: const Icon(
                Icons.history_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary.withValues(alpha: 0.05),
                foregroundColor: AppColors.textPrimary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              label: const Text('Antrenman Geçmişini Gör'),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (studentTrainingPrograms.isEmpty)
              _buildSectionEmptyState(
                'Atanmış antrenman programı bulunmuyor.',
                Icons.fitness_center_rounded,
              )
            else
              Column(
                children:
                    studentTrainingPrograms.map((p) {
                      return _buildTrainingProgramCard(p);
                    }).toList(),
              ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: () => context.push(
                '/training',
                extra: {'targetStudentId': widget.studentId},
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                foregroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              label: const Text('Yeni Antrenman Ata'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrainingProgramCard(ProgramWithAssignments p) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.programName,
                  style: AppTextStyles.listTitle,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Aktif Atama',
                  style: AppTextStyles.listSubtitle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementSummaryCard() {
    final hasMeasurements =
        _measurementSummary != null &&
        _measurementSummary!.measurements.isNotEmpty;

    if (!hasMeasurements) {
      return _buildSectionEmptyState(
        'Henüz paylaşılan ölçüm yok.',
        Icons.straighten_rounded,
      );
    }

    return Column(
      children: [
        _buildSummaryCard(),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed:
                  () => context.push(
                    '/progress-charts',
                    extra: widget.studentId,
                  ),
              icon: const Icon(Icons.bar_chart_rounded, size: 18),
              label: const Text('Grafikleri Gör'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
            TextButton.icon(
              onPressed:
                  () => context.push(
                    '/measurements',
                    extra: widget.studentId,
                  ),
              icon: const Icon(Icons.history_rounded, size: 18),
              label: const Text('Tüm Ölçüm Geçmişi'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Column(
          children:
              _measurementSummary!.measurements.take(3).map((m) {
                final dateStr =
                    '${m.measurementDate.day}.${m.measurementDate.month}.${m.measurementDate.year}';
                return GlassContainer(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        dateStr,
                        style: AppTextStyles.bodyText.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${m.weight ?? "--"} kg',
                        style: AppTextStyles.buttonText.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final latest = _measurementSummary!.measurements.first;
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Kilo', '${latest.weight ?? "--"} kg'),
          _summaryItem('Yağ %', '${latest.bodyFatPct ?? "--"}%'),
          _summaryItem('Bel', '${latest.waist ?? "--"} cm'),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.cardCaption,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: AppTextStyles.bubbleText.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceAndDocsCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: InkWell(
        onTap: () {
          context.push(
            '/coach/student-finance/${widget.studentId}',
            extra: {'studentName': widget.studentName},
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.payments_rounded,
                color: AppColors.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Ödemeler',
              style: AppTextStyles.buttonText.copyWith(color: AppColors.textPrimary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionEmptyState(String msg, IconData icon) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            msg,
            style: AppTextStyles.listSubtitle,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalLevelCard() {
    return BlocBuilder<ClientProfileViewCubit, ClientProfileViewState>(
      builder: (context, state) {
        if (state.status == ClientProfileViewStatus.loading) {
          return const GlassContainer(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          );
        }

        if (state.status == ClientProfileViewStatus.loaded && state.profile != null) {
          final profile = state.profile!;
          return GlassContainer(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _goalLevelItem('Hedef', profile.goal?.toUIString() ?? '—', Icons.flag_rounded),
                _goalLevelItem('Aktivite', profile.activityLevel?.toUIString() ?? '—', Icons.directions_run_rounded),
                _goalLevelItem('Deneyim', profile.experienceLevel?.toUIString() ?? '—', Icons.military_tech_outlined),
              ],
            ),
          );
        }

        if (state.status == ClientProfileViewStatus.failure) {
          return _buildSectionEmptyState('Hedef bilgisi yüklenemedi.', Icons.flag_outlined);
        }

        return _buildSectionEmptyState('Hedef bilgisi bulunmuyor.', Icons.flag_outlined);
      },
    );
  }

  Widget _goalLevelItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.cardCaption,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTextStyles.bubbleText.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
