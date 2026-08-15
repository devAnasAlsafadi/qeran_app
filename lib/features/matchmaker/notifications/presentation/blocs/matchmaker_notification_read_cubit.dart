import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/state/safe_emit.dart';

/// Local read watermark for the matchmaker inbox: every notification with an id
/// at or below the state counts as read.
///
/// Mirrors the user app's `NotificationReadCubit` minus its per-id half. The
/// backend exposes no read-state and no `POST /notifications/{id}/read`, and
/// marking a single row read is deliberately out of scope, so a watermark is
/// all there is. Talks to [SharedPrefService] directly for the same reason the
/// user-side cubit does — there is nothing to fetch and nothing to send, so a
/// use case and a repository would only wrap a preference. If the backend ever
/// grows read-state, this is the single seam to move behind it.
///
/// The state is the watermark AS IT WAS WHEN THE SCREEN OPENED, and
/// [markAllRead] deliberately does NOT emit. Advancing the visible watermark
/// while the list is on screen would mark every row read the instant it
/// appeared — the exact mistake the user app shipped and reverted (pinned in
/// `notifications_read_state_test.dart`: "marking everything read the instant
/// the list appeared left nothing for the user to see"). So a visit shows what
/// arrived since the last one, and the next visit starts clean.
///
/// Registered as a FACTORY, one per screen mount: re-entering the inbox
/// re-reads prefs, so rows highlighted a moment ago come back read.
class MatchmakerNotificationReadCubit extends Cubit<int> with SafeEmit<int> {
  final SharedPrefService _prefs;

  MatchmakerNotificationReadCubit({required SharedPrefService prefs})
      : _prefs = prefs,
        super(0);

  /// Restores the stored watermark. Until this resolves the state is 0, so a
  /// first frame shows everything unread and settles a moment later.
  Future<void> load() async {
    final stored =
        await _prefs.get<int>(StorageKeys.matchmakerNotifReadWatermark) ?? 0;
    emit(stored);
  }

  bool isUnread(int id) => id > state;

  /// Persists [newestId] as the new watermark WITHOUT emitting — see the class
  /// doc. Reads the STORED value rather than [state], which is frozen at mount.
  /// Monotonic: an older page arriving late can never un-read anything.
  Future<void> markAllRead(int newestId) async {
    final stored =
        await _prefs.get<int>(StorageKeys.matchmakerNotifReadWatermark) ?? 0;
    if (newestId <= stored) return;
    await _prefs.save(StorageKeys.matchmakerNotifReadWatermark, newestId);
  }
}
