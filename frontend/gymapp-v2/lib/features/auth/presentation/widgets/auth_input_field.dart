import 'package:flutter/material.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';

class AuthInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onToggleVisibility;
  final String? errorText;
  final TextInputType keyboardType;
  final Iterable<String>? autofillHints;
  final int maxLines;

  const AuthInputField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    required this.icon,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onToggleVisibility,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.autofillHints,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          obscureText: isPassword && !isPasswordVisible,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          maxLines: isPassword ? 1 : maxLines,
          style: AppTextStyles.bodyText.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            // Çok satırlı alanda prefixIcon kutunun dikey ortasına oturuyor ve
            // metinden kopuk duruyor; o durumda hiç gösterilmiyor.
            prefixIcon: maxLines > 1
                ? null
                : Icon(icon, color: AppColors.primary, size: 20),
            suffixIcon: (isPassword && onToggleVisibility != null)
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
