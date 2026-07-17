import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';

import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/like_outcome.dart';
import '../../domain/usecases/fetch_discovery_page_usecase.dart';
import '../../domain/usecases/like_profile_usecase.dart';
import '../../domain/usecases/pass_profile_usecase.dart';
import 'discovery_state.dart';

/// Screen-scoped controller for the Discovery deck.
///
/// State machine (sealed):
///   Initial → Loading → Loaded ⇄ (prefetch failures stay inside Loaded)
///                      Loading → Failure (initial-load error only)
///
/// Pagination: prefetch fires when the user is within 3 cards of the end
/// of the loaded deck (per `DISCOVERY_PLAN.md` §10 R5).
class DiscoveryCubit extends Cubit<DiscoveryState> with SafeEmit<DiscoveryState> {
  /// Server default. Tunable; lifted into a constant so tests can
  /// reference it without magic numbers.
  static const int pageSize = 10;

  /// How many cards before the end we trigger prefetch. Sized wider than
  /// the page can be swiped through in one network round-trip, so a fast
  /// swiper stays a page ahead instead of out-running the fetch and hitting
  /// the exhausted-deck loader.
  static const int prefetchThreshold = 6;

  final FetchDiscoveryPageUseCase _fetchPage;
  final LikeProfileUseCase _likeProfile;
  final PassProfileUseCase _passProfile;

  /// Fired exactly once per [LikeAccepted] outcome. DI wires this to
  /// `CurrentSubscriptionCubit.onActionConsumedCounter` so the Profile
  /// screen's remaining-likes counter refreshes after a successful
  /// like. Kept as an opaque callback so the cubit stays decoupled
  /// from the subscription feature (cross-feature coupling lives in DI
  /// only). Defaults to a no-op for test convenience.
  final VoidCallback _onLikeSuccess;

  /// Flat query map currently constraining the deck. Threaded into
  /// every page fetch — page 1 (loadInitial / refresh / applyFilters)
  /// AND every prefetch — so pagination stays consistent with the
  /// user's filter selection. `null` means unconstrained.
  Map<String, String>? _activeFilters;

  /// Blocks a second [like] from racing the first while the API call
  /// is in flight. Released in `like`'s `finally` block. `pass` does
  /// NOT take this guard — it has its own [_passCooldown] throttle and
  /// fires the network call in the background. The two guards are
  /// independent: a like never blocks a pass and vice versa.
  bool _mutationInFlight = false;

  /// Minimum spacing between two ACCEPTED passes. Taps arriving inside
  /// this window are dropped (no-op), throttling the burst of parallel
  /// `POST /skip/{id}` calls — and the queue advances — that rapid
  /// like/skip tapping (~100 taps/s) otherwise produces.
  static const Duration _passCooldown = Duration(milliseconds: 250);

  /// Timestamp of the last ACCEPTED pass; `null` until the first one.
  /// Compared against `DateTime.now()` at the top of [pass] to enforce
  /// [_passCooldown] without a [Timer] (nothing to dispose).
  DateTime? _lastPassAcceptedAt;

  /// Target ids with a skip request currently in flight. Dedups the
  /// fire-and-forget `_passProfile` calls so a single profile can never
  /// have two concurrent `POST /skip/{id}` requests. Ids are added
  /// before the call and removed in its `finally`.
  final Set<String> _skipInFlight = {};

  DiscoveryCubit({
    required FetchDiscoveryPageUseCase fetchPage,
    required LikeProfileUseCase likeProfile,
    required PassProfileUseCase passProfile,
    VoidCallback? onLikeSuccess,
  })  : _fetchPage = fetchPage,
        _likeProfile = likeProfile,
        _passProfile = passProfile,
        _onLikeSuccess = (onLikeSuccess ?? _noOp),
        super(const DiscoveryInitial());

  static void _noOp() {}

  Future<void> loadInitial() => _loadFirstPage();

  /// Pull-to-refresh entry. Same as initial load; discards the
  /// existing deck. Stale in-flight prefetches drop their results via
  /// the page-mismatch guard inside `_prefetch`. Active filters are
  /// preserved.
  Future<void> refresh() => _loadFirstPage();

