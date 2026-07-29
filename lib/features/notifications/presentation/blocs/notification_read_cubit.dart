import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/state/safe_emit.dart';

import 'notification_read_state.dart';

/// Owns the inbox's local read-state ([NotificationReadState]).
///
/// Talks to [SharedPrefService] directly, like [NotificationBadgeCubit] beside
/// it: there is nothing to fetch and nothing to send — the backend has no
/// read-state — so a use case and a repository would only wrap a preference.
/// If the backend ever grows one, this is the single seam to move behind it.
///
/// A lazy singleton, so the styling survives leaving and re-entering the inbox
/// without a re-read of prefs.
class NotificationReadCubit extends Cubit<NotificationReadState>
    with SafeEmit<NotificationReadState> {
  final SharedPrefService _prefs;

  NotificationReadCubit({required SharedPrefService prefs})
      : _prefs = prefs,
        super(const NotificationReadState());

  /// Restores the stored watermark + ids. Ids at or below the watermark are
  /// dropped on the way in, so a stale list can't outlive a "mark all".
  Future<void> load() async {
    final watermark = await _prefs.get<int>(StorageKeys.notifReadWatermark) ?? 0;
    final stored =
        await _prefs.get<List<String>>(StorageKeys.notifReadIds) ??
            const <String>[];
    final ids = stored
        .map(int.tryParse)
        .whereType<int>()
        .where((id) => id > watermark)
        .toSet();
    emit(NotificationReadState(watermark: watermark, readIds: ids));
  }

  /// Marks ONE notification read — what tapping a row does.
  Future<void> markRead(int id) async {
    if (state.isRead(id)) return;
    final ids = {...state.readIds, id};
    await _prefs.save(
      StorageKeys.notifReadIds,
      ids.map((id) => '$id').toList(growable: false),
    );
    emit(NotificationReadState(watermark: state.watermark, readIds: ids));
  }

  /// Marks everything up to [newestId] read and drops the per-id list, which is
  /// now entirely below the watermark. Monotonic: a stale [newestId] (an older
  /// page arriving late) can never un-read anything.
  Future<void> markAllRead(int newestId) async {
    final watermark = newestId > state.watermark ? newestId : state.watermark;
    await _prefs.save(StorageKeys.notifReadWatermark, watermark);
    await _prefs.remove(StorageKeys.notifReadIds);
    emit(NotificationReadState(watermark: watermark));
  }
}
