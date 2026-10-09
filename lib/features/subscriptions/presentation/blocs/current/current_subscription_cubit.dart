import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';

import '../../../domain/entities/current_subscription.dart';
import '../../../domain/usecases/get_current_subscription_usecase.dart';
import 'activation_pending.dart';
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
///
/// **C5:** a store-confirmed purchase is [CurrentSubscriptionActivating],
/// never None, until `/current` shows it active — across restarts too.
class CurrentSubscriptionCubit extends Cubit<CurrentSubscriptionState> with SafeEmit<CurrentSubscriptionState> {
  final GetCurrentSubscriptionUseCase _getCurrent;
  final ActivationPending _activation;

  static const Duration _ttl = Duration(seconds: 60);

  CurrentSubscriptionCubit({
    required GetCurrentSubscriptionUseCase getCurrent,
    required ActivationPending activation,
  })  : _getCurrent = getCurrent,
        _activation = activation,
        super(const CurrentSubscriptionInitial());

  DateTime? _lastSyncAt;

  /// Coalesces concurrent `refresh()` calls. Without this, two screens
  /// opening in the same frame fire two HTTP requests.
  Future<void>? _inflight;

  /// Bumped by [clear]: a fetch begun before it belongs to the previous
  /// account, and its answer is dropped.
  int _generation = 0;

  /// Synchronous accessor for `state.subscription` (null when the user
  /// isn't subscribed or hasn't hydrated yet).
  CurrentSubscription? get subscription {
    final s = state;
    return s is CurrentSubscriptionLoaded ? s.subscription : null;
  }

  /// True when the cached subscription exists AND `expiresAt > now`.
  bool get hasActiveSubscription =>
      subscription?.isCurrentlyActive ?? false;

  /// Cold-start entry. Always fetches, ignoring the TTL; a purchase still
  /// activating from before the restart resumes its re-reads.
  Future<void> hydrate() async {
    await refresh(force: true);
    if (_activation.isPending) unawaited(_pollWhilePending());
  }

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
      if (identical(_inflight, task)) _inflight = null;
    }
  }

  Future<void> _fetch() async {
    final generation = _generation;
    // Preserve any previous payload so `Failure` can carry it as
    // `lastKnown` — UI can fall back rather than blanking out.
    final previous = state is CurrentSubscriptionLoaded
        ? (state as CurrentSubscriptionLoaded).subscription
        : null;

    if (state is! CurrentSubscriptionLoaded &&
        state is! CurrentSubscriptionNone &&
        state is! CurrentSubscriptionActivating) {
      emit(const CurrentSubscriptionLoading());
    }

    await _activation.load();
    final result = await _getCurrent();
    if (isClosed || generation != _generation) return;
    result.fold((f) => _onFailure(f.message, previous), _onCurrent);
  }

  void _onFailure(String message, CurrentSubscription? lastKnown) =>
      _activation.isPending
          ? _emitActivating()
          : emit(CurrentSubscriptionFailure(
              message: message,
              lastKnown: lastKnown,
            ));

  /// An active subscription settles a pending activation; anything else
  /// while one is pending stays "activating".
  void _onCurrent(CurrentSubscription? sub) {
    _lastSyncAt = DateTime.now();
    if (sub != null && sub.isCurrentlyActive) {
      if (_activation.isPending) unawaited(_activation.settle());
      return emit(CurrentSubscriptionLoaded(sub));
    }
    if (_activation.isPending) return _emitActivating();
    emit(sub == null
        ? const CurrentSubscriptionNone()
        : CurrentSubscriptionLoaded(sub));
  }

  /// The store confirmed a purchase or a restore (C5). "Activating" until
  /// `/current` shows it active — an active plan (an upgrade) keeps showing
  /// meanwhile — with [ActivationPending.watch]'s re-reads.
  Future<void> onStoreConfirmed() async {
    await _activation.start();
    if (isClosed) return;
    if (!hasActiveSubscription) _emitActivating();
    await _pollWhilePending();
  }

  /// Re-reads for this account only: a sign-out ends the loop.
  Future<void> _pollWhilePending() {
    final generation = _generation;
    return _activation.watch(
      () => refresh(force: true),
      alive: () => !isClosed && generation == _generation,
    );
  }

  void _emitActivating() {
    emit(CurrentSubscriptionActivating(
      since: _activation.since!,
      overdue: _activation.isOverdue,
    ));
    _activation.whenOverdue(() {
      if (state is CurrentSubscriptionActivating) _emitActivating();
    });
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

  /// Clears the cached state when the account changes (the session's
  /// AccountScope), so the next account sees a fresh hydration cycle.
  void clear() {
    _generation++;
    _lastSyncAt = null;
    _inflight = null;
    _activation.forgetAccount();
    emit(const CurrentSubscriptionInitial());
  }

  @override
  Future<void> close() {
    _activation.forgetAccount();
    return super.close();
  }

  bool get _isFresh {
    final last = _lastSyncAt;
    if (last == null) return false;
    return DateTime.now().difference(last) < _ttl;
  }
}
