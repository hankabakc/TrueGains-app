import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/core/theme/app_dimens.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/core/widgets/premium_button.dart';
import 'package:gymapp_v2/core/widgets/list_skeleton.dart';
import 'package:gymapp_v2/features/finance/models/finance_models.dart';
import 'package:gymapp_v2/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:gymapp_v2/features/finance/ui/widgets/package_features_list.dart';
import 'package:gymapp_v2/features/auth/data/models/experience_level.dart';
import 'package:gymapp_v2/features/auth/data/models/coaching_mode.dart';

/// Koç Paket Yönetim Paneli - Koç kendi üyelik paketlerini yönetir.
class CoachPackagesPage extends StatefulWidget {
  const CoachPackagesPage({super.key});

  @override
  State<CoachPackagesPage> createState() => _CoachPackagesPageState();
}

class _CoachPackagesPageState extends State<CoachPackagesPage> {
  @override
  void initState() {
    super.initState();
    context.read<FinanceBloc>().add(LoadCoachMyPackages());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'PAKET YÖNETİMİ',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: BlocListener<FinanceBloc, FinanceState>(
        listener: (context, state) {
          if (state.status == FinanceStatus.packageActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage ?? 'İşlem başarılı.'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state.status == FinanceStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error ?? 'Bir hata oluştu.'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: BlocBuilder<FinanceBloc, FinanceState>(
          builder: (context, state) {
            if (state.status == FinanceStatus.loading && state.packages.isEmpty) {
              return const ListSkeleton(rowHeight: 96);
            }

            return Column(
              children: [
                Expanded(
                  child: state.packages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: state.packages.length,
                          itemBuilder: (context, index) {
                            return _buildPackageItem(state.packages[index]);
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: PremiumButton(
                    text: 'YENİ PAKET EKLE',
                    onPressed: () => _showPackageEditor(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 64),
            const SizedBox(height: 16),
            Text(
              'Henüz oluşturulmuş üyelik paketi bulunmuyor.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageItem(SubscriptionPackageModel pkg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.1,
                  height: MediaQuery.of(context).size.width * 0.1,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    pkg.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.white54, size: 20),
                  onPressed: () => _showPackageEditor(context, pkg: pkg),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                  onPressed: () => _showDeleteConfirmation(pkg),
                ),
              ],
            ),
            if (pkg.description != null && pkg.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                pkg.description!,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
            if (pkg.levels != null || pkg.mode != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (pkg.mode != null) ...[
                    (() {
                      final modeEnum = CoachingMode.fromString(pkg.mode);
                      if (modeEnum == null) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          modeEnum.toUIString(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }()),
                  ],
                  if (pkg.levels != null) ...[
                    ...pkg.levels!.split(',').map((levelStr) {
                      final levelEnum = ExperienceLevel.fromString(levelStr.trim());
                      if (levelEnum == null) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.glassWhite,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Text(
                          levelEnum.toUIString(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ],
            if (pkg.features != null && pkg.features!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              PackageFeaturesList(features: pkg.features),
            ],
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: AppColors.textMuted, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${pkg.durationDays} Gün',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    if (pkg.quota != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.groups_rounded, color: AppColors.textMuted, size: 16),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${pkg.activeSubscriberCount}/${pkg.quota} Dolu',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${pkg.price.toStringAsFixed(0)} ₺',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPackageEditor(BuildContext context, {SubscriptionPackageModel? pkg}) {
    final bloc = context.read<FinanceBloc>();
    final isEdit = pkg != null;
    final nameController = TextEditingController(text: pkg?.name);
    final priceController = TextEditingController(text: pkg?.price.toStringAsFixed(0));
    final durationController = TextEditingController(text: pkg?.durationDays.toString());
    final descController = TextEditingController(text: pkg?.description);
    final featuresController = TextEditingController(text: pkg?.features);
    final quotaController = TextEditingController(text: pkg?.quota?.toString());

    final Set<String> selectedLevels = {};
    if (pkg?.levels != null && pkg!.levels!.trim().isNotEmpty) {
      selectedLevels.addAll(
        pkg.levels!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
      );
    }
    String? selectedMode = pkg?.mode;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => GlassContainer(
          margin: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          borderRadius: 32,
          padding: const EdgeInsets.all(28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Paketi Düzenle' : 'Yeni Paket Ekle',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 24),
                _buildEditorField(
                  controller: nameController,
                  label: 'Paket Adı',
                  hint: 'Örn: 3 Aylık Birebir Takip',
                  icon: Icons.title_rounded,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildEditorField(
                        controller: priceController,
                        label: 'Ücret (₺)',
                        hint: 'Fiyat',
                        icon: Icons.payments_rounded,
                        keyboardType: TextInputType.number,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildEditorField(
                        controller: durationController,
                        label: 'Süre (Gün)',
                        hint: 'Örn: 90',
                        icon: Icons.schedule_rounded,
                        keyboardType: TextInputType.number,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildEditorField(
                  controller: quotaController,
                  label: 'Kontenjan (boş = sınırsız)',
                  hint: 'Örn: 10',
                  icon: Icons.groups_rounded,
                  keyboardType: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Seviye (En az bir adet)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExperienceLevel.values.map((level) {
                    final jsonStr = level.toJsonString();
                    final isSelected = selectedLevels.contains(jsonStr);
                    return FilterChip(
                      label: Text(level.toUIString()),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      checkmarkColor: AppColors.background,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.background : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : Colors.white10,
                        ),
                      ),
                      onSelected: (selected) {
                        setSheetState(() {
                          if (selected) {
                            selectedLevels.add(jsonStr);
                          } else {
                            selectedLevels.remove(jsonStr);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Çalışma Modu',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CoachingMode.values.map((mode) {
                    final jsonStr = mode.toJsonString();
                    final isSelected = selectedMode == jsonStr;
                    return ChoiceChip(
                      label: Text(mode.toUIString()),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.background : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : Colors.white10,
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setSheetState(() {
                            selectedMode = jsonStr;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _buildEditorField(
                  controller: descController,
                  label: 'Açıklama / Detaylar',
                  hint: 'Paket içeriğini açıklayın...',
                  icon: Icons.description_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildEditorField(
                  controller: featuresController,
                  label: 'Neler Dahil? (her satıra bir madde)',
                  hint: 'Haftalık birebir görüşme\nBeslenme programı dahil\nWhatsApp desteği',
                  icon: Icons.checklist_rounded,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 32),
                PremiumButton(
                  text: isEdit ? 'GÜNCELLE' : 'OLUŞTUR',
                  onPressed: () {
                    final name = nameController.text.trim();
                    final price = double.tryParse(priceController.text) ?? 0.0;
                    final duration = int.tryParse(durationController.text) ?? 0;
                    final desc = descController.text.trim();
                    final features = featuresController.text.trim();
                    final quotaStr = quotaController.text.trim();
                    final quota = quotaStr.isEmpty ? null : int.tryParse(quotaStr);

                    if (name.isEmpty) {
                      _showError(sheetContext, 'Paket adı boş bırakılamaz.');
                      return;
                    }
                    if (price <= 0) {
                      _showError(sheetContext, 'Geçerli bir fiyat giriniz.');
                      return;
                    }
                    if (duration <= 0) {
                      _showError(sheetContext, 'Geçerli bir süre giriniz.');
                      return;
                    }
                    if (selectedLevels.isEmpty) {
                      _showError(sheetContext, 'En az bir seviye seçmelisiniz.');
                      return;
                    }
                    if (selectedMode == null) {
                      _showError(sheetContext, 'Çalışma modu seçmelisiniz.');
                      return;
                    }
                    if (desc.isEmpty) {
                      _showError(sheetContext, 'Açıklama boş bırakılamaz.');
                      return;
                    }
                    if (features.isEmpty) {
                      _showError(sheetContext, 'Neler dahil alanı boş bırakılamaz.');
                      return;
                    }

                    if (isEdit) {
                      bloc.add(UpdateCoachPackage(
                        id: pkg.id,
                        name: name,
                        price: price,
                        durationDays: duration,
                        description: desc,
                        features: features,
                        quota: quota,
                        levels: selectedLevels.join(','),
                        mode: selectedMode!,
                      ));
                    } else {
                      bloc.add(CreateCoachPackage(
                        name: name,
                        price: price,
                        durationDays: duration,
                        description: desc,
                        features: features,
                        quota: quota,
                        levels: selectedLevels.join(','),
                        mode: selectedMode!,
                      ));
                    }
                    Navigator.pop(sheetContext);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDeleteConfirmation(SubscriptionPackageModel pkg) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Paketi Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          '"${pkg.name}" paketini silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İPTAL', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<FinanceBloc>().add(DeleteCoachPackage(pkg.id));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            child: const Text('SİL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
