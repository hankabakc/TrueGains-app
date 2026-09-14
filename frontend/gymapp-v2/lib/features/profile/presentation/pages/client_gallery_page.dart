import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gymapp_v2/core/config/app_config.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_text_styles.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:gymapp_v2/features/social/data/models/client_gallery_model.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/client_gallery_bloc.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/client_gallery_event.dart';
import 'package:gymapp_v2/features/social/presentation/bloc/client_gallery_state.dart';

class ClientGalleryPage extends StatefulWidget {
  const ClientGalleryPage({super.key});

  @override
  State<ClientGalleryPage> createState() => _ClientGalleryPageState();
}

class _ClientGalleryPageState extends State<ClientGalleryPage> {
  bool _isPickingImage = false;

  Future<void> _pickAndUploadImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        context.read<ClientGalleryBloc>().add(
              AddToClientGallery(
                filePath: image.path,
                fileName: image.name,
              ),
            );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _confirmDelete(int itemId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Center(
        child: GlassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Görseli Sil',
                  style: AppTextStyles.pageTitle.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bu görseli zaman tünelinizden silmek istediğinize emin misiniz?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('İptal', style: TextStyle(color: Colors.white54)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PremiumButton(
                        text: 'SİL',
                        color: AppColors.error,
                        height: 40,
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<ClientGalleryBloc>().add(DeleteFromClientGallery(itemId));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientGalleryBloc, ClientGalleryState>(
      listener: (context, state) {
        if (state is ClientGalleryOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.green),
          );
        } else if (state is ClientGalleryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Zaman Tüneli',
            style: AppTextStyles.pageTitle,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_a_photo_rounded, color: AppColors.primary),
              onPressed: _pickAndUploadImage,
            ),
          ],
        ),
        body: BlocBuilder<ClientGalleryBloc, ClientGalleryState>(
          builder: (context, state) {
            if (state is ClientGalleryLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (state is ClientGalleryLoaded) {
              if (state.images.isEmpty) {
                return _buildEmptyState();
              }
              return _buildGalleryGrid(state.images);
            }

            if (state is ClientGalleryInitial) {
              context.read<ClientGalleryBloc>().add(LoadClientGallery());
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            'Henüz görsel yüklemediniz.',
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: PremiumButton(
              text: 'İLK GÖRSELİ EKLE',
              onPressed: _pickAndUploadImage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid(List<ClientGalleryModel> images) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final img = images[index];
        final date = DateTime.tryParse(img.createdAt);
        final dateStr = date != null ? DateFormat('dd MMM yyyy').format(date) : '';

        return GlassContainer(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: CachedNetworkImage(
                          imageUrl: AppConfig.resolveFileUrl(img.imageUrl),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.white.withValues(alpha: 0.02)),
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white24),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _confirmDelete(img.id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  dateStr,
                  style: AppTextStyles.cardCaption.copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