  /// Replaces the active filter set and reloads from page 1.
  ///
  /// * Pass a non-empty map (produced by `DiscoveryFilterCubit.buildPayload`)
  ///   to constrain the deck.
  /// * Pass `null` or an empty map to clear all filters and reload
  ///   unconstrained.
  ///
  /// The reload uses the same path as `_loadFirstPage`, so any in-flight
  /// prefetch from the previous filter state is discarded by the
  /// page-mismatch guard in `_prefetch`.
  Future<void> applyFilters(Map<String, String>? filters) {
    final hasFilters = filters != null && filters.isNotEmpty;
    _activeFilters = hasFilters ? Map.unmodifiable(filters) : null;
    return _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    emit(const DiscoveryLoading());
    final result = await _fetchPage(
      page: 1,
      pageSize: pageSize,
      filterParams: _activeFilters,
    );
    // The screen can dispose (e.g. rapid back-navigation, app teardown)
    // while the page fetch is in flight. Without this guard, the fold
    // below would call `emit` on a closed cubit and throw StateError.
    if (isClosed) return;
    result.fold(
      (failure) => emit(failure is DailyViewsExceededFailure
          ? DiscoveryDailyLimit(failure.resetAt)
          : DiscoveryFailure(failure.message)),
      (page) => emit(DiscoveryLoaded(
        profiles: page.profiles,
        currentIndex: 0,
        currentPage: page.pageNumber,
        totalPages: page.totalPages,
      )),
    );
  }

  /// Sends a like for the current profile and branches on the server's
  /// typed [LikeOutcome]. On [LikeAccepted] the deck advances and
  /// [_onLikeSuccess] fires. [LikePaywall] keeps the card in place and
  /// emits a paywall-kinded failure for the UI listener to surface as
  /// a paywall sheet. The three "stale" outcomes (already pending,
  /// gender mismatch, user unavailable) advance the card AND emit a
  /// kinded failure so the listener can show a clear toast — there's
  /// no reason to keep a card the server has just declined permanently.
  /// Transport / unknown failures (`Left(Failure)`) emit a `network`
  /// failure without advancing.
  ///
  /// [advanceGate], when provided, defers the visible emit until the
  /// future completes. Phase 5 uses this from the Like button so the
  /// API can start at tap time (in parallel with the 1050 ms heart
  /// burst) while the deck transition still waits for the heart to
  /// finish. Swipe-like calls without a gate — immediate emit.
  ///
  /// [outcomeNotifier], when provided, fires with the resolved server
  /// result as soon as the API responds — **before** the gate is
  /// awaited and **before** any state is emitted. Lets the caller
  /// branch (run an eject animation vs surface a paywall) while the
  /// cubit's commit is still pending. Phase 5 uses this from the Like
  /// button so the eject only runs when the outcome warrants it.
  ///
  /// Re-entrant calls while a like is in flight are ignored via
  /// [_mutationInFlight]. The deck animator's `_runLikeSequence` also
  /// calls `like()` after the eject — that call no-ops naturally for
  /// button-driven likes (the API is already in flight) and runs
  /// normally for swipes (no prior call exists).
  Future<void> like({
    Future<void>? advanceGate,
    Completer<Either<Failure, LikeOutcome>>? outcomeNotifier,
  }) async {
    if (_mutationInFlight) return;
    final current = state;
    if (current is! DiscoveryLoaded) return;
    final profile = current.current;
    if (profile == null) return;
    _mutationInFlight = true;
    try {
      final result = await _likeProfile(profile.id);
      if (isClosed) return;
      if (outcomeNotifier != null && !outcomeNotifier.isCompleted) {
        outcomeNotifier.complete(result);
      }
      if (advanceGate != null) {
        await advanceGate;
        if (isClosed) return;
      }
      result.fold(
        (failure) => _emitLikeFailure(
          kind: LikeFailureKind.network,
          message: failure.message,
        ),
        (outcome) => _handleLikeOutcome(outcome),
      );
    } finally {
      _mutationInFlight = false;
    }
  }

