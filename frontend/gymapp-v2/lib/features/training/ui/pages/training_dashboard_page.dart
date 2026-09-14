import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/core/widgets/pressable_scale.dart';
import 'package:gymapp_v2/core/widgets/list_skeleton.dart';
import 'package:gymapp_v2/core/widgets/network_avatar.dart';
import 'package:gymapp_v2/features/training/bloc/training_bloc.dart';
import 'package:gymapp_v2/features/training/bloc/training_event.dart';
import 'package:gymapp_v2/features/training/bloc/training_state.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';
import 'package:gymapp_v2/features/training/models/exercise.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/social_bloc.dart';
import 'package:gymapp_v2/features/social/data/models/discovery_user_model.dart';
import 'package:gymapp_v2/features/training/ui/widgets/assigned_programs_tab.dart';

class TrainingDashboardPage extends StatefulWidget {
  final int? targetStudentId;
  const TrainingDashboardPage({super.key, this.targetStudentId});

  @override
  State<TrainingDashboardPage> createState() => _TrainingDashboardPageState();
}

class _TrainingDashboardPageState extends State<TrainingDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TrainingBloc _trainingBloc;

  bool get _isCoach {
    final state = context.read<AuthBloc>().state;
    return state is AuthAuthenticated && state.auth.role == UserRole.COACH;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _trainingBloc = context.read<TrainingBloc>();

    if (_isCoach) {
      _trainingBloc.add(const LoadCoachTemplates());
      _trainingBloc.add(const LoadCoachAssignedPrograms());
    } else {
      _trainingBloc.add(const LoadMyPrograms());

      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _trainingBloc.add(SubscribeToTrainingUpdates(authState.auth.id));
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _trainingBloc.add(const UnsubscribeFromTrainingUpdates());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isCoach ? 'Eğitim Yönetimi' : 'Programlarım',
          style: AppTextStyles.pageTitle,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          labelStyle: AppTextStyles.tagText.copyWith(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
          tabs: _isCoach
              ? const [
                  Tab(text: 'ŞABLONLAR'),
                  Tab(text: 'ATANANLAR'),
                ]
              : const [
                  Tab(text: 'KİŞİSEL'),
                  Tab(text: 'ANTRENÖR'),
                ],
        ),
      ),
      body: BlocConsumer<TrainingBloc, TrainingState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
            context.read<TrainingBloc>().add(const ClearTrainingMessages());
          } else if (state.successMessage != null) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.primary,
              ),
            );
            context.read<TrainingBloc>().add(const ClearTrainingMessages());
          }
        },
        builder: (context, state) {
          if (state.status == TrainingStatus.loading) {
            return const ListSkeleton();
          }

          if (state.status == TrainingStatus.failure) {
            return _buildErrorState(state.errorMessage ?? 'Hata oluştu');
          }

          if (_isCoach) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildProgramList(
                  context,
                  state.coachTemplates,
                  isTemplateList: true,
                ),
                const AssignedProgramsTab(),
              ],
            );
          }

          final personal =
              state.activePrograms.where((p) => p.isPersonal).toList();
          final fromCoach =
              state.activePrograms.where((p) => !p.isPersonal).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildProgramList(context, personal, isPersonal: true),
              _buildProgramList(context, fromCoach, isPersonal: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgramList(
    BuildContext context,
    List<TrainingBlock> programs, {
    bool isPersonal = false,
    bool isTemplateList = false,
    bool isAssignedList = false,
  }) {
    return Column(
      children: [
        if (isTemplateList || (isPersonal && _isCoach) || (!_isCoach && isPersonal))
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Row(
              children: [
                if (isTemplateList || (isPersonal && _isCoach) || (!_isCoach && isPersonal))
                  Expanded(
                    child: PremiumButton(
                      text: isTemplateList ? 'Yeni Şablon' : 'Yeni Program',
                      icon: Icons.add_rounded,
                      onPressed: () async {
                        final value = await context.push(
                          '/create-personal-program',
                          extra: isTemplateList ? 'template' : null,
                        );
                        if (value == true && mounted && context.mounted) {
                          context.read<TrainingBloc>().add(
                                isTemplateList
                                    ? const LoadCoachTemplates()
                                    : const LoadMyPrograms(),
                              );
                        }
                      },
                    ),
                  ),
                if (!_isCoach && isPersonal) ...[
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filledTonal(
                    onPressed: () => context.push('/workout-history'),
                    icon: const Icon(Icons.history_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.glassWhite,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.all(AppSpacing.md),
                    ),
                  ),
                ],
              ],
            ),
          ),
        Expanded(
          child: programs.isEmpty
              ? _buildEmptyState(isPersonal, isTemplateList, isAssignedList)
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: programs.length,
                  itemBuilder: (context, index) => _buildProgramCard(
                    programs[index],
                    isTemplate: isTemplateList,
                    isAssigned: isAssignedList,
                  ),
                ),
        ),
      ],
    );
  }

  bool _shouldShowDelete(TrainingBlock program, bool isTemplate, bool isAssigned) {
    if (_isCoach) {
      return true;
    } else {
      return program.isPersonal && program.coachId == null;
    }
  }

  Widget _buildProgramCard(TrainingBlock program,
      {bool isTemplate = false, bool isAssigned = false}) {
    final int dayCount = program.workoutDays.where((day) => day.exercises.isNotEmpty).length;
    final int exerciseCount = program.workoutDays.fold(0, (sum, day) => sum + day.exercises.length);
    
    final int durationWeeks = program.durationWeeks;

    double? progressPercent;
    int currentWeek = 0;
    if (program.isActive && !isTemplate) {
      final elapsedDays = DateTime.now().difference(program.startDate).inDays;
      final int gunFarki = elapsedDays < 0 ? 0 : elapsedDays;
      final int toplamHafta = (gunFarki / 7).floor() + 1;
      currentWeek = ((toplamHafta - 1) % durationWeeks) + 1;
      progressPercent = currentWeek / durationWeeks;
    }

    final distinctMuscles = program.workoutDays
        .expand((day) => day.exercises)
        .map((ex) => ex.muscleGroup)
        .whereType<MuscleGroup>()
        .toSet()
        .toList();

    return PressableScale(
      onTap: () async {
        if (!_isCoach && program.coachId != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Bu program antrenörünüz tarafından atandığı için sadece görüntülenebilir.'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
          );
        }

        final v = await context.push(
          '/create-personal-program',
          extra: program,
        );
        if (v == true && mounted && context.mounted) {
          context.read<TrainingBloc>().add(
                isTemplate
                    ? const LoadCoachTemplates()
                    : (isAssigned
                        ? const LoadCoachAssignedPrograms()
                        : const LoadMyPrograms()),
              );
        }
      },
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        shadow: AppElevation.cardShadow,
        borderRadius: AppRadius.xl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.name,
                        style: AppTextStyles.listTitle.copyWith(fontSize: 18),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isTemplate && !isAssigned && program.isActive) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'AKTİF',
                            style: AppTextStyles.tagText.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_shouldShowDelete(program, isTemplate, isAssigned))
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.textMuted,
                          size: 22,
                        ),
                        onPressed: () {
                          if (!_isCoach && program.coachId != null) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Antrenörünüzün atadığı programları silemezsiniz.'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                              ),
                            );
                            return;
                          }
                          _showDeleteConfirmation(context,
                              program,
                              isTemplate: isTemplate, isAssigned: isAssigned);
                        },
                      ),
                    if (isTemplate)
                      IconButton(
                        icon: const Icon(
                          Icons.edit_note_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                        onPressed: () async {
                          final v = await context.push(
                            '/create-personal-program',
                            extra: program,
                          );
                          if (v == true && mounted && context.mounted) {
                            context.read<TrainingBloc>().add(
                              const LoadCoachTemplates(),
                            );
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
            if (program.description != null && program.description!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                program.description!,
                style: AppTextStyles.bodyText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatCell(
                    icon: Icons.calendar_view_week_rounded,
                    value: '$dayCount',
                    label: 'GÜN',
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.glassBorder),
                Expanded(
                  child: _StatCell(
                    icon: Icons.fitness_center_rounded,
                    value: '$exerciseCount',
                    label: 'EGZERSİZ',
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.glassBorder),
                Expanded(
                  child: _StatCell(
                    icon: Icons.schedule_rounded,
                    value: '$durationWeeks',
                    label: 'HAFTA',
                  ),
                ),
              ],
            ),
            if (distinctMuscles.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  ...distinctMuscles.take(5).map((mg) => _MuscleChip(muscle: mg)),
                  if (distinctMuscles.length > 5)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: AppColors.glassWhite,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '+${distinctMuscles.length - 5}',
                        style: AppTextStyles.tagText.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ],
            if (progressPercent != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('İLERLEME', style: AppTextStyles.cardCaption),
                  Text(
                    '$currentWeek / $durationWeeks hafta',
                    style: AppTextStyles.tagText.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  minHeight: 6,
                  backgroundColor: AppColors.glassWhite,
                  color: (currentWeek == durationWeeks) ? AppColors.warning : AppColors.primary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (!isTemplate && !isAssigned)
                        _buildInfoBadge(
                          program.isPersonal
                              ? Icons.person_rounded
                              : Icons.fitness_center_rounded,
                          program.isPersonal
                              ? 'Kişisel Program'
                              : 'Antrenör Programı',
                        ),
                      if (isAssigned)
                        _buildInfoBadge(Icons.person_pin_rounded, program.clientName),
                    ],
                  ),
                ),
                if (isTemplate) _buildAssignButton(context, program),
              ],
            ),
            if (!_isCoach && !isTemplate) ...[
              if (program.isOrphaned) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'ANTRENÖR BAĞI KOPTU',
                            style: AppTextStyles.bodyText.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '"${program.name}" programının antrenörle bağı koptu (silindi). Kişisel programın olarak saklamak ister misin?',
                        style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: AppColors.textSecondary),
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
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                              ),
                              child: Text('Sakla (Kişisel Yap)', style: AppTextStyles.buttonText.copyWith(color: Colors.black, fontSize: 11)),
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
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                              ),
                              child: Text('Sil', style: AppTextStyles.buttonText.copyWith(color: AppColors.error, fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else if (!program.isActive) ...[
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: () {
                    context.read<TrainingBloc>().add(ActivateProgram(program.id));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 38),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      side: const BorderSide(color: AppColors.primary, width: 0.5),
                    ),
                  ),
                  child: Text(
                    'AKTİF ET',
                    style: AppTextStyles.tagText.copyWith(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssignButton(BuildContext context, TrainingBlock template) {
    return ElevatedButton(
      onPressed: () => _showAssignDialog(context, template),
      style: ElevatedButton.styleFrom(
        minimumSize: Size.zero,
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        foregroundColor: AppColors.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      child: Text('ATA', style: AppTextStyles.tagText.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  void _showAssignDialog(BuildContext context, TrainingBlock template) {
    if (widget.targetStudentId != null) {
      context.read<SocialBloc>().add(LoadMyClientsRequested());
      final socialState = context.read<SocialBloc>().state;
      if (socialState is SocialClientsLoaded) {
        final client = socialState.clients.firstWhere(
          (c) => c.userId == widget.targetStudentId,
          orElse: () => DiscoveryUserModel(
            userId: widget.targetStudentId!,
            fullName: 'Sporcu',
            role: UserRole.CLIENT,
          ),
        );
        _confirmAssignment(context, client, template);
      } else {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (loadingContext) {
            return BlocListener<SocialBloc, SocialState>(
              listener: (ctx, state) {
                if (state is SocialClientsLoaded) {
                  Navigator.pop(loadingContext);
                  final client = state.clients.firstWhere(
                    (c) => c.userId == widget.targetStudentId,
                    orElse: () => DiscoveryUserModel(
                      userId: widget.targetStudentId!,
                      fullName: 'Sporcu',
                      role: UserRole.CLIENT,
                    ),
                  );
                  _confirmAssignment(context, client, template);
                } else if (state is SocialError) {
                  Navigator.pop(loadingContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: AlertDialog(
                backgroundColor: AppColors.surface,
                content: Row(
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Text('Sporcu bilgileri yükleniyor...', style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            );
          },
        );
      }
      return;
    }

    context.read<SocialBloc>().add(LoadMyClientsRequested());

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return GlassContainer(
          borderRadius: AppRadius.xl,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Programı Ata',
                style: AppTextStyles.heroTitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Lütfen programı atamak istediğiniz sporcuyu seçin.',
                style: AppTextStyles.bodyText,
              ),
              const SizedBox(height: AppSpacing.lg),
              Flexible(
                child: BlocBuilder<SocialBloc, SocialState>(
                  builder: (socialContext, state) {
                    if (state is SocialLoading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }
                    if (state is SocialClientsLoaded) {
                      if (state.clients.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                          child: Text(
                            'Aktif öğrenciniz bulunmuyor.',
                            style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.clients.length,
                        itemBuilder: (ctx, index) {
                          final client = state.clients[index];
                          return ListTile(
                            onTap: () {
                              Navigator.pop(modalContext);
                              _confirmAssignment(context, client, template);
                            },
                            leading: NetworkAvatar(
                              imageUrl: client.profilePhotoUrl,
                              size: 44,
                            ),
                            title: Text(
                              client.fullName ?? 'İsimsiz Sporcu',
                              style: AppTextStyles.listTitle,
                            ),
                            subtitle: Text(
                              'Aktif Öğrenci',
                              style: AppTextStyles.cardCaption,
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textMuted,
                            ),
                          );
                        },
                      );
                    }
                    return const SizedBox(height: AppSpacing.xl);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  void _confirmAssignment(
    BuildContext context,
    DiscoveryUserModel client,
    TrainingBlock template,
  ) {
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              'Program Atama',
              style: AppTextStyles.heroTitle.copyWith(fontSize: 20),
            ),
            content: Text(
              '"${template.name}" programını ${client.fullName} isimli sporcuya atamak istediğinize emin misiniz?',
              style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'İPTAL',
                  style: AppTextStyles.buttonText.copyWith(color: AppColors.textMuted),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<TrainingBloc>().add(
                    AssignTemplateToClient(
                      templateId: template.id,
                      clientId: client.userId,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                child: Text(
                  'EVET, ATA',
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.background,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    TrainingBlock program, {
    bool isTemplate = false,
    bool isAssigned = false,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Programı Sil',
          style: AppTextStyles.heroTitle.copyWith(fontSize: 20),
        ),
        content: Text(
          '${program.name} programını silmek istediğinize emin misiniz?',
          style: AppTextStyles.bodyText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'VAZGEÇ',
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (isTemplate) {
                context
                    .read<TrainingBloc>()
                    .add(DeleteCoachTemplate(program.id));
              } else if (isAssigned) {
                context.read<TrainingBloc>().add(DeleteProgram(program.id));
                context.read<TrainingBloc>().add(const LoadCoachAssignedPrograms());
              } else {
                context.read<TrainingBloc>().add(DeleteProgram(program.id));
              }
              Navigator.pop(ctx);
            },
            child: Text(
              'SİL',
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            text,
            style: AppTextStyles.tagText.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      bool isPersonal, bool isTemplateList, bool isAssignedList) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isTemplateList || isAssignedList
                ? Icons.assignment_outlined
                : Icons.fitness_center_rounded,
            size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            isTemplateList
                ? 'Henüz şablonun yok.'
                : (isAssignedList
                    ? 'Henüz atanan program yok.'
                    : (isPersonal
                        ? 'Kişisel programın yok.'
                        : 'Henüz atama yapılmadı.')),
            style: AppTextStyles.emptyTitle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isTemplateList
                ? 'Sık kullandığın antrenmanları şablon olarak kaydedebilirsin.'
                : (isAssignedList
                    ? 'Sporcularına program atadığında burada görebilirsin.'
                    : (isPersonal
                        ? 'Hemen yeni bir program oluşturmaya ne dersin?'
                        : 'Antrenörün program atadığında burada görünecek.')),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 64,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(error, style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary)),
          TextButton(
            onPressed: () => context.read<TrainingBloc>().add(LoadMyPrograms()),
            child: Text('Tekrar Dene', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.cardValue.copyWith(fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: AppTextStyles.cardCaption.copyWith(fontSize: 9),
        ),
      ],
    );
  }
}

class _MuscleChip extends StatelessWidget {
  final MuscleGroup muscle;

  const _MuscleChip({required this.muscle});

  @override
  Widget build(BuildContext context) {
    final baseColor = muscle.color;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: baseColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: baseColor,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            muscle.turkishName,
            style: AppTextStyles.tagText.copyWith(
              color: baseColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
