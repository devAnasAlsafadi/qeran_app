import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/state/safe_emit.dart';

import '../../domain/entities/badge_counts.dart';
import '../../domain/usecases/get_badges_usecase.dart';
import '../../domain/usecases/mark_tab_seen_usecase.dart';

/// App-scoped unread counts behind the bottom-nav dots and the notifications
/// bell, for whichever role is signed in.
///
/// One cubit serves both shells: the server answers `GET /api/badges` for the
/// caller's own role, so the user app simply never sees `casesUnread` and the
/// matchmaker never sees `likesUnread`. Splitting it per role would duplicate
/// every path to separate two sets of keys the server already keeps apart.
///
/// There is no loading or error state, deliberately. A badge is decoration on
/// a tab that works regardless; a failed refresh keeps the last known counts
/// rather than blanking a navigation bar or putting an error where a dot goes.
class BadgesCubit extends Cubit<BadgeCounts> with SafeEmit<BadgeCounts> {
  BadgesCubit({
    required GetBadgesUseCase getBadges,
    required MarkTabSeenUseCase markTabSeen,
  }) : _getBadges = getBadges,
       _markTabSeen = markTabSeen,
       super(const BadgeCounts.empty());

  final GetBadgesUseCase _getBadges;
  final MarkTabSeenUseCase _markTabSeen;

  /// Coalesces concurrent fetches. A resume refreshes, and the socket
  /// reconnect it causes refreshes again a moment later; sharing the in-flight
  /// future collapses the pair into one request. (Same shape as
  /// `CurrentSubscriptionCubit`.)
  Future<void>? _inflight;

  /// Pulls the authoritative counts. Hung off the hooks that already exist —
  /// shell mount, app resume, socket reconnect — rather than a schedule of its
  /// own.
  ///
  /// Silent on failure: the previous counts stay. A transient network blip must
  /// not clear a dot the user has not acted on, nor invent one.
  Future<void> refresh() {
    final existing = _inflight;
    if (existing != null) return existing;
    final task = _refresh();
    _inflight = task;
    task.whenComplete(() => _inflight = null);
    return task;
  }

  Future<void> _refresh() async {
    final result = await _getBadges();
    result.fold(
      (failure) => AppLogger.warning(
        'BADGES — refresh failed raw="${failure.message}"',
        tag: 'BADGES',
      ),
      (counts) => emit(counts),
    );
  }

  /// Applies one `BadgeUpdated` event from the chat hub.
  ///
  /// Assigns the count, never adds to it: the server sends the absolute value,
  /// so adding would double whatever a REST refresh had already counted.
  /// Unknown tab keys are stored and simply never read — the contract says to
  /// ignore what we do not recognise, and dropping it here would be one more
  /// place to edit when the backend grows a tab.
  void applyUpdate(String tabKey, int count) {
    if (tabKey.isEmpty) return;
    emit(state.withTab(tabKey, count < 0 ? 0 : count));
  }

  /// Zeroes a tab locally, then tells the server.
  ///
  /// Optimistic and one-way: the dot must disappear the instant the tab opens,
  /// and a failed call is not worth restoring it over — the user did look. The
  /// next [refresh] re-reads the truth either way, which is why the failure is
  /// logged and swallowed.
  Future<void> markSeen(String tabKey) async {
    if (tabKey.isEmpty || !state.has(tabKey)) return;
    emit(state.cleared(tabKey));
    final result = await _markTabSeen(tabKey);
    result.fold(
      (failure) => AppLogger.warning(
        'BADGES — mark-seen failed tab=$tabKey raw="${failure.message}"',
        tag: 'BADGES',
      ),
      (_) {},
    );
  }

  /// Drops every count. Called on sign-out so the next account cannot inherit
  /// the previous one's dots — this cubit is a lazy singleton and outlives the
  /// session that filled it.
  void clear() {
    if (state == const BadgeCounts.empty()) return;
    emit(const BadgeCounts.empty());
  }
}
