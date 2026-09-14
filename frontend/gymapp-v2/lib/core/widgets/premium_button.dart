import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

enum PremiumButtonVariant { primary, secondary }

class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final double height;
  final PremiumButtonVariant variant;

  const PremiumButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
    this.height = 56,
    this.variant = PremiumButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == PremiumButtonVariant.primary;
    final baseColor = color ?? (isPrimary ? AppColors.primary : Colors.white10);
    // Neon yeşil (#00E5A0) zemin üzerinde beyaz metin ~1.6:1 kontrast veriyordu
    // (WCAG AA eşiği 4.5:1). Siyah aynı zeminde ~12:1 verir.
    final fgColor = isPrimary ? Colors.black : Colors.white70;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow:
            onPressed != null && isPrimary
                ? [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                : null,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: baseColor,
          foregroundColor: fgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side:
                !isPrimary
                    ? BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)
                    : BorderSide.none,
          ),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child:
            isLoading
                ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: fgColor,
                    strokeWidth: 2,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        text,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
