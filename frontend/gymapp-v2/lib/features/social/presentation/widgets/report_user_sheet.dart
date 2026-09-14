import 'package:flutter/material.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/features/social/data/services/social_api_service.dart';

/// Sikayet sebepleri. Serbest metin DEGIL: kapali kume olunca yonetim tarafinda
/// gruplanabiliyor ve istatistigi alinabiliyor.
const Map<String, String> _reasons = {
  'SPAM': 'Spam / reklam',
  'HARASSMENT': 'Taciz veya hakaret',
  'INAPPROPRIATE_CONTENT': 'Uygunsuz içerik',
  'FAKE_PROFILE': 'Sahte profil',
  'SCAM': 'Dolandırıcılık',
  'OTHER': 'Diğer',
};

/// Kullaniciyi sikayet etme alt paneli.
Future<void> showReportUserSheet(
  BuildContext context, {
  required int reportedUserId,
  required String displayName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportUserSheet(
      reportedUserId: reportedUserId,
      displayName: displayName,
    ),
  );
}

class _ReportUserSheet extends StatefulWidget {
  final int reportedUserId;
  final String displayName;

  const _ReportUserSheet({
    required this.reportedUserId,
    required this.displayName,
  });

  @override
  State<_ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends State<_ReportUserSheet> {
  String? _reason;
  final _descriptionController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null) return;

    setState(() => _sending = true);

    final response = await sl<SocialApiService>().reportUser(
      reportedUserId: widget.reportedUserId,
      reason: reason,
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _sending = false);

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.success
              ? 'Şikâyetiniz alındı, en kısa sürede incelenecek.'
              : response.message,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: GlassContainer(
        borderRadius: AppRadius.xl,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Şikâyet et',
              style: AppTextStyles.listTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              widget.displayName,
              style: AppTextStyles.tagText.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Sebep',
              style: AppTextStyles.cardLabel
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: _reasons.entries.map((entry) {
                final selected = _reason == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  labelStyle: AppTextStyles.tagText.copyWith(
                    color: selected
                        ? AppColors.background
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: AppColors.glassWhite,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  onSelected: (value) {
                    if (value) setState(() => _reason = entry.key);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 1000,
              style: AppTextStyles.bodyText,
              decoration: const InputDecoration(
                hintText: 'Açıklama (isteğe bağlı)',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_reason == null || _sending) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: Text(
                  _sending ? 'Gönderiliyor…' : 'Şikâyeti gönder',
                  style: AppTextStyles.buttonText.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
