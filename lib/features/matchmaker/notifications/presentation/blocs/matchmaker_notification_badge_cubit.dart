import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/matchmaker_notifications_page.dart';
import '../../domain/usecases/get_notifications_usecase.dart';

/// App-wide unread-badge source for the matchmaker bell (a lazy singleton, so
/// every `MatchmakerAppBar` and the inbox screen share one instance).
///
/// The backend exposes no read-state, so unread is a LOCAL heuristic on the
/// newest notification id: there are unread items when the newest id on the
/// server is greater than [StorageKeys.matchmakerNotifLastSeenId] (the id
/// stored the last time the inbox was opened). Identical to the user app's
/// `NotificationBadgeCubit`, down to the state being a plain `hasUnread` bool.
///
/// It used to key off `/notifications/count` instead: unread was
/// `max(0, currentTotal − lastSeenTotal)`. A total cannot tell "new" from
/// "different" — delete one notification server-side and the next arrival puts
/// the total back where it was, so the badge never lights. An id is monotonic,
/// so nothing that happens to older rows can mask a newer one.
class MatchmakerNotificationBadgeCubit extends Cubit<bool> with SafeEmit<bool> {
  final GetNotificationsUseCase _getNotifications;
  final SharedPrefService _prefs;

  /// Coalesces concurrent fetches (the `CurrentSubscriptionCubit` pattern).
  /// Without it, a resume ([refresh]) followed immediately by opening the inbox
  /// ([markAllSeen]) fires two requests back to back; sharing the in-flight
  /// future collapses them into one.
  Future<Either<Failure, MatchmakerNotificationsPage>>? _inflight;

  MatchmakerNotificationBadgeCubit({
    required GetNotificationsUseCase getNotifications,
    required SharedPrefService prefs,
  })  : _getNotifications = getNotifications,
        _prefs = prefs,
        super(false);

  /// Just the newest row — page 1, size 1. The id is all the heuristic needs.
  Future<Either<Failure, MatchmakerNotificationsPage>> _fetchNewest() {
    final existing = _inflight;
    if (existing != null) return existing;
    final task = _getNotifications(page: 1, pageSize: 1);
    _inflight = task;
    task.whenComplete(() => _inflight = null);
    return task;
  }

  /// Flags unread when the newest id on the server is greater than the stored
  /// last-seen id. Silent on failure (keeps the last value) — a transient
  /// network error never flips the badge.
  Future<void> refresh() async {
    final result = await _fetchNewest();
    await result.fold(
      (_) async {},
      (page) async {
        if (page.items.isEmpty) return;
        final seen = await _prefs.get<int>(
              StorageKeys.matchmakerNotifLastSeenId,
            ) ??
            0;
        if (!isClosed) emit(page.items.first.id > seen);
      },
    );
  }

  /// Marks the inbox seen up to the newest id — persists it (monotonic) and
  /// clears the badge. Called when the inbox is opened.
  ///
  /// Clears FIRST, before the round trip that establishes the new baseline. The
  /// user has just opened the inbox; making a local heuristic survive a network
  /// call to acknowledge that — and reappear if the call is slow or fails — is
  /// the wrong order.
  Future<void> markAllSeen() async {
    if (!isClosed) emit(false);
    final result = await _fetchNewest();
    await result.fold(
      (_) async {},
      (page) async {
        if (page.items.isEmpty) return;
        final newest = page.items.first.id;
        final seen = await _prefs.get<int>(
              StorageKeys.matchmakerNotifLastSeenId,
            ) ??
            0;
        if (newest > seen) {
          await _prefs.save(StorageKeys.matchmakerNotifLastSeenId, newest);
        }
      },
    );
  }
}
