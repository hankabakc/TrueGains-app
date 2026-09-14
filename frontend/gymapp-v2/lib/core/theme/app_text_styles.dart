import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle get greeting => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get heroTitle => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get pageTitle => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
        color: AppColors.textPrimary,
      );

  static TextStyle get sectionLabel => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: AppColors.primary,
      );

  static TextStyle get cardLabel => GoogleFonts.outfit(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
      );

  static TextStyle get cardValue => GoogleFonts.outfit(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
        color: AppColors.textPrimary,
      );

  static TextStyle get cardCaption => GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: AppColors.textMuted,
      );

  static TextStyle get bodyText => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: AppColors.textSecondary,
      );

  static TextStyle get buttonText => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
      );

  static TextStyle get tagText => GoogleFonts.outfit(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );

  static TextStyle get listTitle => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get listSubtitle => GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: AppColors.textMuted,
      );

  static TextStyle get bubbleText => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: AppColors.textPrimary,
      );

  static TextStyle get timestamp => GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: AppColors.textMuted,
      );

  static TextStyle get emptyTitle => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get heroDisplay => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
        color: AppColors.textPrimary,
      );

  /// Sabit genişlikli rakam varyantı. Sürüklenerek değişen sayılarda (cetvel,
  /// sayaç) rakam genişliği değiştiği için sayı titrer; tabularFigures bunu
  /// engeller. Boyut çağıran tarafta copyWith ile verilir.
  static TextStyle get heroNumeral => heroDisplay.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
