import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gymapp_v2/core/config/app_config.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';

class NetworkAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final IconData fallbackIcon;

  /// Fotoğraf yoksa veya yüklenemezse gösterilecek ad. Verilirse ilk harfi çizilir,
  /// verilmezse [fallbackIcon] kullanılır. Liste ekranlarında herkesin aynı ikonla
  /// görünmesi kullanıcıları ayırt edilemez hâle getiriyordu.
  final String? fallbackText;
  final Color ringColor;
  final bool gradientRing;

  const NetworkAvatar({
    super.key,
    required this.imageUrl,
    this.size = 56,
    this.fallbackIcon = Icons.person_rounded,
    this.fallbackText,
    this.ringColor = AppColors.primary,
    this.gradientRing = false,
  });

  Widget _buildFallback() {
    final String? name = fallbackText?.trim();
    if (name == null || name.isEmpty) {
      return Icon(fallbackIcon, color: AppColors.primary, size: size * 0.5);
    }
    return Center(
      child: Text(
        name[0].toUpperCase(),
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: gradientRing
            ? null
            : Border.all(
                color: ringColor.withValues(alpha: 0.3),
                width: 2,
              ),
        gradient: gradientRing ? AppColors.primaryGradient : null,
      ),
      padding: gradientRing ? const EdgeInsets.all(2) : null,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipOval(
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: AppConfig.resolveFileUrl(imageUrl!),
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => _buildFallback(),
                  placeholder: (context, url) => const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              : _buildFallback(),
        ),
      ),
    );
  }
}
