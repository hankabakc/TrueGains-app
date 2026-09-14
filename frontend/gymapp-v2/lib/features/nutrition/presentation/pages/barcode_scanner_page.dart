import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/barcode_scanner/barcode_scanner_cubit.dart';
import 'package:gymapp_v2/features/nutrition/presentation/bloc/barcode_scanner/barcode_scanner_state.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<BarcodeScannerCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Barkod Tara',
            style: AppTextStyles.pageTitle,
          ),
          actions: [
            IconButton(
              icon: Icon(
                controller.torchEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: controller.torchEnabled ? Colors.yellow : Colors.white,
              ),
              onPressed: () {
                controller.toggleTorch();
                setState(() {});
              },
            ),
          ],
        ),
        body: BlocConsumer<BarcodeScannerCubit, BarcodeScannerState>(
          listener: (context, state) {
            if (state is BarcodeScannerSuccess) {
              Navigator.pop(context, state.food);
            }
            if (state is BarcodeScannerError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        context.read<BarcodeScannerCubit>().scanBarcode(barcode.rawValue!);
                      }
                    }
                  },
                ),
                // Tarama Alanı Çerçevesi
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 2),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
                if (state is BarcodeScannerLoading)
                  const Center(
                    child: GlassContainer(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
