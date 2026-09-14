import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/features/measurement/models/client_measurements_summary.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/assigned_programs/assigned_programs_cubit.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/coach_diet_templates/coach_diet_templates_cubit.dart';
import 'package:gymapp_v2/features/training/bloc/weekly_progress_cubit.dart';
import 'package:gymapp_v2/features/training/presentation/bloc/assigned_programs/assigned_programs_state.dart';
import 'package:gymapp_v2/features/training/models/assigned_program_models.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/coach_diet_templates/coach_diet_templates_state.dart';
import 'package:go_router/go_router.dart';

import 'package:gymapp_v2/features/training/ui/widgets/weekly_history_section.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';

class CoachStudentDetailPage extends StatefulWidget {
  final int studentId;
  final String studentName;
  final ClientMeasurementsSummary? measurementSummary;

  const CoachStudentDetailPage({
    super.key,
    required this.studentId,
    required this.studentName,
    this.measurementSummary,
  });

  @override
  State<CoachStudentDetailPage> createState() => _CoachStudentDetailPageState();
}

class _CoachStudentDetailPageState extends State<CoachStudentDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        BlocProvider<WeeklyProgressCubit>(
          create: (context) => sl<WeeklyProgressCubit>()..loadClientProgress(widget.studentId),
        ),
      ],
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
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.studentName,
            style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Diyet & Beslenme'),
              Tab(text: 'Antrenman & Gelişim'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDietTab(),
            _buildTrainingTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDietTab() {
    return BlocBuilder<CoachDietTemplatesCubit, CoachDietTemplatesState>(
      builder: (context, dietState) {
        final studentPrograms = dietState.templates.where((t) {
          final assignments = dietState.templateAssignments[t.id] ?? [];
          return assignments.any((a) => a.studentId == widget.studentId);
        }).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Aktif Diyet Programları'),
              SizedBox(height: AppSpacing.sm),
              if (studentPrograms.isEmpty)
                _buildEmptyState('Atanmış program bulunmuyor.', Icons.restaurant_rounded)
              else
                ...studentPrograms.map((p) => _buildDietCard(p)),
              SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => context.push('/coach-diet-templates'),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Şablonlardan Ata'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrainingTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Haftalık Gelişim'),
          SizedBox(height: AppSpacing.sm),
          _buildWeeklyProgressCard(),
          SizedBox(height: AppSpacing.lg),
          
          // Haftalık Başarı Geçmişi (Ayrı/İzole Cubit Örneği)
          BlocProvider<WeeklyProgressCubit>(
            create: (context) => sl<WeeklyProgressCubit>()..loadClientHistory(widget.studentId),
            child: BlocBuilder<WeeklyProgressCubit, WeeklyProgressState>(
              builder: (context, progressState) {
                if (progressState is WeeklyProgressLoading) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }
                if (progressState is WeeklyHistoryLoaded) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.lg),
                    child: WeeklyHistorySection(history: progressState.history),
                  );
                }
                if (progressState is WeeklyProgressError) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Text(
                      progressState.message,
                      style: AppTextStyles.bodyText.copyWith(color: AppColors.error),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          _buildSectionTitle('Antrenman Atamaları'),
          SizedBox(height: AppSpacing.sm),
          _buildTrainingAssignmentsList(),
          SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => context.push('/training', extra: {'targetStudentId': widget.studentId}),
            icon: const Icon(Icons.add_task_rounded),
            label: const Text('Yeni Antrenman Ata'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressCard() {
    return BlocBuilder<WeeklyProgressCubit, WeeklyProgressState>(
      builder: (context, state) {
        if (state is WeeklyProgressLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is WeeklyProgressLoaded) {
          final progress = state.progress;
          return GlassContainer(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Hedef', '${progress.targetDays} Gün', Icons.flag_outlined),
                _buildStatItem('Tamamlanan', '${progress.completedDays} Gün', Icons.check_circle_outline),
                _buildStatItem('Başarı', '%${progress.successPercentage.toInt()}', Icons.auto_awesome_rounded),
              ],
            ),
          );
        }
        return _buildEmptyState('Gelişim verisi bulunmuyor.', Icons.show_chart_rounded);
      },
    );
  }

  Widget _buildTrainingAssignmentsList() {
    return BlocBuilder<AssignedProgramsCubit, AssignedProgramsState>(
      builder: (context, state) {
        final assignedToThisStudent = state.programs.where((p) => 
          p.assignedStudents.any((s) => s.studentId == widget.studentId)).toList();

        if (assignedToThisStudent.isEmpty) {
          return _buildEmptyState('Atanmış antrenman bulunmuyor.', Icons.fitness_center_rounded);
        }

        return Column(
          children: assignedToThisStudent.map((p) => _buildTrainingCard(p)).toList(),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary)),
        Text(label, style: AppTextStyles.cardLabel.copyWith(color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildDietCard(DietProgramModel p) {
    return GlassContainer(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.restaurant_menu_rounded, color: AppColors.primary),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                Text('${p.targetCalories.toInt()} kcal', style: AppTextStyles.sectionLabel.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted.withValues(alpha: 0.24)),
        ],
      ),
    );
  }

  Widget _buildTrainingCard(ProgramWithAssignments p) {
    return GlassContainer(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: AppColors.primary),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(p.programName, style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted.withValues(alpha: 0.24)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.sectionLabel.copyWith(color: AppColors.primary, letterSpacing: 1.1),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return GlassContainer(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted.withValues(alpha: 0.2)),
          SizedBox(height: AppSpacing.md),
          Text(msg, style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
