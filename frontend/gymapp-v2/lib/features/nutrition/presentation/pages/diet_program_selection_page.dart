import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/list_skeleton.dart';
import 'package:gymapp_v2/core/widgets/pressable_scale.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_program_model.dart';
import 'package:gymapp_v2/features/nutrition/data/models/diet_source.dart';
import 'package:gymapp_v2/features/nutrition/presentation/widgets/diet_program_card.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_program_selection/diet_program_selection_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/diet_program_selection/diet_program_selection_state.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';

class DietProgramSelectionPage extends StatelessWidget {
  final DietSource sourceFilter;
  const DietProgramSelectionPage({super.key, required this.sourceFilter});

  @override
  Widget build(BuildContext context) {
    final title =
        sourceFilter == DietSource.coach
            ? 'Antrenör Programları'
            : 'Benim Programlarım';

    return BlocProvider(
      create:
          (context) =>
              sl<DietProgramSelectionCubit>()
                ..loadPrograms(sourceFilter),
      child: BlocConsumer<DietProgramSelectionCubit, DietProgramSelectionState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          final cubit = context.read<DietProgramSelectionCubit>();

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => context.pop(),
              ),
              title: Text(
                title,
                style: AppTextStyles.heroTitle.copyWith(
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            body:
                state.status == DietProgramSelectionStatus.loading
                    ? const ListSkeleton()
                    : Column(
                      children: [
                        if (sourceFilter == DietSource.client) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _buildFixedCreateHeader(context, cubit),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        if (state.programs.isEmpty)
                          Expanded(child: _buildEmptyState())
                        else
                          Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              itemCount: state.programs.length,
                              itemBuilder: (context, index) {
                                final program = state.programs[index];
                                return DietProgramCard(
                                  program: program,
                                  subtitle: program.description ?? 'Beslenme Programı',
                                  isActive: program.isMain,
                                  onTap: () => context.push('/nutrition/dashboard/${program.id}'),
                                  onKeepOrphan: () => cubit.approveOrphaned(program.id, true, sourceFilter),
                                  onDiscardOrphan: () => cubit.approveOrphaned(program.id, false, sourceFilter),
                                  actions: [
                                    if (sourceFilter == DietSource.client)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppColors.error,
                                        ),
                                        onPressed: () => _showDeleteDialog(context, cubit, program),
                                      ),
                                    if (!program.isMain)
                                      ElevatedButton(
                                        onPressed: () => cubit.activateProgram(program.id, sourceFilter),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                          foregroundColor: AppColors.primary,
                                          elevation: 0,
                                          minimumSize: Size.zero,
                                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                                        ),
                                        child: Text(
                                          'AKTİF SEÇ',
                                          style: AppTextStyles.buttonText.copyWith(color: AppColors.primary),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                      ],
                    ),
          );
        },
      ),
    );
  }

  Widget _buildFixedCreateHeader(
    BuildContext context,
    DietProgramSelectionCubit cubit,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: PressableScale(
        onTap: () => _showCreateDialog(context, cubit, sourceFilter),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YENİ PROGRAM',
                      style: AppTextStyles.buttonText.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Kendi diyetini tasarla',
                      style: AppTextStyles.cardCaption.copyWith(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_rounded, color: AppColors.textMuted, size: 80),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Henüz bir program yok',
            style: AppTextStyles.bodyText.copyWith(
              fontSize: 16,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(
    BuildContext context,
    DietProgramSelectionCubit cubit,
    DietSource sourceFilter,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _CreateProgramDialog(cubit: cubit, sourceFilter: sourceFilter),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    DietProgramSelectionCubit cubit,
    DietProgramModel program,
  ) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            title: Text(
              'Programı Sil',
              style: AppTextStyles.listTitle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            content: Text(
              '${program.name} programı silinecek. Bu işlem geri alınamaz.',
              style: AppTextStyles.bodyText.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'İPTAL',
                  style: AppTextStyles.buttonText.copyWith(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  cubit.deleteProgram(program.id);
                },
                child: Text(
                  'SİL',
                  style: AppTextStyles.buttonText.copyWith(
                    fontSize: 14,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

class _CreateProgramDialog extends StatefulWidget {
  final DietProgramSelectionCubit cubit;
  final DietSource sourceFilter;
  const _CreateProgramDialog({required this.cubit, required this.sourceFilter});

  @override
  State<_CreateProgramDialog> createState() => _CreateProgramDialogState();
}

class _CreateProgramDialogState extends State<_CreateProgramDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      title: Text(
        'Yeni Program Oluştur',
        style: AppTextStyles.listTitle.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: AppTextStyles.bodyText.copyWith(
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Program Adı (Örn: Definasyon)',
          hintStyle: AppTextStyles.bodyText.copyWith(
            color: AppColors.textMuted,
          ),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.glassBorder)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'İPTAL',
            style: AppTextStyles.buttonText.copyWith(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            final name = _controller.text.trim();
            if (name.isNotEmpty) {
              Navigator.pop(context);
              final newProg = await widget.cubit.createProgram(name, widget.sourceFilter);
              if (newProg != null && context.mounted) {
                context.push('/nutrition/diet-goals', extra: newProg);
              }
            }
          },
          child: Text(
            'OLUŞTUR',
            style: AppTextStyles.buttonText.copyWith(
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

