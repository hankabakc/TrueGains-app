import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/constants/app_strings.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/nutrition_camera/nutrition_camera_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/nutrition_camera/nutrition_camera_state.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';

class NutritionCameraPage extends StatelessWidget {
  final bool returnToBasket;
  const NutritionCameraPage({super.key, this.returnToBasket = false});

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<NutritionCameraCubit>(),
      child: BlocConsumer<NutritionCameraCubit, NutritionCameraState>(
        listener: (context, state) async {
          if (state.status == NutritionCameraStatus.success && state.scanResult != null) {
            if (returnToBasket) {
              context.pop(state.scanResult);
            } else {
              final result = await context.push('/nutrition/gemini-analysis', extra: state.scanResult);
              if (context.mounted && result == true) {
                context.pop(true);
              }
            }
          } else if (state.status == NutritionCameraStatus.failure && state.error != null) {
            _showError(context, state.error!);
          }
        },
        builder: (context, state) {
          final cubit = context.read<NutritionCameraCubit>();

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
            ),
            body: state.status == NutritionCameraStatus.analyzing ? _buildAnalyzingState(state) : _buildCameraMenu(cubit),
          );
        },
      ),
    );
  }

  Widget _buildAnalyzingState(NutritionCameraState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.primary.withAlpha(25), shape: BoxShape.circle),
            child: const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 4),
          ),
          const SizedBox(height: 32),
          Text(state.loadingMessage, textAlign: TextAlign.center, style: AppTextStyles.emptyTitle.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildCameraMenu(NutritionCameraCubit cubit) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(Icons.document_scanner_rounded, size: 120, color: AppColors.primary.withAlpha(200)),
          const SizedBox(height: 32),
          Text(AppStrings.smartFoodScan, textAlign: TextAlign.center, style: AppTextStyles.heroDisplay.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Text(AppStrings.smartFoodScanDesc, textAlign: TextAlign.center, style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 16)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              cubit.pickAndAnalyze(ImageSource.camera);
            },
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text(AppStrings.openCamera),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              textStyle: AppTextStyles.buttonText.copyWith(fontSize: 18),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => cubit.pickAndAnalyze(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_rounded, color: AppColors.textSecondary),
            label: Text(AppStrings.selectFromGallery, style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary, fontSize: 16)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
