import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';

/// Uygulama öne gelince bekleyen çevrimdışı kayıtları göndermeyi dener (G-69). Geçici hatada kayıt
/// bir sonraki bağlantı değişimini beklemesin diye.
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
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
