import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/empty_state.dart';
import 'package:gymapp_v2/core/widgets/list_skeleton.dart';
import 'package:gymapp_v2/core/widgets/network_avatar.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:gymapp_v2/features/nutrition/presentation/widgets/diet_program_card.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/coach_diet_templates/coach_diet_templates_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/coach_diet_templates/coach_diet_templates_state.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/social_bloc.dart';
import 'package:gymapp_v2/features/social/data/models/discovery_user_model.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/widgets/pressable_scale.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_assignment_model.dart';

class CoachDietTemplatesPage extends StatefulWidget {
  const CoachDietTemplatesPage({super.key});

  @override
  State<CoachDietTemplatesPage> createState() => _CoachDietTemplatesPageState();
}

class _CoachDietTemplatesPageState extends State<CoachDietTemplatesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CoachDietTemplatesCubit>(
      create: (context) => sl<CoachDietTemplatesCubit>()..loadTemplatesWithAssignments(),
      child: _CoachDietTemplatesView(tabController: _tabController),
    );
  }
}

class _CoachDietTemplatesView extends StatelessWidget {
  final TabController tabController;
  const _CoachDietTemplatesView({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CoachDietTemplatesCubit, CoachDietTemplatesState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Diyet Şablon Merkezi',
              style: AppTextStyles.heroTitle.copyWith(fontSize: 22, color: AppColors.textPrimary),
            ),
            bottom: TabBar(
              controller: tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              dividerColor: Colors.transparent,
              indicatorWeight: 3,
              labelStyle: AppTextStyles.buttonText.copyWith(fontSize: 13),
              tabs: const [
                Tab(text: 'Programlar'),
                Tab(text: 'Atanan Kişiler'),
              ],
            ),
          ),
          body: Stack(
            children: [
              _buildBackgroundGlow(),
              TabBarView(
                controller: tabController,
                children: [
                  _DietProgramsTabView(state: state),
                  _DietAssignmentsTabView(state: state),
                ],
              ),
              _buildLoadingOverlay(),
            ],
          ),
          floatingActionButton: tabController.index == 0
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: () => _showCreateTemplateDialog(context),
                    backgroundColor: AppColors.primary,
                    icon: const Icon(Icons.add_rounded, color: AppColors.background),
                    label: Text('Yeni Şablon',
                        style: AppTextStyles.buttonText.copyWith(color: AppColors.background)),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBackgroundGlow() {
    return Positioned(
      top: -50,
      right: -50,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return BlocBuilder<CoachDietTemplatesCubit, CoachDietTemplatesState>(
      builder: (context, state) {
        if (!state.isProcessing) return const SizedBox.shrink();
        return Container(
          color: Colors.black54,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      },
    );
  }

  void _showCreateTemplateDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Yeni Diyet Şablonu',
            style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Şablon Adı (Örn: Definasyon Başlangıç)',
            hintStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.glassBorder)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('İPTAL', style: AppTextStyles.buttonText.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                context
                    .read<CoachDietTemplatesCubit>()
                    .createTemplate(nameController.text);
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            child: Text('OLUŞTUR',
                style: AppTextStyles.buttonText.copyWith(color: AppColors.background)),
          ),
        ],
      ),
    );
  }
}

