// lib/features/call_history/data/call_log_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/models.dart';

class CallLogRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  CallLogRepository(this._db);

  Future<List<CallLogModel>> getAll({int limit = 200}) =>
      _db.getCallLogs(limit: limit);

  Future<List<CallLogModel>> getByNumber(String number) =>
      _db.getCallLogsByNumber(number);

  Future<int> getMissedCount() => _db.getMissedCallCount();

  Future<void> addLog({
    required String number,
    String? contactName,
    String? contactPhotoUri,
    required CallType type,
    required DateTime timestamp,
    int durationSeconds = 0,
    bool isRecorded = false,
    String? recordingPath,
    int simSlot = 0,
  }) async {
    final log = CallLogModel(
      id: _uuid.v4(),
      number: number,
      contactName: contactName,
      contactPhotoUri: contactPhotoUri,
      type: type,
      timestamp: timestamp,
      durationSeconds: durationSeconds,
      isRecorded: isRecorded,
      recordingPath: recordingPath,
      simSlot: simSlot,
    );
    await _db.insertCallLog(log);
  }

  Future<void> delete(String id) => _db.deleteCallLog(id);

  Future<void> clearAll() => _db.clearAllCallLogs();
}

// ─── Providers ────────────────────────────────────────────────────────────────

final callLogRepositoryProvider = Provider<CallLogRepository>((ref) {
  return CallLogRepository(AppDatabase());
});

final callLogsProvider = FutureProvider<List<CallLogModel>>((ref) {
  return ref.watch(callLogRepositoryProvider).getAll();
});

final missedCallCountProvider = FutureProvider<int>((ref) {
  return ref.watch(callLogRepositoryProvider).getMissedCount();
});

// Filter enum
enum CallLogFilter { all, missed, recorded }

final callLogFilterProvider =
    StateProvider<CallLogFilter>((ref) => CallLogFilter.all);

final filteredCallLogsProvider = FutureProvider<List<CallLogModel>>((ref) async {
  final all = await ref.watch(callLogsProvider.future);
  final filter = ref.watch(callLogFilterProvider);
  return switch (filter) {
    CallLogFilter.all => all,
    CallLogFilter.missed =>
      all.where((l) => l.type == CallType.missed).toList(),
    CallLogFilter.recorded => all.where((l) => l.isRecorded).toList(),
  };
});
