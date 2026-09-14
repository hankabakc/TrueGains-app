import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gymapp_v2/core/config/app_config.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/pressable_scale.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/social/data/models/discovery_user_model.dart';
import 'package:gymapp_v2/features/social/data/models/coach_specialization.dart';

class DiscoveryUserCard extends StatelessWidget {
  final DiscoveryUserModel user;
  final VoidCallback onViewProfile;
  final VoidCallback onSendMessage;

  const DiscoveryUserCard({
    super.key,
    required this.user,
    required this.onViewProfile,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    return _DiscoveryUserCardContent(
      user: user,
      onViewProfile: onViewProfile,
      onSendMessage: onSendMessage,
    );
  }
}

class _DiscoveryUserCardContent extends StatelessWidget {
  final DiscoveryUserModel user;
  final VoidCallback onViewProfile;
  final VoidCallback onSendMessage;

  const _DiscoveryUserCardContent({
    required this.user,
    required this.onViewProfile,
    required this.onSendMessage,
  });

  Widget get _photoFallback => Container(
        key: const Key('discovery_card_photo_fallback'),
        color: AppColors.primary.withValues(alpha: 0.10),
        child: const Icon(
          Icons.person_rounded,
          color: AppColors.primary,
          size: 40,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto =
        user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty;

    final List<String> specs = (user.specialization ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final bool isCoach = user.role == UserRole.COACH;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: PressableScale(
        // Kartin TAMAMI profile gider. Onceden ayri bir "PROFILI GOR"
        // dugmesi vardi; kart tiklanabilir olunca o dugme fazlalik.
        onTap: onViewProfile,
        child: GlassContainer(
          borderRadius: AppRadius.xl,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: hasPhoto
                      ? CachedNetworkImage(
                          imageUrl:
                              AppConfig.resolveFileUrl(user.profilePhotoUrl!),
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: AppColors.surface),
                          errorWidget: (context, url, error) => _photoFallback,
                        )
                      : _photoFallback,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.fullName ?? '',
                      style: AppTextStyles.listTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isCoach) ..._coachDetails(specs),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _messageButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Kocu SECTIREN bilgiler. Sifir degerler bilerek gosterilmiyor:
  /// "0 ogrenci" kartin tek sayisi olunca her koc kotu gorunuyordu.
  List<Widget> _coachDetails(List<String> specs) {
    final stats = <String>[];
    if (user.averageRating != null) {
      stats.add('${user.averageRating!.toStringAsFixed(1)} (${user.reviewCount})');
    }
    if (user.activeStudentCount > 0) {
      stats.add('${user.activeStudentCount} öğrenci');
    }

    final meta = <String>[];
    final location = _location;
    if (location != null) meta.add(location);
    if (user.experienceYears != null) meta.add('${user.experienceYears} yıl');

    return [
      if (stats.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.xxs),
        Row(
          children: [
            // Puan yokken yildiz gostermek yaniltici: "1 ogrenci" bir puan degil.
            Icon(
              user.averageRating != null
                  ? Icons.star_rounded
                  : Icons.groups_rounded,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
                stats.join(' · '),
                style: AppTextStyles.tagText.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
      if (meta.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.xxs),
        Row(
          children: [
            const Icon(
              Icons.place_outlined,
              size: 14,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
                meta.join(' · '),
                style: AppTextStyles.tagText
                    .copyWith(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
      if (user.minPackagePrice != null) ...[
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '${_formatPrice(user.minPackagePrice!)}\'den başlıyor',
          key: const Key('discovery_card_price'),
          style: AppTextStyles.tagText.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
      if (specs.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.xs),
        _specWrap(specs),
      ],
    ];
  }

  String? get _location {
    final province = user.province?.trim();
    if (province == null || province.isEmpty) return null;
    final district = user.district?.trim();
    if (district == null || district.isEmpty) return province;
    return '$province, $district';
  }

  String _formatPrice(double price) {
    const symbols = {'TRY': '₺', 'USD': '\$', 'EUR': '€', 'GBP': '£'};
    final symbol = symbols[user.currency] ?? '₺';
    return '$symbol${price.toStringAsFixed(0)}';
  }

  /// Uzmanliklarin HEPSI gosterilir; kocu kocdan ayiran asil bilgi bu.
  /// Serbest metin alani oldugu icin ust sinir var, sonsuza kadar sarmasin.
  Widget _specWrap(List<String> specs) {
    const maxVisible = 4;
    final visible = specs.take(maxVisible).toList();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...visible.map((s) {
          final enumVal = CoachSpecialization.values.firstWhere(
            (e) => e.apiValue == s,
            orElse: () => CoachSpecialization.fitness,
          );
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(enumVal.icon, size: 11, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  s,
                  style:
                      AppTextStyles.tagText.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          );
        }),
        if (specs.length > maxVisible)
          Text(
            '+${specs.length - maxVisible}',
            style: AppTextStyles.tagText.copyWith(color: AppColors.textMuted),
          ),
      ],
    );
  }

  /// Mesaj eylemi ikincil: kimse hakkinda hicbir sey bilmedigi koca mesaj
  /// atmiyor. Dolu daire yerine cerceve; dokunma hedefi yine 48x48.
  Widget _messageButton() {
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.glassBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSendMessage,
          child: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
