import 'package:equatable/equatable.dart';

import '../../domain/entities/discovery_empty_reason.dart';
import '../../domain/entities/discovery_profile.dart';
import 'like_failure_kind.dart';

export 'like_failure_kind.dart';

sealed class DiscoveryState extends Equatable {
  const DiscoveryState();

  @override
  List<Object?> get props => const [];
}

final class DiscoveryInitial extends DiscoveryState {
  const DiscoveryInitial();
}

final class DiscoveryLoading extends DiscoveryState {
  const DiscoveryLoading();
}

/// Initial-page fetch failed. The UI should surface a retry button.
/// Prefetch failures are NOT modeled here — see [DiscoveryLoaded.prefetchError].
final class DiscoveryFailure extends DiscoveryState {
  final String message;
  const DiscoveryFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Active deck state. Stays here for the entire session once page 1
/// resolves, even when the deck is empty or exhausted (the UI branches
/// on `isEmpty` / `isExhausted`).
final class DiscoveryLoaded extends DiscoveryState {
  final List<DiscoveryProfile> profiles;
  final int currentIndex;
  final int currentPage;
  final int totalPages;
  final bool isPrefetching;

  /// Profiles matching the active query server-side, as the backend reported
  /// it. Null when the backend sent no total.
  ///
  /// Threaded for parity with the matchmaker's explore list, but the deck
  /// renders no count header — a full-bleed one-card-at-a-time surface has no
  /// header region, and the count is only meaningful here to tell "the filter
  /// matched nothing" apart from "you have swiped through all the matches".
  final int? totalCount;

  /// Raw server / localized message for the most recent like/pass
  /// failure. UI consumes it as a one-shot snackbar via `BlocListener`.
  /// Cleared when the next action succeeds or `undo` rewinds.
  ///
  /// Kept around alongside [actionFailureKind] for two reasons:
  /// (1) backwards-compat with existing tests, and (2) the raw server
  /// message is useful in logs even when the kind already drives the UI.
  final String? actionError;

  /// Typed projection of [actionError] — drives which UI surface fires
  /// (paywall vs toast vs generic error). `null` when no failure is
  /// active. Set/cleared in lockstep with [actionError].
  final LikeFailureKind? actionFailureKind;

  /// Bumped every time the failure transitions from null to a value.
  /// Lets the listener detect consecutive failures with the same kind
  /// (Equatable would otherwise dedupe them).
  final int actionErrorVersion;

  /// Last prefetch's failure message (if any). Non-fatal — the deck
  /// keeps working with the cards already loaded. UI may show a small
  /// banner with a retry button.
  final String? prefetchError;

  /// Reason reported by the MOST RECENT page fetch. Null whenever the backend
  /// gave none — which is every page that carried profiles, and every response
  /// from a backend predating the field. A hint, never a requirement.
  ///
  /// Only describes what the SERVER can know: it never learns that the user
  /// swiped through profiles it did hand over. [sawEveryLoadedProfile] covers
  /// that half.
  final DiscoveryEmptyReason? currentReason;

  const DiscoveryLoaded({
    required this.profiles,
    required this.currentIndex,
    required this.currentPage,
    required this.totalPages,
    this.totalCount,
    this.isPrefetching = false,
    this.actionError,
    this.actionFailureKind,
    this.actionErrorVersion = 0,
    this.prefetchError,
    this.currentReason,
  });

  bool get isEmpty => profiles.isEmpty;
  bool get isExhausted => currentIndex >= profiles.length;
  bool get hasMore => currentPage < totalPages;

  /// The user was handed profiles and swiped past the last one, with no page
  /// left to fetch. The server cannot report this — it never hears about the
  /// swipes — so the client watches for it instead.
  ///
  /// `profiles.isNotEmpty` is LOAD-BEARING, not a tidiness check: [isExhausted]
  /// is `currentIndex >= profiles.length`, which is also true of a deck that
  /// never had anything (`0 >= 0`). Drop the guard and "you have seen everyone"
  /// fires at a user who was shown nobody.
  bool get sawEveryLoadedProfile =>
      profiles.isNotEmpty && isExhausted && !hasMore;

