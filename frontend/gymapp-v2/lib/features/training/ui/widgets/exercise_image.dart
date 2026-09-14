import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Egzersiz görsellerini esnek ve güvenli şekilde render eden widget.
/// Yerel asset dosyalarını ve uzaktaki (HTTP/HTTPS) görselleri destekler.
/// Görsel bulunamadığında veya hata oluştuğunda şık bir yedek (fallback) ikon gösterir.
class ExerciseImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final double size;
  final Color iconColor;
  final Color backgroundColor;
  final double borderRadius;
  final BoxFit fit;
  final Alignment alignment;

  const ExerciseImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.size = 52,
    required this.iconColor,
    required this.backgroundColor,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final double finalWidth = width ?? size;
    final double finalHeight = height ?? size;

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _buildFallbackIcon(finalWidth, finalHeight);
    }

    final trimmedUrl = imageUrl!.trim();

    // 1. Uzaktaki Web Görseli Desteği (HTTP/HTTPS)
    if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: trimmedUrl,
          width: finalWidth,
          height: finalHeight,
          fit: fit,
          alignment: alignment,
          placeholder: (context, url) => Container(
            width: finalWidth,
            height: finalHeight,
            color: backgroundColor,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallbackIcon(finalWidth, finalHeight),
        ),
      );
    }

    // 2. Yerel Asset Görseli Desteği
    final String assetPath = trimmedUrl.startsWith('assets/')
        ? trimmedUrl
        : 'assets/images/exercises/$trimmedUrl';

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        assetPath,
        width: finalWidth,
        height: finalHeight,
        fit: fit,
        alignment: alignment,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackIcon(finalWidth, finalHeight);
        },
      ),
    );
  }

  Widget _buildFallbackIcon(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.fitness_center_rounded,
        color: iconColor,
        size: (w > h ? h : w) * 0.46,
      ),
    );
  }
}
