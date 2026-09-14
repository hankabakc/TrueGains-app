import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/features/finance/models/finance_models.dart';
import 'package:gymapp_v2/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/features/finance/repository/finance_repository.dart';
import 'package:gymapp_v2/features/finance/ui/widgets/package_features_list.dart';

/// Sporcu Ödeme Sayfası - Sepetteki (ödeme bekleyen) işlem için ödeme yapma.
class CheckoutPage extends StatefulWidget {
  final SubscriptionPackageModel package;
  final int transactionId;

  const CheckoutPage({
    super.key,
    required this.package,
    required this.transactionId,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {

  Future<void> _handlePayment() async {
    // Yükleniyor dialog gösterimi
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final response = await sl<FinanceRepository>().getPurchaseIntent(widget.transactionId);
    
    if (!mounted) return;
    Navigator.pop(context); // Yükleniyor dialogunu kapat

    if (!response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final intent = response.data;
    if (intent == null) return;

    bool proceed = true;

    if (intent.type == 'DIFFERENT_COACH') {
      final coachName = intent.currentCoachName ?? 'Mevcut Koçunuz';
      proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: Text(
            'Koç Değişikliği',
            style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Farklı bir koçtan paket alıyorsunuz. Onaylarsanız mevcut koçunuz ($coachName) ile bağlantınız kopacak; o koça ait antrenman ve diyet programlarınız arşivlenecek. Devam edilsin mi?',
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'İPTAL',
                style: AppTextStyles.buttonText.copyWith(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'DEVAM ET',
                style: AppTextStyles.buttonText.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ) ?? false;
    } else if (intent.type == 'SAME_COACH_DIFFERENT_PACKAGE') {
      proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: Text(
            'Farklı Paket',
            style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Şu an farklı bir paket alıyorsunuz. Bu paket mevcut aboneliğinize EKLENMEZ (süreniz uzamaz); ayrı bir abonelik olarak başlatılır. Devam edilsin mi?',
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'İPTAL',
                style: AppTextStyles.buttonText.copyWith(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'DEVAM ET',
                style: AppTextStyles.buttonText.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ) ?? false;
    }

    if (!mounted) return;

    if (proceed) {
      context.read<FinanceBloc>().add(InitiateCheckoutEvent(widget.transactionId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FinanceBloc, FinanceState>(
      listener: (context, state) {
        if (state.status == FinanceStatus.checkoutInitiated && state.paymentUrl != null) {
          context.push(state.paymentUrl!);
        } else if (state.status == FinanceStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error ?? 'Ödeme başlatma işlemi başarısız.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
              margin: const EdgeInsets.all(AppSpacing.lg),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'ÖDEME ÖZETİ',
            style: AppTextStyles.greeting.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Paket bilgisi kartı
              _buildPackageInfoCard(),
              const SizedBox(height: AppSpacing.xl),
              // Ödeme butonu
              BlocBuilder<FinanceBloc, FinanceState>(
                builder: (context, state) {
                  if (state.status == FinanceStatus.loading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  return PremiumButton(
                    text: 'GÜVENLİ ÖDEMEYE GEÇ',
                    onPressed: _handlePayment,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  '🔒 PCI-DSS uyumlu harici güvenli ödeme arayüzüne yönlendirileceksiniz.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageInfoCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.package.name,
                      style: AppTextStyles.listTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${widget.package.durationDays} Gün',
                      style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.package.description != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.package.description!,
              style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
          if (widget.package.features != null && widget.package.features!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            PackageFeaturesList(features: widget.package.features),
          ],
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '${widget.package.price.toStringAsFixed(2)} ₺',
              textAlign: TextAlign.center,
              style: AppTextStyles.heroDisplay.copyWith(
                color: AppColors.primary,
                fontSize: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
