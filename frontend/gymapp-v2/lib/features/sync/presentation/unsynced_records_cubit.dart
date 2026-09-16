import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';

class UnsyncedRecordsState extends Equatable {
  final List<RejectedRecord> records;
  final bool busy;

  const UnsyncedRecordsState({this.records = const <RejectedRecord>[], this.busy = false});

  @override
  List<Object?> get props => [records, busy];
}

/// Aktarılamayan kayıtlar ekranı (G-69).
class UnsyncedRecordsCubit extends Cubit<UnsyncedRecordsState> {
  final SyncManager _syncManager;

  UnsyncedRecordsCubit(this._syncManager) : super(const UnsyncedRecordsState());

  void load() {
    emit(UnsyncedRecordsState(records: _syncManager.rejectedRecords()));
  }

  Future<void> retry(String key) async {
    emit(UnsyncedRecordsState(records: state.records, busy: true));
    await _syncManager.retry(key);
    if (isClosed) return;
    load();
  }

  Future<void> discard(String key) async {
    emit(UnsyncedRecordsState(records: state.records, busy: true));
    await _syncManager.discard(key);
    if (isClosed) return;
    load();
  }
}
