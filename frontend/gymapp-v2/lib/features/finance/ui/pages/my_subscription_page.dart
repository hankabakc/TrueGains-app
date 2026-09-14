import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/section_header.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/core/widgets/empty_state.dart';
import 'package:gymapp_v2/core/widgets/list_skeleton.dart';
import 'package:gymapp_v2/features/finance/models/finance_models.dart';
import 'package:gymapp_v2/features/finance/presentation/bloc/finance_bloc.dart';

/// Sporcu Ödemeler ve Sepet Sayfası.
/// Aktif aboneliği, sepetindeki ödeme bekleyen paketleri ve geçmiş ödemelerini gösterir.
class MySubscriptionPage extends StatefulWidget {
  const MySubscriptionPage({super.key});

  @override
  State<MySubscriptionPage> createState() => _MySubscriptionPageState();
}

class _MySubscriptionPageState extends State<MySubscriptionPage> {
  @override
  void initState() {
    super.initState();
    context.read<FinanceBloc>().add(LoadMySubscription());
    context.read<FinanceBloc>().add(LoadMyTransactions());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            'ÖDEMELERİM & SEPETİM',
            style: AppTextStyles.greeting.copyWith(letterSpacing: 1.2, fontSize: 16, color: AppColors.textPrimary),
          ),
          centerTitle: true,
          bottom: TabBar(
            dividerColor: Colors.transparent,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: AppTextStyles.buttonText.copyWith(fontSize: 13),
            tabs: const [
              Tab(text: 'ABONELİK & SEPET'),
              Tab(text: 'ÖDEME GEÇMİŞİ'),
            ],
          ),
        ),
        body: BlocListener<FinanceBloc, FinanceState>(
          listener: (context, state) {
            if (state.status == FinanceStatus.cartUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage ?? 'Sepet güncellendi.'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: BlocBuilder<FinanceBloc, FinanceState>(
            builder: (context, state) {
              if (state.status == FinanceStatus.loading && state.transactions.isEmpty) {
                return const ListSkeleton();
              }

              final pending = state.transactions.where((tx) => tx.status == 'PENDING').toList();
              final history = state.transactions.where((tx) => tx.status != 'PENDING').toList();

              return TabBarView(
                children: [
                  // TAB 1: ABONELİK & SEPET
                  RefreshIndicator(
                    onRefresh: () async {
                      context.read<FinanceBloc>().add(LoadMySubscription());
                      context.read<FinanceBloc>().add(LoadMyTransactions());
                    },
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(label: 'AKTİF ABONELİK'),
                          const SizedBox(height: AppSpacing.sm),
                          _buildActiveSubscriptionCard(state.subscription),
                          const SizedBox(height: AppSpacing.xl),
                          const SectionHeader(label: 'SEPETİM (ÖDEME BEKLEYENLER)'),
                          const SizedBox(height: AppSpacing.sm),
                          _buildCartSection(pending),
                        ],
                      ),
                    ),
                  ),

                  // TAB 2: ÖDEME GEÇMİŞİ
                  RefreshIndicator(
                    onRefresh: () async {
                      context.read<FinanceBloc>().add(LoadMyTransactions());
                    },
                    color: AppColors.primary,
                    child: history.isEmpty
                        ? _buildEmptyHistory()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: history.length,
                            itemBuilder: (context, index) {
                              return _buildHistoryItem(history[index]);
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSubscriptionCard(ClientSubscriptionModel? sub) {
    if (sub == null || !sub.isActive) {
      return GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(Icons.credit_card_off_rounded, color: AppColors.textMuted.withValues(alpha: 0.5), size: 36),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktif Abonelik Yok',
                    style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary, fontSize: 15),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Koçunuzun profilinden bir paket seçip sepetinize ekleyebilirsiniz.',
                    style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final totalDays = sub.startDate.difference(sub.endDate).inDays.abs();
    final progress = totalDays > 0 ? sub.daysRemaining / totalDays : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  sub.packageName,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heroTitle.copyWith(color: Colors.white, fontSize: 20),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'AKTİF',
                  style: AppTextStyles.tagText.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Antrenör: ${sub.coachName}',
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyText.copyWith(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kalan Süre', style: AppTextStyles.bodyText.copyWith(color: Colors.white70, fontSize: 12)),
              Text('${sub.daysRemaining} Gün', style: AppTextStyles.listTitle.copyWith(color: Colors.white, fontSize: 16)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Bitiş Tarihi: ${sub.endDate.day}.${sub.endDate.month}.${sub.endDate.year}',
            style: AppTextStyles.cardCaption.copyWith(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSection(List<PaymentTransactionModel> pending) {
    if (pending.isEmpty) {
      return const EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: 'Sepetinizde ödeme bekleyen paket bulunmuyor.',
      );
    }

    return Column(
      children: pending.map((tx) => _buildCartItem(tx)).toList(),
    );
  }

  Widget _buildCartItem(PaymentTransactionModel tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.packageName,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary, fontSize: 15),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Fiyat: ${tx.amount.toStringAsFixed(0)} ₺  ·  ${tx.durationDays} gün',
                        style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                  onPressed: () {
                    context.read<FinanceBloc>().add(RemovePackageFromCart(tx.id));
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: PremiumButton(
                    text: 'ÖDEMEYİ TAMAMLA',
                    onPressed: () {
                      final package = SubscriptionPackageModel(
                        id: tx.packageId,
                        name: tx.packageName,
                        price: tx.amount,
                        durationDays: tx.durationDays,
                      );
                      FocusManager.instance.primaryFocus?.unfocus();
                      context.push('/checkout', extra: {
                        'package': package,
                        'transactionId': tx.id,
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return const EmptyState(
      icon: Icons.shopping_cart_outlined,
      title: 'Henüz ödeme geçmişi bulunmamaktadır.',
    );
  }

  Widget _buildHistoryItem(PaymentTransactionModel tx) {
    final isSuccess = tx.status == 'SUCCESS';
    final dateStr = '${tx.transactionDate.day}.${tx.transactionDate.month}.${tx.transactionDate.year} ${tx.transactionDate.hour.toString().padLeft(2, '0')}:${tx.transactionDate.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isSuccess ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                color: isSuccess ? AppColors.success : AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.packageName,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary, fontSize: 14),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    dateStr,
                    style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${tx.amount.toStringAsFixed(0)} ₺',
                  style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary, fontSize: 15),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  isSuccess ? 'Başarılı' : 'Başarısız',
                  style: AppTextStyles.bodyText.copyWith(
                    color: isSuccess ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
