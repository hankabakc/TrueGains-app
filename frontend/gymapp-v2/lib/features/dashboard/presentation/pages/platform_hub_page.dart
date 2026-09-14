import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:gymapp_v2/core/widgets/hub_action_card.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';

class PlatformHubPage extends StatelessWidget {
  final UserRole role;

  const PlatformHubPage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              centerTitle: false,
              title: Text('Platform', style: AppTextStyles.pageTitle),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.xs),
                const SectionHeader(
                  label: 'AKADEMİK & SOSYAL',
                  icon: Icons.groups_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.5,
                  children: [
                    if (role == UserRole.COACH)
                      HubActionCard(
                        title: 'İstekler',
                        icon: Icons.notifications_active_rounded,
                        onTap: () => context.push('/requests'),
                      ),
                    HubActionCard(
                      title: 'Programlar',
                      icon: Icons.assignment_rounded,
                      onTap: () => context.push('/training'),
                    ),
                    HubActionCard(
                      title: 'Kütüphane',
                      icon: Icons.menu_book_rounded,
                      onTap: () => context.push('/exercises'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(
                  label: 'GELİŞİM & ANALİZ',
                  icon: Icons.insights_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.5,
                  children: [
                    HubActionCard(
                      title: 'Ölçümler',
                      icon: Icons.straighten_rounded,
                      onTap:
                          () => context.push(
                            role == UserRole.COACH
                                ? '/shared-measurements'
                                : '/measurements',
                          ),
                    ),
                    HubActionCard(
                      title: 'Diyet',
                      icon: Icons.restaurant_rounded,
                      onTap:
                          () => context.push(
                            role == UserRole.COACH
                                ? '/coach-diet-templates'
                                : '/nutrition',
                          ),
                    ),
                    HubActionCard(
                      title: 'Su Takibi',
                      icon: Icons.local_drink_rounded,
                      onTap:
                          () => context.push(
                            role == UserRole.COACH
                                ? '/coach-water-tracking'
                                : '/water-tracking',
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(
                  label: 'FİNANS & SİSTEM',
                  icon: Icons.account_balance_wallet_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.5,
                  children: [
                    HubActionCard(
                      title: 'Ödemeler',
                      icon: Icons.payments_rounded,
                      onTap: () {
                        if (role == UserRole.CLIENT) {
                          context.push('/my-subscription');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Koç ödeme ve kazanç ekranı yakında eklenecektir.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppLayout.bottomNavClearance),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
