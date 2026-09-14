import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/pressable_scale.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';

class DietHubPage extends StatelessWidget {
  const DietHubPage({super.key});

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Beslenme Yönetimi',
          style: AppTextStyles.pageTitle,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'Programlarını, girdilerini ve analizini tek yerden yönet.',
                style: AppTextStyles.bodyText.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _HubCard(
                compact: false,
                isHero: true,
                title: 'Beslenme Girdisi',
                subtitle: 'Günlük öğünlerini işaretle ve takip et.',
                icon: Icons.restaurant_menu_rounded,
                onTap: () => context.push('/nutrition/entry'),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(
                label: 'PROGRAMLAR',
                icon: Icons.assignment_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _HubCard(
                      compact: true,
                      title: 'Antrenörümden Gelenler',
                      subtitle: 'Koçunun özel hazırladığı listeler.',
                      icon: Icons.assignment_ind_rounded,
                      onTap: () => context.push('/nutrition/list/COACH'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _HubCard(
                      compact: true,
                      title: 'Benim Planlarım',
                      subtitle: 'Kendi oluşturduğun diyet listeleri.',
                      icon: Icons.list_alt_rounded,
                      onTap: () => context.push('/nutrition/list/CLIENT'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _HubCard(
                compact: false,
                title: 'Analiz ve Raporlar',
                subtitle: 'Kalori ve makro gelişimini detaylı incele.',
                icon: Icons.analytics_rounded,
                onTap: () => context.push('/nutrition/analytics'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final bool compact;
  final bool isHero;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HubCard({
    required this.compact,
    this.isHero = false,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return PressableScale(
        onTap: onTap,
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderRadius: AppRadius.lg,
          shadow: AppElevation.softGlow(AppColors.primary),
          border: Border.all(color: AppColors.glassBorder),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTextStyles.listTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                style: AppTextStyles.listSubtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return PressableScale(
      onTap: onTap,
      child: GlassContainer(
        padding: isHero ? const EdgeInsets.all(AppSpacing.xl) : const EdgeInsets.all(AppSpacing.lg),
        borderRadius: AppRadius.lg,
        shadow: AppElevation.softGlow(AppColors.primary),
        overlayGradient: isHero ? AppColors.heroGradient : null,
        border: Border.all(color: AppColors.glassBorder),
        child: Row(
          children: [
            Container(
              padding: isHero ? const EdgeInsets.all(AppSpacing.lg) : const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: AppColors.primary, size: isHero ? 32 : 28),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.listTitle,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: AppTextStyles.listSubtitle,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textMuted,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
