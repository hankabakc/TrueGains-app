import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/empty_state.dart';
import 'package:gymapp_v2/core/widgets/list_skeleton.dart';
import 'package:gymapp_v2/features/finance/models/finance_models.dart';
import 'package:gymapp_v2/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:gymapp_v2/features/finance/ui/widgets/package_features_list.dart';

/// Sporcu Paket Seçim Sayfası - Koça ait veya global paketleri listeler.
class PackageSelectionPage extends StatefulWidget {
  final int coachId;

  const PackageSelectionPage({super.key, required this.coachId});

  @override
  State<PackageSelectionPage> createState() => _PackageSelectionPageState();
}

class _PackageSelectionPageState extends State<PackageSelectionPage> {
  @override
  void initState() {
    super.initState();
    context.read<FinanceBloc>().add(LoadPackages(widget.coachId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'PAKET SEÇ',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: BlocListener<FinanceBloc, FinanceState>(
        listenWhen: (p, c) => p.status != c.status && c.status == FinanceStatus.cartUpdated,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.successMessage ?? 'Paket sepetinize eklendi.'),
            backgroundColor: AppColors.success,
          ));
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.push('/my-subscription');
            }
          });
        },
        child: BlocBuilder<FinanceBloc, FinanceState>(
          builder: (context, state) {
            if (state.status == FinanceStatus.loading && state.packages.isEmpty) {
              return const ListSkeleton(rowHeight: 96);
            }

            if (state.packages.isEmpty) {
              return const EmptyState(
                icon: Icons.shopping_cart_outlined,
                title: 'Henüz mevcut paket bulunmamaktadır.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: state.packages.length,
              itemBuilder: (context, index) {
                return _buildPackageCard(state.packages[index], index);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPackageCard(SubscriptionPackageModel pkg, int index) {
    final isPopular = index == 1;
    final gradientColors = isPopular
        ? [AppColors.primary, AppColors.primaryDark]
        : [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPopular) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '⭐ EN POPÜLER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.11,
                      height: MediaQuery.of(context).size.width * 0.11,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isPopular ? Icons.diamond_rounded : Icons.workspace_premium_rounded,
                        color: isPopular ? Colors.white : AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        pkg.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                if (pkg.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    pkg.description!,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: AppColors.textMuted, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${pkg.durationDays} Gün',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${pkg.price.toStringAsFixed(0)} ₺',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                if (pkg.features != null && pkg.features!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  PackageFeaturesList(features: pkg.features),
                ],
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<FinanceBloc>().add(AddPackageToCart(pkg.id));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: Text(
                      'SATIN AL',
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