  /// Union of the two independent signals, per the agreed CTA rule: the server
  /// saying so, OR the client having watched it happen. Either one alone is
  /// enough to offer "start over".
  bool get hasSeenEveryone =>
      currentReason == DiscoveryEmptyReason.seenAll || sawEveryLoadedProfile;

  /// Server-only signal: the query matched nobody, so the seen ledger is
  /// irrelevant and the filters are the remedy. Deliberately NOT unioned with
  /// [hasSeenEveryone] — both can be true at once, and each drives its own CTA.
  bool get filtersMatchedNobody =>
      currentReason == DiscoveryEmptyReason.noMatchesForFilters;
  DiscoveryProfile? get current =>
      isExhausted ? null : profiles[currentIndex];

  DiscoveryProfile? get next =>
      currentIndex + 1 < profiles.length ? profiles[currentIndex + 1] : null;

  /// Copies the loaded state with selective overrides.
  ///
  /// `resetActionError` clears BOTH [actionError] and [actionFailureKind]
  /// — they're always set and cleared together.
  /// `resetPrefetchError` forces [prefetchError] to `null`.
  /// `resetReason` forces [currentReason] to `null` — needed because a page
  /// that reports NO reason must clear whatever the previous page reported,
  /// and `??` alone can only ever set it.
  DiscoveryLoaded copyWith({
    List<DiscoveryProfile>? profiles,
    int? currentIndex,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    bool? isPrefetching,
    String? actionError,
    LikeFailureKind? actionFailureKind,
    int? actionErrorVersion,
    String? prefetchError,
    DiscoveryEmptyReason? currentReason,
    bool resetActionError = false,
    bool resetPrefetchError = false,
    bool resetReason = false,
  }) {
    return DiscoveryLoaded(
      profiles: profiles ?? this.profiles,
      currentIndex: currentIndex ?? this.currentIndex,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      isPrefetching: isPrefetching ?? this.isPrefetching,
      actionError:
          resetActionError ? null : (actionError ?? this.actionError),
      actionFailureKind: resetActionError
          ? null
          : (actionFailureKind ?? this.actionFailureKind),
      actionErrorVersion: actionErrorVersion ?? this.actionErrorVersion,
      prefetchError:
          resetPrefetchError ? null : (prefetchError ?? this.prefetchError),
      currentReason:
          resetReason ? null : (currentReason ?? this.currentReason),
    );
  }

  @override
  List<Object?> get props => [
        profiles,
        currentIndex,
        currentPage,
        totalPages,
        totalCount,
        isPrefetching,
        actionError,
        actionFailureKind,
        actionErrorVersion,
        prefetchError,
        currentReason,
      ];

  /// Concise one-line summary for logs (BlocObserver dumps `$change`).
  /// Deliberately omits the `profiles` payload — the default Equatable
  /// `toString` prints every prop, flooding the console with the full
  /// profile list on every state change. Only `toString` is overridden;
  /// `props` (equality/rebuild logic) is untouched.
  @override
  String toString() =>
      'DiscoveryLoaded(len: ${profiles.length}, idx: $currentIndex, '
      'page: $currentPage/$totalPages, prefetching: $isPrefetching'
      '${actionFailureKind != null ? ', fail: ${actionFailureKind!.name}#$actionErrorVersion' : ''}'
      '${prefetchError != null ? ', prefetchErr' : ''}'
      '${currentReason != null ? ', reason: ${currentReason!.name}' : ''})';
}

/// The no-subscription daily view cap was hit (`DAILY_VIEWS_EXCEEDED`). A
/// full-screen "come back tomorrow" state — NOT a paywall. [resetAt] drives the
/// reset countdown. Only ever emitted because the server returned the code
/// (no client-side cap counting).
final class DiscoveryDailyLimit extends DiscoveryState {
  final DateTime resetAt;
  const DiscoveryDailyLimit(this.resetAt);

  @override
  List<Object?> get props => [resetAt];
}
