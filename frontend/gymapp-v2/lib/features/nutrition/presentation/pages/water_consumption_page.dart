import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:gymapp_v2/core/widgets/pressable_scale.dart';
import '../bloc/water/water_bloc.dart';
import '../../data/models/water_intake_model.dart';
import 'water_analysis_page.dart';
import 'dart:math' as math;

class WaterConsumptionPage extends StatelessWidget {
  const WaterConsumptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WaterConsumptionView();
  }
}

class WaterConsumptionView extends StatefulWidget {
  const WaterConsumptionView({super.key});

  @override
  State<WaterConsumptionView> createState() => _WaterConsumptionViewState();
}

class _WaterConsumptionViewState extends State<WaterConsumptionView>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WaterBloc, WaterState>(
      listener: (context, state) {
        if (state is WaterError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: BlocBuilder<WaterBloc, WaterState>(
        builder: (context, state) {
          if (state is WaterLoading && state is! WaterLoaded) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          if (state is WaterLoaded) {
            final summary = state.summary;
            double progress = (summary.totalIntakeMl / summary.targetMl).clamp(
              0.0,
              1.0,
            );

            return Scaffold(
              backgroundColor: AppColors.background,
              body: CustomScrollView(
                slivers: [
                  _buildAppBar(context),
                  SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildProgressCard(
                          summary.totalIntakeMl,
                          summary.targetMl,
                          progress,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildTargetEditButton(context, summary.targetMl),
                        const SizedBox(height: AppSpacing.xl),

                        _buildAnalysisButton(context, state),

                        const SizedBox(height: AppSpacing.xl),
                        const SectionHeader(label: 'HIZLI EKLE'),
                        const SizedBox(height: AppSpacing.md),
                        _buildQuickGlassesGrid(context),

                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SectionHeader(label: 'ÖZEL BARDAKLARIN'),
                            IconButton(
                              onPressed:
                                  () => _showAddCustomGlassDialog(context),
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildCustomGlassesGrid(context, summary.customGlasses),
                        const SizedBox(height: AppLayout.bottomNavClearance),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          }

          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 80,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'SU TAKİBİ',
        style: AppTextStyles.greeting.copyWith(
          color: AppColors.textPrimary,
          fontSize: 16,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildProgressCard(int current, int target, double progress) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.xl,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipOval(
                      child: AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: WaterWavePainter(
                              waveAnimation: _waveController.value,
                              progress: progress,
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          );
                        },
                      ),
                    ),
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: AppColors.glassWhite,
                      color: AppColors.primary,
                      strokeCap: StrokeCap.round,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$current',
                    style: AppTextStyles.heroDisplay.copyWith(
                      fontSize: 48,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'ml / $target ml',
                    style: AppTextStyles.bodyText.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            progress >= 1.0
                ? 'Harika! Hedefine ulaştın! 💧'
                : 'Hidrasyonu korumak için su içmeyi unutma.',
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTargetEditButton(BuildContext context, int currentTarget) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _showTargetDialog(context, currentTarget),
        icon: const Icon(Icons.edit_rounded, size: 14, color: AppColors.textMuted),
        label: Text(
          'HEDEFİ GÜNCELLE',
          style: AppTextStyles.buttonText.copyWith(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisButton(BuildContext context, WaterLoaded state) {
    return PressableScale(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => WaterAnalysisPage(state: state),
            ),
          ),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        borderRadius: AppRadius.md,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'GELİŞİM VE ANALİZ',
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickGlassesGrid(BuildContext context) {
    final sizes = [150, 200, 250, 300, 400, 500];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.1,
      ),
      itemCount: sizes.length,
      itemBuilder:
          (ctx, index) =>
              _buildGlassItem(context, sizes[index], Icons.local_drink_rounded),
    );
  }

  Widget _buildGlassItem(BuildContext context, int ml, IconData icon) {
    return PressableScale(
      onTap: () => context.read<WaterBloc>().add(AddWaterIntake(ml)),
      child: GlassContainer(
        borderRadius: AppRadius.md,
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              '$ml ml',
              style: AppTextStyles.listTitle.copyWith(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomGlassesGrid(
    BuildContext context,
    List<CustomGlassModel> customGlasses,
  ) {
    if (customGlasses.isEmpty) return const SizedBox();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.1,
      ),
      itemCount: customGlasses.length,
      itemBuilder: (ctx, index) {
        final glass = customGlasses[index];
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _buildGlassItem(context, glass.sizeMl, Icons.wine_bar_rounded),
            Positioned(
              top: -8,
              right: -8,
              child: GestureDetector(
                onTap:
                    () => context.read<WaterBloc>().add(
                      DeleteCustomGlass(glass.id),
                    ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, size: 12, color: AppColors.textPrimary),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTargetDialog(BuildContext context, int currentTarget) {
    final controller = TextEditingController(text: currentTarget.toString());
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            title: Text(
              'Hedef Güncelle',
              style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary),
            ),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Yeni Hedef (ml)',
                labelStyle: AppTextStyles.cardCaption.copyWith(color: AppColors.textSecondary),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('İptal', style: AppTextStyles.buttonText.copyWith(color: AppColors.textMuted)),
              ),
              PremiumButton(
                text: 'Güncelle',
                onPressed: () {
                  final val = int.tryParse(controller.text);
                  if (val != null) {
                    context.read<WaterBloc>().add(UpdateWaterTarget(val));
                  }
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
    );
  }

  void _showAddCustomGlassDialog(BuildContext context) {
    final state = context.read<WaterBloc>().state;
    if (state is WaterLoaded && state.summary.customGlasses.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimum 3 adet özel bardak ekleyebilirsiniz.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final sizeController = TextEditingController();
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            title: Text(
              'Özel Bardak Ekle',
              style: AppTextStyles.listTitle.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: sizeController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Boyut (ml)',
                labelStyle: AppTextStyles.cardCaption.copyWith(color: AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: Text(
                        'İPTAL',
                        style: AppTextStyles.buttonText.copyWith(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PremiumButton(
                      text: 'EKLE',
                      onPressed: () {
                        final size = int.tryParse(sizeController.text);
                        if (size != null) {
                          context.read<WaterBloc>().add(
                            AddCustomGlass('Özel', size),
                          );
                        }
                        Navigator.pop(ctx);
                      },
                      height: 44,
                    ),
                  ),
                ],
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          ),
    );
  }
}

class WaterWavePainter extends CustomPainter {
  final double waveAnimation;
  final double progress;
  final Color color;

  WaterWavePainter({
    required this.waveAnimation,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()..color = color;
    final path = Path();
    final yOffset = size.height * (1 - progress);
    path.moveTo(0, yOffset);
    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        yOffset +
            math.sin(
                  (i / size.width * 2 * math.pi) +
                      (waveAnimation * 2 * math.pi),
                ) *
                8,
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaterWavePainter oldDelegate) => true;
}
