import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:gymapp_v2/features/nutrition/data/repositories/nutrition_repository.dart';
import 'package:gymapp_v2/features/training/repository/training_repository.dart';

/// Uygulama öne gelince bekleyen çevrimdışı kayıtları göndermeyi dener (G-69). Geçici hatada kayıt
/// bir sonraki bağlantı değişimini beklemesin diye.
///
/// Açılışta ve öne gelince besin kataloğu ile egzersiz kütüphanesi de telefona iner / tazelenir (KR13, KR16,
/// G-71); yanıtları okuma önbelleği saklar, internetsizken oradan cevaplanır.
class SyncOnResume extends StatefulWidget {
  final Widget child;

  const SyncOnResume({super.key, required this.child});

  @override
  State<SyncOnResume> createState() => _SyncOnResumeState();
}

class _SyncOnResumeState extends State<SyncOnResume> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshReferenceData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final sl = GetIt.instance;
    if (sl.isRegistered<SyncManager>()) {
      sl<SyncManager>().syncPendingData();
    }
    _refreshReferenceData();
  }

  /// Sonuç beklenmez; internet yoksa istek önbellekten cevaplanır ya da hata cevabı olarak döner.
  void _refreshReferenceData() {
    final sl = GetIt.instance;
    // ponytail: her açılış/öne gelişte tamamı yeniden iner (katalog birkaç bin kayıt, KR16); büyürse değişenler.
    if (sl.isRegistered<NutritionRepository>()) {
      sl<NutritionRepository>().refreshFoodCatalog();
    }
    if (sl.isRegistered<TrainingRepository>()) {
      sl<TrainingRepository>().getAllExercises();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
