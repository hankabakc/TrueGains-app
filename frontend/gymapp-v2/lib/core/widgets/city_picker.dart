import 'package:flutter/material.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/constants/turkiye_cities.dart';

class CityPicker extends StatelessWidget {
  final String? province;
  final String? district;
  final ValueChanged<String?> onProvinceChanged;
  final ValueChanged<String?> onDistrictChanged;

  const CityPicker({
    super.key,
    required this.province,
    required this.district,
    required this.onProvinceChanged,
    required this.onDistrictChanged,
  });

  @override
  Widget build(BuildContext context) {
    final districts = province != null ? (kTurkiyeIlIlce[province] ?? const []) : const <String>[];
    
    // Ensure the current selected district is valid within the current province's districts list
    // or null if the province has changed.
    final currentDistrict = (province != null && districts.contains(district)) ? district : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('il_${province ?? ''}'),
          initialValue: province,
          dropdownColor: AppColors.background,
          style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
          items: kIlListesi
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e,
                      style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                    ),
                  ))
              .toList(),
          onChanged: onProvinceChanged,
          decoration: InputDecoration(
            labelText: 'İl',
            labelStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
            prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          key: ValueKey('ilce_${currentDistrict ?? ''}'),
          initialValue: currentDistrict,
          dropdownColor: AppColors.background,
          style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
          items: districts
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e,
                      style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                    ),
                  ))
              .toList(),
          onChanged: province == null ? null : onDistrictChanged,
          decoration: InputDecoration(
            labelText: 'İlçe',
            labelStyle: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
            prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
