import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/features/finance/presentation/bloc/finance_bloc.dart';

/// Koç Finans Detay Sayfası - Sporcunun aktif abonelik durumunu salt okunur gösterir.
class ClientFinanceDetailPage extends StatefulWidget {
  final int clientId;
  final String clientName;

  const ClientFinanceDetailPage({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<ClientFinanceDetailPage> createState() => _ClientFinanceDetailPageState();
}

class _ClientFinanceDetailPageState extends State<ClientFinanceDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<FinanceBloc>().add(LoadClientSubscription(widget.clientId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          '${widget.clientName} - FİNANS',
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          if (state.status == FinanceStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state.subscription == null) {
            return _buildNoSubscription();
          }

          final sub = state.subscription!;
          final totalDays = sub.startDate.difference(sub.endDate).inDays.abs();
          final progress = totalDays > 0 ? sub.daysRemaining / totalDays : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Paket bilgi kartı
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        sub.packageName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: sub.isActive
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Text(
                          sub.isActive ? '✅ AKTİF' : '❌ SONA ERMİŞ',
                          style: TextStyle(
                            color: sub.isActive ? AppColors.primary : AppColors.error,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Kalan gün progress
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'KALAN SÜRE',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            '${sub.daysRemaining} GÜN',
                            style: TextStyle(
                              color: sub.daysRemaining > 7 ? AppColors.primary : AppColors.error,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 12,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            sub.daysRemaining > 7 ? AppColors.primary : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Detay bilgi satırları
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildInfoRow('Ödenen Tutar', '${sub.price.toStringAsFixed(2)} ₺', Icons.payments_rounded),
                      const Divider(color: Colors.white10, height: 24),
                      _buildInfoRow(
                        'Başlangıç',
                        '${sub.startDate.day}.${sub.startDate.month}.${sub.startDate.year}',
                        Icons.play_circle_outline_rounded,
                      ),
                      const Divider(color: Colors.white10, height: 24),
                      _buildInfoRow(
                        'Bitiş',
                        '${sub.endDate.day}.${sub.endDate.month}.${sub.endDate.year}',
                        Icons.stop_circle_outlined,
                      ),
                      const Divider(color: Colors.white10, height: 24),
                      _buildInfoRow('Koç', sub.coachName, Icons.sports_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bu sayfa salt okunurdur. Değişiklik yapılamaz.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w900),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNoSubscription() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_off_rounded, color: AppColors.textMuted, size: 72),
            const SizedBox(height: 24),
            const Text(
              'Aktif Abonelik Yok',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bu sporcunun henüz aktif bir aboneliği bulunmamaktadır.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