  void _handleLikeOutcome(LikeOutcome outcome) {
    switch (outcome) {
      case LikeAccepted():
        _advance();
        _onLikeSuccess();
      case LikePaywall(:final serverMessage):
        _emitLikeFailure(
          kind: LikeFailureKind.paywall,
          message: serverMessage,
        );
      case LikeAlreadyPending(:final serverMessage):
        _advanceWithFailure(
          kind: LikeFailureKind.alreadyPending,
          message: serverMessage,
        );
      case LikeGenderMismatch(:final serverMessage):
        _advanceWithFailure(
          kind: LikeFailureKind.genderMismatch,
          message: serverMessage,
        );
      case LikeUserUnavailable(:final serverMessage):
        _advanceWithFailure(
          kind: LikeFailureKind.userUnavailable,
          message: serverMessage,
        );
    }
  }

  /// Emits a failure state without advancing the deck — paywall, network,
  /// and unknown-server failures keep the card in place so the user can
  /// retry / upgrade.
  void _emitLikeFailure({
    required LikeFailureKind kind,
    required String message,
  }) {
    // Build off the LIVE state, never a pre-await snapshot: a prefetch may have
    // appended pages while `like()` awaited the server/gate, and emitting off a
    // captured copy would revert both `profiles` and `isPrefetching`.
    final live = state;
    if (live is! DiscoveryLoaded) return;
    emit(live.copyWith(
      actionError: message,
      actionFailureKind: kind,
      actionErrorVersion: live.actionErrorVersion + 1,
    ));
  }

  /// Advances the deck AND attaches a kinded failure message in a
  /// single emit. Used for "stale" outcomes where the server tells us
  /// the card is no longer actionable (already pending / wrong gender /
  /// hidden user) — there's no value in leaving it on screen, so we
  /// move on while still surfacing the explanation.
  void _advanceWithFailure({
    required LikeFailureKind kind,
    required String message,
  }) {
    // Live state only (see `_advance`): preserve any concurrently-appended
    // pages, mutate just the index + error fields.
    final live = state;
    if (live is! DiscoveryLoaded) return;
    emit(live.copyWith(
      currentIndex: live.currentIndex + 1,
      actionError: message,
      actionFailureKind: kind,
      actionErrorVersion: live.actionErrorVersion + 1,
    ));
    _maybePrefetch();
  }

  /// Optimistic skip. Advances the deck immediately, then fires the
  /// server's skip endpoint in the background. Transport-level
  /// failures are logged but never surfaced — skip is invisible by
  /// design (no counter, no notification), so a toast on network
  /// failure would only confuse the user. The advance is committed
  /// even if the network call later fails; on the next Discovery
  /// fetch the server's persisted skip list takes over.
  ///
  /// Two throttles keep a tap burst (~100 taps/s) from racing ahead of
  /// the deck animation and flooding the backend:
  ///   * a [_passCooldown] re-entry guard at the top — taps arriving
  ///     within the window are dropped (pure no-op, current card
  ///     stays); only accepted passes advance and fire a skip;
  ///   * [_skipInFlight] dedup around the network call — a profile can
  ///     never have two concurrent `POST /skip/{id}` requests.
  ///
  /// **Known backend issue**: `POST /api/discovery/skip/{id}` has been
  /// observed returning HTTP 500 with an empty body. The log line
  /// below is the single place a backend report can be lifted from —
  /// the HTTP layer separately logs the status code and the raw
  /// response body via `_handleRawResponse`, so the two together give
  /// enough context (endpoint, target id, status, body) for a ticket.
  Future<void> pass() async {
    final now = DateTime.now();
    if (_lastPassAcceptedAt != null &&
        now.difference(_lastPassAcceptedAt!) < _passCooldown) {
      return;
    }
    _lastPassAcceptedAt = now;
    final current = state;
    if (current is! DiscoveryLoaded) return;
    final profile = current.current;
    if (profile == null) return;
    _advance();
    if (_skipInFlight.contains(profile.id)) return;
    _skipInFlight.add(profile.id);
    unawaited(_passProfile(profile.id).then((result) {
      result.fold(
        (failure) => AppLogger.warning(
          'skip endpoint failed silently for targetUserId=${profile.id} '
          '(UX optimistic — card already advanced). '
          'Server message: "${failure.message}". '
          'Endpoint: POST /api/discovery/skip/${profile.id}. '
          'Check HTTP layer log for status code and raw body.',
          tag: 'DISCOVERY',
        ),
        (_) => null,
      );
    }).whenComplete(() => _skipInFlight.remove(profile.id)));
  }

