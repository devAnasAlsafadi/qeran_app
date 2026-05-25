import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/current_subscription.dart';
import '../../../domain/usecases/get_current_subscription_usecase.dart';
import 'current_subscription_state.dart';

/// App-scoped (lazy singleton) holder for the signed-in user's
/// subscription state. Mirrors the carve-out documented on
/// `UserSessionCubit` — lives for the lifetime of the app so all
/// screens see the same `CurrentSubscription` without an extra round-trip
/// per navigation.
///
/// **Active rule:** any caller that needs to gate behaviour should check
/// `state.subscription.isCurrentlyActive` (`expiresAt > now`). The
/// server's `isActive` flag is informational only.
///
/// **Caching:** in-memory only — never persisted to disk. A "soft" call
/// to [refresh] within the 60 s TTL no-ops; `force: true` bypasses the
/// TTL and is used for cold-start, pull-to-refresh, gated-action
/// success, and the `/subscribe` aftermath (though the latter prefers
/// [onSubscribed] which avoids an extra round-trip entirely).
class CurrentSubscriptionCubit extends Cubit<CurrentSubscriptionState> {
  final GetCurrentSubscriptionUseCase _getCurrent;

  static const Duration _ttl = Duration(seconds: 60);

  CurrentSubscriptionCubit({
    required GetCurrentSubscriptionUseCase getCurrent,
  })  : _getCurrent = getCurrent,
        super(const CurrentSubscriptionInitial());

  DateTime? _lastSyncAt;

  /// Coalesces concurrent `refresh()` calls. Without this, two screens
  /// opening in the same frame fire two HTTP requests.
  Future<void>? _inflight;

  /// Synchronous accessor for `state.subscription` (null when the user
  /// isn't subscribed or hasn't hydrated yet).
  CurrentSubscription? get subscription {
    final s = state;
    return s is CurrentSubscriptionLoaded ? s.subscription : null;
  }

  /// True when the cached subscription exists AND `expiresAt > now`.
  bool get hasActiveSubscription =>
      subscription?.isCurrentlyActive ?? false;

  /// Cold-start entry. Always fetches, ignoring the TTL.
  Future<void> hydrate() => refresh(force: true);

  /// Refreshes the subscription from the server.
  ///
  /// * [force] `false` (default) — short-circuits when we have a fresh
  ///   value (within [_ttl]). Concurrent callers coalesce into the same
  ///   in-flight future.
  /// * [force] `true` — bypasses the TTL. Used by pull-to-refresh, app
  ///   foreground after long background, and after gated-action calls
  ///   that consume counters (like / interest / photo exchange).
  Future<void> refresh({bool force = false}) async {
    if (!force && _isFresh) return;
    final existing = _inflight;
    if (existing != null) return existing;

    final task = _fetch();
    _inflight = task;
    try {
      await task;
    } finally {
      _inflight = null;
    }
  }

  Future<void> _fetch() async {
    // Preserve any previous payload so `Failure` can carry it as
    // `lastKnown` — UI can fall back rather than blanking out.
    final previous = state is CurrentSubscriptionLoaded
        ? (state as CurrentSubscriptionLoaded).subscription
        : null;

    if (state is! CurrentSubscriptionLoaded &&
        state is! CurrentSubscriptionNone) {
      emit(const CurrentSubscriptionLoading());
    }

    final result = await _getCurrent();
    if (isClosed) return;
    result.fold(
      (failure) => emit(CurrentSubscriptionFailure(
        message: failure.message,
        lastKnown: previous,
      )),
      (sub) {
        _lastSyncAt = DateTime.now();
        if (sub == null) {
          emit(const CurrentSubscriptionNone());
        } else {
          emit(CurrentSubscriptionLoaded(sub));
        }
      },
    );
  }

  /// Pushes the freshly-issued subscription returned by `/subscribe`
  /// directly into state — skips the extra `/current` round-trip and
  /// keeps the success animation instant.
  void onSubscribed(CurrentSubscription subscription) {
    _lastSyncAt = DateTime.now();
    emit(CurrentSubscriptionLoaded(subscription));
  }

  /// Called by gated-action flows after the server confirms an action
  /// that consumes a counter (like / serious interest / photo exchange).
  /// Forces a fresh `/current` fetch so the Profile screen's
  /// `Remaining` counts update.
  Future<void> onActionConsumedCounter() => refresh(force: true);

  /// Clears the cached state — call this from `signOut` so a future
  /// sign-in sees a fresh hydration cycle.
  void clear() {
    _lastSyncAt = null;
    _inflight = null;
    emit(const CurrentSubscriptionInitial());
  }

  bool get _isFresh {
    final last = _lastSyncAt;
    if (last == null) return false;
    return DateTime.now().difference(last) < _ttl;
  }
}
