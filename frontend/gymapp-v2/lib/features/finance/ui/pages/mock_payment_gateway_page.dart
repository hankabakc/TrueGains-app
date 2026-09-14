import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/features/finance/presentation/bloc/finance_bloc.dart';

/// 3. Parti Ödeme Sağlayıcı Simülasyon Ekranı (MockPaymentGatewayPage)
class MockPaymentGatewayPage extends StatefulWidget {
  final String sessionId;

  const MockPaymentGatewayPage({super.key, required this.sessionId});

  @override
  State<MockPaymentGatewayPage> createState() => _MockPaymentGatewayPageState();
}

class _MockPaymentGatewayPageState extends State<MockPaymentGatewayPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<FinanceBloc, FinanceState>(
      listener: (context, state) {
        if (state.status == FinanceStatus.webhookTriggered) {
          setState(() => _isLoading = false);
          context.go('/checkout/success');
        } else if (state.status == FinanceStatus.error) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error ?? 'Ödeme simülasyonu başarısız.'),
              backgroundColor: AppColors.error,
            ),
          );
          context.go('/checkout/failure');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            _buildBackgroundGradients(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildGatewayCard(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundGradients() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                'GÜVENLİ ÖDEME SİMÜLASYONU (PCI-DSS)',
                style: AppTextStyles.tagText.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_rounded, color: AppColors.textPrimary, size: 28),
            const SizedBox(width: 12),
            Text(
              'PAYMENT GATEWAY',
              style: AppTextStyles.heroTitle.copyWith(
                color: AppColors.textPrimary,
                fontSize: 22,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGatewayCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İŞLEM DETAYLARI',
            style: AppTextStyles.cardLabel.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const Divider(color: AppColors.glassBorder, height: 24),
          _buildInfoRow('Oturum ID', widget.sessionId),
          _buildInfoRow('Sağlayıcı', 'Stripe Mock Provider v2'),
          _buildInfoRow('İşlem Tipi', 'Kredi Kartı / 3D Secure'),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'KART BİLGİLERİ (TEST SİMÜLASYONU)',
            style: AppTextStyles.tagText.copyWith(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            enabled: false,
            controller: TextEditingController(text: '4242 4242 4242 4242'),
            style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.glassWhite,
              labelText: 'Kart Numarası',
              labelStyle: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.credit_card, color: AppColors.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else ...[
            PremiumButton(
              text: 'ÖDEMEYİ SİMÜLE ET (SUCCESS)',
              color: AppColors.success,
              onPressed: () {
                setState(() => _isLoading = true);
                context.read<FinanceBloc>().add(TriggerPaymentWebhookEvent(
                  sessionId: widget.sessionId,
                  status: 'SUCCESS',
                ));
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            PremiumButton(
              text: 'ÖDEMEYİ İPTAL ET / SİMÜLE ET (FAIL)',
              color: AppColors.error,
              onPressed: () {
                setState(() => _isLoading = true);
                context.read<FinanceBloc>().add(TriggerPaymentWebhookEvent(
                  sessionId: widget.sessionId,
                  status: 'FAILED',
                ));
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 13)),
          Text(value, style: AppTextStyles.listTitle.copyWith(color: AppColors.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }
}