  /// Pure visual rewind (per `DISCOVERY_PLAN.md` Q1 answer): decrements
  /// `currentIndex`, clamped at 0. Does NOT call any server endpoint —
  /// the like/pass that produced the previous card stays recorded on
  /// the backend until a future "undo" endpoint lands.
  void undo() {
    final current = state;
    if (current is! DiscoveryLoaded) return;
    final newIndex =
        (current.currentIndex - 1).clamp(0, current.profiles.length);
    if (newIndex == current.currentIndex) return;
    emit(current.copyWith(
      currentIndex: newIndex,
      resetActionError: true,
    ));
  }

  /// Public hook for the UI's "retry" affordance on a failed prefetch.
  Future<void> retryPrefetch() async {
    final current = state;
    if (current is! DiscoveryLoaded) return;
    if (!current.hasMore || current.isPrefetching) return;
    await _prefetch(current);
  }

  /// Safety-net prefetch trigger for the exhausted-deck case. Once the deck
  /// is exhausted `current` is null, so `like()`/`pass()` no-op and
  /// [_maybePrefetch] can never fire again on its own — without this the deck
  /// would dead-end permanently even though more pages exist. The view calls
  /// this when it renders the "catching up" loader (exhausted but
  /// [DiscoveryLoaded.hasMore]). Idempotent: no-ops when there's nothing more
  /// to load or a prefetch is already in flight.
  void ensurePrefetch() {
    final current = state;
    if (current is! DiscoveryLoaded) return;
    if (!current.hasMore || current.isPrefetching) return;
    unawaited(_prefetch(current));
  }

  void _advance() {
    // Re-read the live state at emit time. A prefetch running concurrently with
    // a `like()` (which captures a pre-await snapshot to read `profile.id`) may
    // have appended pages and reset `isPrefetching`; emitting off that snapshot
    // would revert both. The prefetch never moves `currentIndex`, so advancing
    // off the live index is the same card progression, minus the clobber.
    final live = state;
    if (live is! DiscoveryLoaded) return;
    emit(live.copyWith(
      currentIndex: live.currentIndex + 1,
      resetActionError: true,
    ));
    _maybePrefetch();
  }

  void _maybePrefetch() {
    final updated = state;
    if (updated is! DiscoveryLoaded) return;
    final atThreshold =
        updated.currentIndex >= updated.profiles.length - prefetchThreshold;
    if (atThreshold && updated.hasMore && !updated.isPrefetching) {
      unawaited(_prefetch(updated));
    }
  }

  Future<void> _prefetch(DiscoveryLoaded base) async {
    if (base.isPrefetching || !base.hasMore) return;
    emit(base.copyWith(
      isPrefetching: true,
      resetPrefetchError: true,
    ));
    final nextPage = base.currentPage + 1;
    final result = await _fetchPage(
      page: nextPage,
      pageSize: pageSize,
      filterParams: _activeFilters,
    );
    if (isClosed) return;
    final post = state;
    if (post is! DiscoveryLoaded) return; // refresh / shutdown happened
    result.fold(
      (failure) {
        // Follow-up: mid-deck daily-limit coverage. If a no-sub user
        // prefetched a page then hits DAILY_VIEWS_EXCEEDED here, we keep it
        // as a non-fatal prefetchError — the limit screen only appears once
        // the loaded cards run out (the page-1 load is the primary trigger).
        emit(post.copyWith(
          isPrefetching: false,
          prefetchError: failure.message,
        ));
      },
      (page) {
        // Guard: drop stale results when a refresh reset currentPage back to 1
        // while this prefetch was in flight. Reset `isPrefetching` on the
        // dropped path too — otherwise a dropped result would strand the flag
        // `true` forever and block every future page.
        final dropped = post.currentPage != base.currentPage;
        if (dropped) {
          emit(post.copyWith(isPrefetching: false));
          return;
        }
        emit(post.copyWith(
          profiles: [...post.profiles, ...page.profiles],
          currentPage: page.pageNumber,
          totalPages: page.totalPages,
          isPrefetching: false,
          resetPrefetchError: true,
        ));
        // Eager chain: a fast swiper may already sit within the threshold of
        // this freshly appended page's tail. Re-check now so the next page
        // starts loading immediately instead of waiting for the next swipe.
        _maybePrefetch();
      },
    );
  }
}