class _DietProgramsTabView extends StatelessWidget {
  final CoachDietTemplatesState state;
  const _DietProgramsTabView({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == CoachDietTemplatesStatus.loading &&
        state.templates.isEmpty) {
      return const ListSkeleton();
    }

    if (state.templates.isEmpty) {
      return const EmptyState(
        icon: Icons.restaurant_menu_rounded,
        title: 'Henüz diyet şablonu oluşturmadınız.',
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      itemCount: state.templates.length,
      itemBuilder: (context, index) {
        final template = state.templates[index];
        return DietProgramCard(
          program: template,
          subtitle: '${template.dietDays.length} Günlük Program',
          isActive: false,
          onTap: () => context.push('/nutrition/dashboard/${template.id}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: () => _confirmDelete(context, template),
              tooltip: 'Sil',
            ),
            const SizedBox(width: AppSpacing.xs),
            ElevatedButton(
              onPressed: () => _showAssignDialog(context, template),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                foregroundColor: AppColors.primary,
                elevation: 0,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
              ),
              child: Text('ATA', style: AppTextStyles.buttonText.copyWith(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, DietProgramModel template) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Şablonu Sil', style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary)),
        content: Text('"${template.name}" şablonunu silmek istediğinize emin misiniz?',
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('İPTAL', style: AppTextStyles.buttonText.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CoachDietTemplatesCubit>().deleteTemplate(template.id);
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            child: Text('SİL', style: AppTextStyles.buttonText.copyWith(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context, DietProgramModel template) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      isScrollControlled: true,
      builder: (modalContext) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<CoachDietTemplatesCubit>()),
            BlocProvider.value(value: context.read<SocialBloc>()),
          ],
          child: _AssignmentsModalContent(template: template),
        );
      },
    );
  }
}

class _DietAssignmentsTabView extends StatelessWidget {
  final CoachDietTemplatesState state;
  const _DietAssignmentsTabView({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == CoachDietTemplatesStatus.loading &&
        state.allAssignments.isEmpty) {
      return const ListSkeleton();
    }

    if (state.allAssignments.isEmpty) {
      return const EmptyState(
        icon: Icons.restaurant_menu_rounded,
        title: 'Henüz hiçbir sporcuya şablon atamadınız.',
      );
    }

    final Map<String, List<DietAssignmentModel>> groupedAssignments = {};
    for (final assignment in state.allAssignments) {
      final progName = assignment.dietProgram.name;
      if (!groupedAssignments.containsKey(progName)) {
        groupedAssignments[progName] = [];
      }
      groupedAssignments[progName]!.add(assignment);
    }

    final programNames = groupedAssignments.keys.toList();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      itemCount: programNames.length,
      itemBuilder: (context, index) {
        final progName = programNames[index];
        final assignments = groupedAssignments[progName]!;

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.folder_open_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      progName.toUpperCase(),
                      style: AppTextStyles.sectionLabel.copyWith(
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        '${assignments.length} Sporcu',
                        style: AppTextStyles.tagText.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GlassContainer(
                borderRadius: AppRadius.xl,
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Column(
                  children: List.generate(assignments.length, (idx) {
                    final assignment = assignments[idx];
                    final dateStr = assignment.dietProgram.startDate != null
                        ? _formatDateTimeStr(assignment.dietProgram.startDate!)
                        : 'Tarih yok';

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                          leading: NetworkAvatar(
                            imageUrl: assignment.profileImageUrl,
                            fallbackText: assignment.fullName,
                            size: 40,
                          ),
                          title: Text(
                            assignment.fullName,
                            style: AppTextStyles.listTitle.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Atanma: $dateStr',
                            style: AppTextStyles.cardCaption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                            onPressed: () => _confirmUnassign(context, assignment),
                          ),
                        ),
                        if (idx < assignments.length - 1)
                          const Divider(color: AppColors.glassBorder, height: 1, indent: 16, endIndent: 16),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTimeStr(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (e) {
      return isoString;
    }
  }

  void _confirmUnassign(BuildContext context, DietAssignmentModel assignment) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Atamayı Kaldır', style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary)),
        content: Text(
          '${assignment.fullName} isimli sporcudan bu program atamasını kaldırmak istediğinize emin misiniz? (Sporcunun kopyası silinecektir)',
          style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('İPTAL', style: AppTextStyles.buttonText.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final cubit = context.read<CoachDietTemplatesCubit>();
              final success = await cubit.deleteAssignment(assignment.assignmentId);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${assignment.fullName} için program ataması kaldırıldı.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            child: Text('KALDIR',
                style: AppTextStyles.buttonText.copyWith(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _AssignmentsModalContent extends StatefulWidget {
  final DietProgramModel template;
  const _AssignmentsModalContent({required this.template});

  @override
  State<_AssignmentsModalContent> createState() => _AssignmentsModalContentState();
}

class _AssignmentsModalContentState extends State<_AssignmentsModalContent> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    context.read<SocialBloc>().add(LoadMyClientsRequested());
    context.read<CoachDietTemplatesCubit>().loadAssignments(widget.template.id);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: BlocBuilder<CoachDietTemplatesCubit, CoachDietTemplatesState>(
            builder: (context, templatesState) {
              return BlocBuilder<SocialBloc, SocialState>(
                builder: (context, socialState) {
                  if (socialState is SocialLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );
                  }

                  if (socialState is SocialClientsLoaded) {
                    final allClients = socialState.clients;
                    final assignedList = templatesState.templateAssignments[widget.template.id] ?? [];
                    final assignedStudentIds = assignedList.map((a) => a.studentId).toSet();
                    final unassignedClients = allClients.where((c) => !assignedStudentIds.contains(c.userId)).toList();

                    final filteredClients = unassignedClients.where((c) {
                      return (c.fullName ?? '').toLowerCase().contains(_query.trim().toLowerCase());
                    }).toList();

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.glassBorder,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          '"${widget.template.name}" Şablonunu Ata',
                          style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Atamak istediğin sporcuyu seç',
                          style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: _searchController,
                          style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Sporcu ara...',
                            hintStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                            filled: true,
                            fillColor: AppColors.glassWhite,
                            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.glassBorder)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.primary)),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _query = val;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            const SectionHeader(label: 'SPORCULAR'),
                            const Spacer(),
                            Text(
                              '${filteredClients.length}',
                              style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (unassignedClients.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Atama yapılabilecek yeni sporcu bulunmuyor.',
                              style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 13),
                            ),
                          )
                        else if (filteredClients.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 36),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Aramayla eşleşen sporcu yok.',
                                    style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredClients.length,
                              itemBuilder: (context, index) {
                                final client = filteredClients[index];
                                return _buildClientTile(context, client);
                              },
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    );
                  }

                  if (socialState is SocialError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          socialState.message,
                          style: AppTextStyles.bodyText.copyWith(color: AppColors.error, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildClientTile(BuildContext context, DiscoveryUserModel client) {
    return PressableScale(
      onTap: () => _confirmAssign(context, client),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.glassWhite,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            NetworkAvatar(
              imageUrl: client.profilePhotoUrl,
              fallbackText: client.fullName,
              size: 40,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.fullName ?? 'İsimsiz Sporcu',
                    style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary, fontSize: 14),
                  ),
                  Text(
                    'Aktif Öğrenci',
                    style: AppTextStyles.cardCaption.copyWith(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.glassWhite,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAssign(BuildContext context, DiscoveryUserModel client) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Şablon Ata', style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary)),
        content: Text(
          '"${widget.template.name}" şablonunu ${client.fullName} isimli sporcuya atamak istediğinize emin misiniz?',
          style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('İPTAL', style: AppTextStyles.buttonText.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final cubit = context.read<CoachDietTemplatesCubit>();
              final success = await cubit.assignTemplate(widget.template.id, client.userId);
              if (success) {
                cubit.loadAssignments(widget.template.id);
                cubit.loadAllAssignments();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${client.fullName} için program başarıyla atandı.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            child: Text('ATA', style: AppTextStyles.buttonText.copyWith(color: AppColors.background)),
          ),
        ],
      ),
    );
  }
}
