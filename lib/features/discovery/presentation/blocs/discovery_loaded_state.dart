part of 'discovery_state.dart';

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

  /// A skip-reset is in flight. Drives the "start over" button's own disable +
  /// spinner treatment so the request cannot be fired twice.
  final bool isResettingSeen;

  /// One-shot outcome of a "start over" that left the screen looking
  /// unchanged — the reset restored nobody, or it failed.
  ///
  /// A reset that DID restore someone never lands here: it reloads the deck,
  /// and the returning cards are its own feedback. Everything else needs
  /// saying, or the button reads as broken.
  ///
  /// Reset owns this channel outright rather than sharing [actionError], whose
  /// listener renders a generic message by design.
  final DiscoveryResetNotice? resetNotice;

  /// Bumped whenever [resetNotice] is set, for the same reason as
  /// [actionErrorVersion]: two identical notices in a row are equal under
  /// Equatable, and the listener would swallow the second.
  final int resetNoticeVersion;

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
    this.isResettingSeen = false,
    this.resetNotice,
    this.resetNoticeVersion = 0,
  });

  bool get isEmpty => profiles.isEmpty;
  bool get isExhausted => currentIndex >= profiles.length;
  bool get hasMore => currentPage < totalPages;

  /// Why the deck is showing nothing — see `discovery_terminal_signals.dart`.
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
  /// `clearResetNotice` forces [resetNotice] to `null` so a spent one-shot
  /// notice cannot ride along on later copies.
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
    bool? isResettingSeen,
    DiscoveryResetNotice? resetNotice,
    int? resetNoticeVersion,
    bool resetActionError = false,
    bool resetPrefetchError = false,
    bool resetReason = false,
    bool clearResetNotice = false,
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
      isResettingSeen: isResettingSeen ?? this.isResettingSeen,
      resetNotice:
          clearResetNotice ? null : (resetNotice ?? this.resetNotice),
      resetNoticeVersion: resetNoticeVersion ?? this.resetNoticeVersion,
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
        isResettingSeen,
        resetNotice,
        resetNoticeVersion,
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
      '${currentReason != null ? ', reason: ${currentReason!.name}' : ''}'
      '${isResettingSeen ? ', resetting' : ''}'
      '${resetNotice != null ? ', reset: ${resetNotice!.name}#$resetNoticeVersion' : ''})';
}
