import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';

import '../../domain/usecases/get_notifications_usecase.dart';

/// App-wide unread indicator for the user-app notifications bell — a lazy
/// singleton shared by the discovery bell and the inbox screen.
///
/// The backend exposes no read-state, so unread is a LOCAL heuristic on the
/// newest notification id: there are unread items when the newest id on the
/// server is greater than [StorageKeys.notifLastSeenId] (the id stored the last
/// time the inbox was opened). State is a simple `hasUnread` boolean — distinct
/// from the matchmaker badge, which uses a count heuristic.
class NotificationBadgeCubit extends Cubit<bool> {
  final GetNotificationsUseCase _getNotifications;
  final SharedPrefService _prefs;

  NotificationBadgeCubit({
    required GetNotificationsUseCase getNotifications,
    required SharedPrefService prefs,
  })  : _getNotifications = getNotifications,
        _prefs = prefs,
        super(false);

  /// Fetches just the newest notification (page 1, size 1) and flags unread
  /// when its id is greater than the stored last-seen id. Silent on failure
  /// (keeps the last value) — a transient network error never flips the badge.
  Future<void> refresh() async {
    final result = await _getNotifications(page: 1, pageSize: 1);
    await result.fold(
      (_) async {},
      (page) async {
        if (page.items.isEmpty) return;
        final newest = page.items.first.id;
        final seen = await _prefs.get<int>(StorageKeys.notifLastSeenId) ?? 0;
        if (!isClosed) emit(newest > seen);
      },
    );
  }

  /// Marks the inbox seen up to [newestId] — persists it (monotonic) and clears
  /// the badge. Called when the inbox screen loads its list.
  Future<void> markSeen(int newestId) async {
    final seen = await _prefs.get<int>(StorageKeys.notifLastSeenId) ?? 0;
    if (newestId > seen) {
      await _prefs.save(StorageKeys.notifLastSeenId, newestId);
    }
    if (!isClosed) emit(false);
  }
}
