import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final Border? border;
  final Color? color;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final BoxConstraints? constraints;
  final bool elevated;
  final List<BoxShadow>? shadow;
  final Gradient? overlayGradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = AppRadius.xl,
    this.blur = 15,
    this.padding,
    this.border,
    this.color,
    this.gradient,
    this.width,
    this.height,
    this.margin,
    this.constraints,
    this.elevated = false,
    this.shadow,
    this.overlayGradient,
  });

  @override
  Widget build(BuildContext context) {
    final hasOverlay = overlayGradient != null;
    // ListTile gibi Material bileşenleri arka planlarını ve dokunma dalgalarını en yakın
    // Material atasına çizer. Bu widget'ın kendi renkli kutusu araya girdiği için Flutter
    // "ListTile background color or ink splashes may be invisible" hatası atıyordu
    // (Sentry'de 152 olay). Şeffaf Material aradaki boşluğu kapatır.
    //
    // textStyle AKTARILMAK ZORUNDA: Material, çocuğunu her hâlükârda
    // AnimatedDefaultTextStyle ile sarar (material.dart:476) ve varsayılan olarak
    // theme.textTheme.bodyMedium uygular — aktarılmazsa tüm cam kartlardaki yazı stili
    // sessizce değişir.
    final Widget inkSafeChild = Material(
      type: MaterialType.transparency,
      textStyle: DefaultTextStyle.of(context).style,
      child: child,
    );
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: shadow != null ? BoxDecoration(boxShadow: shadow) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: hasOverlay ? EdgeInsets.zero : padding,
            constraints: constraints,
            decoration: BoxDecoration(
              color: elevated 
                  ? AppColors.card 
                  : (gradient == null ? (color ?? AppColors.glassWhite) : null),
              gradient: elevated ? null : gradient,
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ?? Border.all(color: AppColors.glassBorder),
            ),
            child: hasOverlay
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: overlayGradient,
                            borderRadius: BorderRadius.circular(borderRadius),
                          ),
                        ),
                      ),
                      Padding(
                        padding: padding ?? EdgeInsets.zero,
                        child: inkSafeChild,
                      ),
                    ],
                  )
                : inkSafeChild,
          ),
        ),
      ),
    );
  }
}
